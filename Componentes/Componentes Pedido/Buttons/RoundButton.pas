unit RoundButton;

{ Botão em pílula (ou círculo, quando só tem ícone) com estados de hover, pressionado e foco. }

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
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Grids,
  ComponentAccess,
  ComponentIcons,
  ComponentTheme,
  ComponentUtils;

type
  TEstiloBotao = (ebPrimario, ebSecundario, ebPerigo, ebFantasma);

  { TRoundButton }
  TRoundButton = class(TCustomControl)
  private
    FIcone: TIcone;
    FEstilo: TEstiloBotao;
    FSobre: Boolean;
    FPressionado: Boolean;
    FSomenteIcone: Boolean;
    procedure SetIcone(const AValue: TIcone);
    procedure SetSomenteIcone(const AValue: Boolean);
    function TextoVisivel: string;
    procedure SetEstilo(const AValue: TEstiloBotao);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFocusChanged(var Msg: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetObject(var Msg: TMessage); message WM_GETOBJECT;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption;
    // Botão só de ícone: o Caption não é desenhado, mas continua sendo o nome
    // lido por leitores de tela.
    property SomenteIcone: Boolean read FSomenteIcone write SetSomenteIcone;
    property OnClick;
    property Icone: TIcone read FIcone write SetIcone;
    property Estilo: TEstiloBotao read FEstilo write SetEstilo;
    property Align;
    property Anchors;
    property Enabled;
    property Hint;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property Cursor;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TRoundButton]);
end;

{ TRoundButton }

constructor TRoundButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque] + [csCaptureMouse];
  DoubleBuffered := True;
  TabStop := True;
  Width := 150;
  Height := 40;
  Cursor := crHandPoint;
  FEstilo := ebSecundario;
end;

procedure TRoundButton.WMGetObject(var Msg: TMessage);
begin
  // Para leitores de tela: botão de verdade, com nome, estado e ação.
  if not ResponderGetObject(Self, Msg,
    function: TDadosAcessiveis
    begin
      if Caption <> '' then
        Result := NovosDados(Caption, PAPEL_BOTAO)
      else
        Result := NovosDados(Hint, PAPEL_BOTAO);
      if (Hint <> '') and (Hint <> Result.Nome) then
        Result.Descricao := Hint;
    end,
    procedure
    begin
      if Enabled then
        Click;
    end) then
    inherited;
end;

procedure TRoundButton.SetIcone(const AValue: TIcone);
begin
  FIcone := AValue;
  Invalidate;
end;

procedure TRoundButton.SetEstilo(const AValue: TEstiloBotao);
begin
  FEstilo := AValue;
  Invalidate;
end;

procedure TRoundButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FSobre := True;
  Invalidate;
end;

procedure TRoundButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FSobre := False;
  FPressionado := False;
  Invalidate;
end;

procedure TRoundButton.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TRoundButton.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TRoundButton.CMFocusChanged(var Msg: TCMFocusChanged);
begin
  inherited;
  Invalidate;
end;

procedure TRoundButton.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TRoundButton.SetSomenteIcone(const AValue: Boolean);
begin
  FSomenteIcone := AValue;
  Invalidate;
end;

function TRoundButton.TextoVisivel: string;
begin
  if FSomenteIcone then
    Result := ''
  else
    Result := Caption;
end;

procedure TRoundButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TRoundButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TRoundButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    FPressionado := True;
    Invalidate;
  end;
end;

procedure TRoundButton.KeyUp(var Key: Word; Shift: TShiftState);
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

procedure TRoundButton.Paint;
var
  G: TGPGraphics;
  Caminho: TGPGraphicsPath;
  Fundo, Borda, Frente: TColor;
  TamIcone, Espaco, LarguraTexto, LarguraTotal, X: Integer;
begin
  PreencherFundo(Self, Canvas);

  // Cores conforme estilo e estado
  Borda := clNone;
  case FEstilo of
    ebPrimario:
      begin
        Frente := clWhite;
        if FPressionado then Fundo := CorPrimariaPress
        else if FSobre then Fundo := CorPrimariaHover
        else Fundo := CorPrimaria;
      end;
    ebPerigo:
      begin
        if FPressionado or FSobre then
        begin
          Fundo := CorPerigo;
          Frente := clWhite;
        end
        else
        begin
          Fundo := CorPerigoSuave;
          Frente := CorPerigo;
        end;
      end;
    ebFantasma:
      begin
        Frente := clWhite;
        if FPressionado or FSobre then Fundo := CorTopoTextoSuave
        else Fundo := TColor($003A2A20);
      end;
  else
    begin
      Frente := CorTexto;
      Borda := CorBordaForte;
      if FPressionado then Fundo := CorBorda
      else if FSobre then Fundo := CorHover
      else Fundo := CorCartao;
    end;
  end;
  if not Enabled then
  begin
    Fundo := CorBorda;
    Frente := CorBordaForte;
    Borda := clNone;
  end;

  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    Caminho := CaminhoArredondado(0.5, 0.5, Width - 1, Height - 1, (Height - 1) / 2);
    try
      PintarCaminho(G, Caminho, Fundo, Borda, 1);
    finally
      Caminho.Free;
    end;

    // Anel de foco (teclado)
    if Focused and Enabled then
    begin
      Caminho := CaminhoArredondado(2.5, 2.5, Width - 5, Height - 5, (Height - 5) / 2);
      try
        PintarCaminho(G, Caminho, clNone, CorPrimariaSuave, 2);
      finally
        Caminho.Free;
      end;
    end;

    Canvas.Font.Name := FonteNomeNegrito;
    Canvas.Font.Size := 10;
    Canvas.Font.Color := Frente;
    Canvas.Brush.Style := bsClear;

    TamIcone := IfThen(TextoVisivel = '', Min(Width, Height) div 2, 18);
    Espaco := IfThen((FIcone <> icNenhum) and (TextoVisivel <> ''), 8, 0);
    LarguraTexto := Canvas.TextWidth(TextoVisivel);
    LarguraTotal := LarguraTexto + Espaco;
    if FIcone <> icNenhum then
      Inc(LarguraTotal, TamIcone);
    X := (Width - LarguraTotal) div 2;

    if FIcone <> icNenhum then
    begin
      DesenharIcone(G, FIcone, X, (Height - TamIcone) / 2, TamIcone, Frente);
      Inc(X, TamIcone + Espaco);
    end;
  finally
    G.Free;
  end;

  if TextoVisivel <> '' then
    Canvas.TextOut(X, (Height - Canvas.TextHeight(TextoVisivel)) div 2, TextoVisivel);
end;


end.
