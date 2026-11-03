unit AlertBar;

{ Faixa de mensagem (erro, sucesso ou informação). }

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
  TTipoAviso = (taErro, taSucesso, taInfo);

  { TAlertBar }
  TAlertBar = class(TCustomControl)
  private
    FMensagem: string;
    FTipo: TTipoAviso;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Mostrar(const AMensagem: string; ATipo: TTipoAviso = taErro);
    procedure Limpar;
  published
    property Align;
    property AlignWithMargins;
    property Margins;
    property Anchors;
    property Visible;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TAlertBar]);
end;

{ TAlertBar }

constructor TAlertBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque];
  DoubleBuffered := True;
  Height := 38;
  Width := 400;
end;

procedure TAlertBar.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TAlertBar.Mostrar(const AMensagem: string; ATipo: TTipoAviso);
begin
  FMensagem := AMensagem;
  FTipo := ATipo;
  Invalidate;
end;

procedure TAlertBar.Limpar;
begin
  FMensagem := '';
  Invalidate;
end;

procedure TAlertBar.Paint;
var
  G: TGPGraphics;
  Caminho: TGPGraphicsPath;
  Fundo, Frente: TColor;
  Icone: TIcone;
  Larg: Integer;
begin
  PreencherFundo(Self, Canvas);
  if FMensagem = '' then
    Exit;

  case FTipo of
    taSucesso:
      begin
        Fundo := CorSucessoSuave;
        Frente := CorSucesso;
        Icone := icSucesso;
      end;
    taInfo:
      begin
        Fundo := CorPrimariaSuave;
        Frente := CorPrimaria;
        Icone := icInfo;
      end;
  else
    Fundo := CorPerigoSuave;
    Frente := CorPerigo;
    Icone := icErro;
  end;

  Canvas.Font.Name := FonteNomeNegrito;
  Canvas.Font.Size := 10;
  Canvas.Font.Color := Frente;
  Canvas.Brush.Style := bsClear;
  Larg := Min(Width, Canvas.TextWidth(FMensagem) + 56);

  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    Caminho := CaminhoArredondado(0.5, 0.5, Larg - 1, Height - 1, (Height - 1) / 2);
    try
      PintarCaminho(G, Caminho, Fundo, clNone, 1);
    finally
      Caminho.Free;
    end;
    DesenharIcone(G, Icone, 14, (Height - 20) / 2, 20, Frente);
  finally
    G.Free;
  end;
  Canvas.TextOut(42, (Height - Canvas.TextHeight(FMensagem)) div 2, FMensagem);
end;


end.
