unit ModernEdit;

{ Campo de texto com rótulo, ícone, foco destacado e ENTER que avança. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  System.Classes,
  System.SysUtils,
  System.Math,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Grids,
  ComponentIcons,
  ComponentTheme,
  ComponentUtils;

type
  { TModernEdit }
  TModernEdit = class(TCustomControl)
  private
    FEdit: TEdit;
    FRotulo: string;
    FIcone: TIcone;
    FFocado: Boolean;
    FDica: string;
    FOnSaida: TNotifyEvent;
    FOnConfirmar: TNotifyEvent;
    function GetTexto: string;
    procedure SetTexto(const AValue: string);
    function GetSomenteLeitura: Boolean;
    procedure SetSomenteLeitura(AValue: Boolean);
    procedure SetRotulo(const AValue: string);
    procedure SetDica(const AValue: string);
    procedure SetIcone(const AValue: TIcone);
    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure PosicionarEdit;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetFocus; override;
    procedure Limpar;
    // Disparado ao sair do campo.
  published
    // Campo de texto interno: permite ajustar MaxLength, NumbersOnly etc. no dfm.
    property Edit: TEdit read FEdit;
    property Rotulo: string read FRotulo write SetRotulo;
    // Texto de ajuda mostrado como dica (hint) ao parar o mouse sobre o campo.
    property Dica: string read FDica write SetDica;
    property Icone: TIcone read FIcone write SetIcone;
    property Texto: string read GetTexto write SetTexto;
    property SomenteLeitura: Boolean read GetSomenteLeitura write SetSomenteLeitura;
    property OnSaida: TNotifyEvent read FOnSaida write FOnSaida;
    property OnConfirmar: TNotifyEvent read FOnConfirmar write FOnConfirmar;
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property Visible;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TModernEdit]);
end;

const
  ALTURA_ROTULO = 22;
  ALTURA_CAIXA = 38;

constructor TModernEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque] + [csAcceptsControls];
  DoubleBuffered := True;
  Width := 200;
  Height := ALTURA_ROTULO + ALTURA_CAIXA;

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.SetSubComponent(True);
  FEdit.BorderStyle := bsNone;
  FEdit.Font.Name := FonteNome;
  FEdit.Font.Size := 11;
  FEdit.Font.Color := CorTexto;
  FEdit.Color := CorCartao;
  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
  FEdit.OnKeyPress := EditKeyPress;
  PosicionarEdit;
end;

function TModernEdit.GetTexto: string;
begin
  Result := FEdit.Text;
end;

procedure TModernEdit.SetTexto(const AValue: string);
begin
  FEdit.Text := AValue;
end;

function TModernEdit.GetSomenteLeitura: Boolean;
begin
  Result := FEdit.ReadOnly;
end;

procedure TModernEdit.SetSomenteLeitura(AValue: Boolean);
begin
  FEdit.ReadOnly := AValue;
  FEdit.TabStop := not AValue;
  if AValue then
    FEdit.Color := CorCampoFundo
  else
    FEdit.Color := CorCartao;
  Invalidate;
end;

procedure TModernEdit.SetRotulo(const AValue: string);
begin
  FRotulo := AValue;
  Invalidate;
end;

procedure TModernEdit.SetDica(const AValue: string);
begin
  FDica := AValue;
  Hint := AValue;
  ShowHint := AValue <> '';
  FEdit.Hint := AValue;
  FEdit.ShowHint := AValue <> '';
end;

procedure TModernEdit.SetIcone(const AValue: TIcone);
begin
  FIcone := AValue;
  PosicionarEdit;
  Invalidate;
end;

procedure TModernEdit.Limpar;
begin
  FEdit.Clear;
end;

procedure TModernEdit.SetFocus;
begin
  if FEdit.CanFocus then
    FEdit.SetFocus
  else
    inherited;
end;

procedure TModernEdit.PosicionarEdit;
var
  Esquerda: Integer;
begin
  Esquerda := 14;
  if FIcone <> icNenhum then
    Esquerda := 42;
  FEdit.SetBounds(Esquerda, ALTURA_ROTULO + (ALTURA_CAIXA - FEdit.Height) div 2,
    Max(20, Width - Esquerda - 12), FEdit.Height);
end;

procedure TModernEdit.Resize;
begin
  inherited;
  PosicionarEdit;
end;

procedure TModernEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FEdit.CanFocus then
    FEdit.SetFocus;
end;

procedure TModernEdit.EditEnter(Sender: TObject);
begin
  FFocado := True;
  Invalidate;
end;

procedure TModernEdit.EditExit(Sender: TObject);
begin
  FFocado := False;
  Invalidate;
  if Assigned(FOnSaida) then
    FOnSaida(Self);
end;

procedure TModernEdit.EditKeyPress(Sender: TObject; var Key: Char);
var
  Formulario: TCustomForm;
begin
  if Key <> #13 then
    Exit;
  Key := #0;
  if Assigned(FOnConfirmar) then
    FOnConfirmar(Self)
  else
  begin
    Formulario := GetParentForm(Self);
    if Formulario <> nil then
      Formulario.Perform(WM_NEXTDLGCTL, 0, 0);
  end;
end;

procedure TModernEdit.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TModernEdit.Paint;
var
  G: TGPGraphics;
  Caminho: TGPGraphicsPath;
  Fundo, Borda: TColor;
  Largura: Single;
begin
  PreencherFundo(Self, Canvas);

  if FRotulo <> '' then
  begin
    Canvas.Font.Name := FonteNomeNegrito;
    Canvas.Font.Size := 9;
    Canvas.Font.Color := CorTextoSuave;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(2, 0, FRotulo);
  end;

  if FEdit.ReadOnly then
    Fundo := CorCampoFundo
  else
    Fundo := CorCartao;
  if FFocado then
  begin
    Borda := CorPrimaria;
    Largura := 2;
  end
  else
  begin
    Borda := CorBordaForte;
    Largura := 1;
  end;

  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    Caminho := CaminhoArredondado(1, ALTURA_ROTULO + 1, Width - 2, ALTURA_CAIXA - 2, 10);
    try
      PintarCaminho(G, Caminho, Fundo, Borda, Largura);
    finally
      Caminho.Free;
    end;
    if FIcone <> icNenhum then
    begin
      if FFocado then
        DesenharIcone(G, FIcone, 14, ALTURA_ROTULO + (ALTURA_CAIXA - 20) / 2, 20, CorPrimaria)
      else
        DesenharIcone(G, FIcone, 14, ALTURA_ROTULO + (ALTURA_CAIXA - 20) / 2, 20, CorTextoSuave);
    end;
  finally
    G.Free;
  end;
end;


end.
