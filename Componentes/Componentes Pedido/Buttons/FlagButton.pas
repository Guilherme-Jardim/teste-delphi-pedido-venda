unit FlagButton;

{ Botão redondo com a bandeira de um país (troca de idioma). As bandeiras são
  desenhadas em GDI+ com as mesmas formas do conjunto flag-icons (licença MIT),
  o mesmo usado no site do Shadows Pokémon. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  System.Classes,
  System.SysUtils,
  System.Math,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  ComponentAccess,
  ComponentTheme,
  ComponentUtils,
  ComponentIcons;

type
  TBandeira = (bdEspanha, bdBrasil);

  { TFlagButton }
  TFlagButton = class(TCustomControl)
  private
    FBandeira: TBandeira;
    FAtivo: Boolean;
    FSobre: Boolean;
    FPressionado: Boolean;
    procedure SetBandeira(const AValue: TBandeira);
    procedure SetAtivo(const AValue: Boolean);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMFocusChanged(var Msg: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetObject(var Msg: TMessage); message WM_GETOBJECT;
    procedure DesenharBandeira(G: TGPGraphics; X, Y, D: Single);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Bandeira: TBandeira read FBandeira write SetBandeira;
    // Bandeira do idioma em uso: fica com anel de destaque; as outras esmaecem.
    property Ativo: Boolean read FAtivo write SetAtivo;
    // O Caption não é desenhado; serve de nome para leitores de tela.
    property Caption;
    property OnClick;
    property Align;
    property Anchors;
    property Enabled;
    property Hint;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TFlagButton]);
end;

constructor TFlagButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque] + [csCaptureMouse];
  DoubleBuffered := True;
  TabStop := True;
  Width := 44;
  Height := 44;
  Cursor := crHandPoint;
end;

procedure TFlagButton.WMGetObject(var Msg: TMessage);
begin
  // A bandeira do idioma em uso aparece como "marcada" (botão de opção).
  if not ResponderGetObject(Self, Msg,
    function: TDadosAcessiveis
    begin
      if Caption <> '' then
        Result := NovosDados(Caption, PAPEL_RADIO)
      else
        Result := NovosDados(Hint, PAPEL_RADIO);
      if FAtivo then
        Result.Estado := ESTADO_MARCADO;
    end,
    procedure
    begin
      if Enabled then
        Click;
    end) then
    inherited;
end;

procedure TFlagButton.SetBandeira(const AValue: TBandeira);
begin
  FBandeira := AValue;
  Invalidate;
end;

procedure TFlagButton.SetAtivo(const AValue: Boolean);
begin
  FAtivo := AValue;
  Invalidate;
  AvisarMudanca(Self, EVENTO_VALOR_MUDOU);
end;

procedure TFlagButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FSobre := True;
  Invalidate;
end;

procedure TFlagButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FSobre := False;
  FPressionado := False;
  Invalidate;
end;

procedure TFlagButton.CMFocusChanged(var Msg: TCMFocusChanged);
begin
  inherited;
  Invalidate;
end;

procedure TFlagButton.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TFlagButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and Enabled then
  begin
    if CanFocus then
      SetFocus;
    FPressionado := True;
    Invalidate;
  end;
end;

procedure TFlagButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Clicou: Boolean;
begin
  inherited;
  Clicou := FPressionado and (Button = mbLeft) and PtInRect(ClientRect, Point(X, Y));
  FPressionado := False;
  Invalidate;
  if Clicou and Enabled then
    Click;
end;

procedure TFlagButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    FPressionado := True;
    Invalidate;
  end;
end;

procedure TFlagButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if FPressionado and ((Key = VK_SPACE) or (Key = VK_RETURN)) then
  begin
    FPressionado := False;
    Invalidate;
    if Enabled then
      Click;
  end;
end;

procedure TFlagButton.DesenharBandeira(G: TGPGraphics; X, Y, D: Single);
var
  Pincel: TGPSolidBrush;
  Caminho: TGPGraphicsPath;
  Esc, Larg, Alt, Ox, Oy: Single;

  function PX(V: Single): Single;
  begin
    Result := Ox + V * Esc;
  end;

  function PY(V: Single): Single;
  begin
    Result := Oy + V * Esc;
  end;

  procedure Cor(const C: TColor);
  begin
    Pincel.Free;
    Pincel := TGPSolidBrush.Create(CorParaARGB(C));
  end;

