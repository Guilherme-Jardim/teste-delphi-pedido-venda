unit InfoCard;

{ Painel branco com cantos arredondados, título e ícone. }

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
  ComponentAccess,
  ComponentIcons,
  ComponentTheme,
  ComponentUtils;

type
  { TInfoCard }
  TInfoCard = class(TCustomControl)
  private
    FTitulo: string;
    FIcone: TIcone;
    procedure SetTitulo(const AValue: string);
    procedure SetIcone(const AValue: TIcone);
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetObject(var Msg: TMessage); message WM_GETOBJECT;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Titulo: string read FTitulo write SetTitulo;
    property Icone: TIcone read FIcone write SetIcone;
    property Align;
    property AlignWithMargins;
    property Margins;
    property Anchors;
    property Visible;
    property Padding;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TInfoCard]);
end;

{ TInfoCard }

procedure TInfoCard.WMGetObject(var Msg: TMessage);
begin
  // O título é desenhado, então o grupo recebe o título como nome.
  if not ResponderGetObject(Self, Msg,
    function: TDadosAcessiveis
    begin
      Result := NovosDados(FTitulo, PAPEL_AGRUPAMENTO);
    end) then
    inherited;
end;

constructor TInfoCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque] + [csAcceptsControls];
  DoubleBuffered := True;
  Color := CorCartao;
  Padding.SetBounds(20, 20, 20, 20);
end;

procedure TInfoCard.SetTitulo(const AValue: string);
begin
  FTitulo := AValue;
  if FTitulo <> '' then
    Padding.Top := 52
  else
    Padding.Top := 20;
  Invalidate;
end;

procedure TInfoCard.SetIcone(const AValue: TIcone);
begin
  FIcone := AValue;
  Invalidate;
end;

procedure TInfoCard.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TInfoCard.Paint;
var
  G: TGPGraphics;
  Caminho: TGPGraphicsPath;
  X: Integer;
begin
  PreencherFundo(Self, Canvas);
  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    Caminho := CaminhoArredondado(0.5, 0.5, Width - 1, Height - 1, 14);
    try
      PintarCaminho(G, Caminho, CorCartao, CorBorda, 1);
    finally
      Caminho.Free;
    end;
    X := 20;
    if (FTitulo <> '') and (FIcone <> icNenhum) then
    begin
      DesenharIcone(G, FIcone, X, 16, 20, CorPrimaria);
      Inc(X, 28);
    end;
  finally
    G.Free;
  end;

  if FTitulo <> '' then
  begin
    Canvas.Font.Name := FonteNomeNegrito;
    Canvas.Font.Size := 11;
    Canvas.Font.Color := CorTexto;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(X, 16, FTitulo);
  end;
end;


end.
