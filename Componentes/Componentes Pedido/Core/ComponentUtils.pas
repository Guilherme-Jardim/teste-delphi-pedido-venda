unit ComponentUtils;

{ Funções de apoio compartilhadas pelos componentes do pacote. }

interface

uses
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Vcl.Controls,
  Vcl.Graphics;

// Cor de fundo do controle pai (usada para pintar os cantos arredondados).
function CorDoPai(AControle: TControl): TColor;
procedure PreencherFundo(AControle: TControl; ACanvas: TCanvas);
procedure PintarCaminho(G: TGPGraphics; ACaminho: TGPGraphicsPath; APreenchimento: TColor;
  ABorda: TColor; ALarguraBorda: Single);

implementation

uses
  ComponentIcons,
  ComponentTheme;

type
  TControleAcesso = class(TControl);

function CorDoPai(AControle: TControl): TColor;
begin
  if AControle.Parent <> nil then
    Result := TControleAcesso(AControle.Parent).Color
  else
    Result := CorFundo;
end;

procedure PreencherFundo(AControle: TControl; ACanvas: TCanvas);
begin
  ACanvas.Brush.Color := CorDoPai(AControle);
  ACanvas.FillRect(AControle.ClientRect);
end;

procedure PintarCaminho(G: TGPGraphics; ACaminho: TGPGraphicsPath; APreenchimento: TColor;
  ABorda: TColor; ALarguraBorda: Single);
var
  Pincel: TGPSolidBrush;
  Caneta: TGPPen;
begin
  if APreenchimento <> clNone then
  begin
    Pincel := TGPSolidBrush.Create(CorParaARGB(APreenchimento));
    try
      G.FillPath(Pincel, ACaminho);
    finally
      Pincel.Free;
    end;
  end;
  if ABorda <> clNone then
  begin
    Caneta := TGPPen.Create(CorParaARGB(ABorda), ALarguraBorda);
    try
      G.DrawPath(Caneta, ACaminho);
    finally
      Caneta.Free;
    end;
  end;
end;


end.