begin
  // Bandeira 640 x 480 (4:3) centrada e cobrindo o círculo de diâmetro D.
  Esc := D / 480;
  Larg := 640 * Esc;
  Alt := 480 * Esc;
  Ox := X + (D - Larg) / 2;
  Oy := Y + (D - Alt) / 2;
  Pincel := TGPSolidBrush.Create(0);
  try
    if FBandeira = bdEspanha then
    begin
      Cor(TColor($001E0BC6));   // vermelho #c60b1e
      G.FillRectangle(Pincel, Ox, Oy, Larg, Alt);
      Cor(TColor($0000C4FF));   // amarelo #ffc400
      G.FillRectangle(Pincel, Ox, PY(120), Larg, 240 * Esc);
    end
    else
    begin
      Cor(TColor($00459E22));   // verde #229e45
      G.FillRectangle(Pincel, Ox, Oy, Larg, Alt);
      Caminho := TGPGraphicsPath.Create;
      try
        Caminho.AddLine(PX(320), PY(75), PX(590), PY(240));
        Caminho.AddLine(PX(590), PY(240), PX(320), PY(405));
        Caminho.AddLine(PX(320), PY(405), PX(50), PY(240));
        Caminho.CloseFigure;
        Cor(TColor($0009E5F8)); // amarelo #f8e509
        G.FillPath(Pincel, Caminho);
      finally
        Caminho.Free;
      end;
      Cor(TColor($00A3492B));   // azul #2b49a3
      G.FillEllipse(Pincel, PX(240), PY(160), 160 * Esc, 160 * Esc);
      Caminho := TGPGraphicsPath.Create;
      try
        Caminho.AddBezier(PX(246), PY(206), PX(292), PY(210), PX(340), PY(234), PX(371), PY(272));
        Caminho.AddBezier(PX(371), PY(272), PX(328), PY(253), PX(281), PY(244), PX(246), PY(256));
        Caminho.CloseFigure;
        Cor(clWhite);
        G.FillPath(Pincel, Caminho);
      finally
        Caminho.Free;
      end;
    end;
  finally
    Pincel.Free;
  end;
end;

procedure TFlagButton.Paint;
var
  G: TGPGraphics;
  Clip: TGPGraphicsPath;
  Caneta: TGPPen;
  Esmaecer: TGPSolidBrush;
  D: Single;
begin
  PreencherFundo(Self, Canvas);
  D := Min(Width, Height) - 8;
  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    // Bandeira recortada em círculo
    Clip := TGPGraphicsPath.Create;
    try
      Clip.AddEllipse((Width - D) / 2, (Height - D) / 2, D, D);
      G.SetClip(Clip);
      DesenharBandeira(G, (Width - D) / 2, (Height - D) / 2, D);
      // Esmaece as bandeiras que não estão ativas (o mouse realça)
      if (not FAtivo) and (not FSobre) then
      begin
        Esmaecer := TGPSolidBrush.Create(CorParaARGB(CorTopo, 150));
        try
          G.FillEllipse(Esmaecer, (Width - D) / 2, (Height - D) / 2, D, D);
        finally
          Esmaecer.Free;
        end;
      end;
      G.ResetClip;
    finally
      Clip.Free;
    end;

    // Anel: destaque (ativa) ou borda suave
    if FAtivo then
      Caneta := TGPPen.Create(CorParaARGB(clWhite), 2.5)
    else
      Caneta := TGPPen.Create(CorParaARGB(CorTopoTextoSuave, 140), 1);
    try
      G.DrawEllipse(Caneta, (Width - D) / 2, (Height - D) / 2, D, D);
    finally
      Caneta.Free;
    end;

    // Anel de foco do teclado
    if Focused and Enabled then
    begin
      Caneta := TGPPen.Create(CorParaARGB(CorPrimariaSuave), 2);
      try
        G.DrawEllipse(Caneta, 1, 1, Width - 2, Height - 2);
      finally
        Caneta.Free;
      end;
    end;
  finally
    G.Free;
  end;
end;

end.
