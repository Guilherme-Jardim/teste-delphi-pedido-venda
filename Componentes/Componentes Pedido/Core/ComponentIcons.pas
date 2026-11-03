unit ComponentIcons;

{ Ícones vetoriais desenhados em código com GDI+ (nenhuma imagem externa).
  Cada ícone usa uma grade de 24 x 24 que é escalada para o tamanho pedido. }

interface

uses
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Vcl.Graphics;

type
  TIcone = (icNenhum, icMais, icCheck, icLixeira, icLapis, icBusca, icNovo,
    icSalvar, icSair, icUsuario, icCadeado, icCaixa, icErro, icInfo, icSucesso,
    icPasta);

function CorParaARGB(ACor: TColor; AAlfa: Byte = 255): ARGB;

// Retângulo com cantos arredondados; ARaio = metade da altura gera a "pílula".
function CaminhoArredondado(X, Y, L, A, ARaio: Single): TGPGraphicsPath;

procedure DesenharIcone(G: TGPGraphics; AIcone: TIcone; X, Y, ATamanho: Single;
  ACor: TColor);

implementation

uses
  Winapi.Windows;

function CorParaARGB(ACor: TColor; AAlfa: Byte): ARGB;
var
  RGB: LongInt;
begin
  RGB := ColorToRGB(ACor);
  Result := MakeColor(AAlfa, GetRValue(RGB), GetGValue(RGB), GetBValue(RGB));
end;

function CaminhoArredondado(X, Y, L, A, ARaio: Single): TGPGraphicsPath;
var
  D: Single;
begin
  D := ARaio * 2;
  if D > L then D := L;
  if D > A then D := A;
  Result := TGPGraphicsPath.Create;
  Result.AddArc(X, Y, D, D, 180, 90);
  Result.AddArc(X + L - D, Y, D, D, 270, 90);
  Result.AddArc(X + L - D, Y + A - D, D, D, 0, 90);
  Result.AddArc(X, Y + A - D, D, D, 90, 90);
  Result.CloseFigure;
end;

procedure DesenharIcone(G: TGPGraphics; AIcone: TIcone; X, Y, ATamanho: Single;
  ACor: TColor);
var
  Pen: TGPPen;
  E: Single;

  function PX(V: Single): Single;
  begin
    Result := X + V * E;
  end;

  function PY(V: Single): Single;
  begin
    Result := Y + V * E;
  end;

  procedure Linha(X1, Y1, X2, Y2: Single);
  begin
    G.DrawLine(Pen, PX(X1), PY(Y1), PX(X2), PY(Y2));
  end;

  procedure Elipse(X1, Y1, L, A: Single);
  begin
    G.DrawEllipse(Pen, PX(X1), PY(Y1), L * E, A * E);
  end;

  procedure Arco(X1, Y1, L, A, Inicio, Varredura: Single);
  begin
    G.DrawArc(Pen, PX(X1), PY(Y1), L * E, A * E, Inicio, Varredura);
  end;

begin
  if AIcone = icNenhum then
    Exit;

  E := ATamanho / 24;
  Pen := TGPPen.Create(CorParaARGB(ACor), 2 * E);
  try
    Pen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
    Pen.SetLineJoin(LineJoinRound);

    case AIcone of
      icMais:
        begin
          Linha(12, 5, 12, 19);
          Linha(5, 12, 19, 12);
        end;
      icCheck:
        begin
          Linha(5, 13, 10, 18);
          Linha(10, 18, 19, 7);
        end;
      icLixeira:
        begin
          Linha(4, 7, 20, 7);
          Linha(9, 7, 9, 4);
          Linha(9, 4, 15, 4);
          Linha(15, 4, 15, 7);
          Linha(6, 7, 7, 20);
          Linha(7, 20, 17, 20);
          Linha(17, 20, 18, 7);
          Linha(10, 11, 10, 16);
          Linha(14, 11, 14, 16);
        end;
      icLapis:
        begin
          Linha(4, 20, 5, 15);
          Linha(5, 15, 16, 4);
          Linha(16, 4, 20, 8);
          Linha(20, 8, 9, 19);
          Linha(9, 19, 4, 20);
          Linha(13, 7, 17, 11);
        end;
      icBusca:
        begin
          Elipse(4, 4, 13, 13);
          Linha(15, 15, 20, 20);
        end;
      icNovo:
        begin
          Linha(6, 3, 14, 3);
          Linha(14, 3, 19, 8);
          Linha(19, 8, 19, 21);
          Linha(19, 21, 6, 21);
          Linha(6, 21, 6, 3);
          Linha(14, 3, 14, 8);
          Linha(14, 8, 19, 8);
          Linha(12.5, 12, 12.5, 18);
          Linha(9.5, 15, 15.5, 15);
        end;
      icSalvar:
        begin
          Linha(4, 4, 17, 4);
          Linha(17, 4, 20, 7);
          Linha(20, 7, 20, 20);
          Linha(20, 20, 4, 20);
          Linha(4, 20, 4, 4);
          Linha(8, 4, 8, 9);
          Linha(8, 9, 15, 9);
          Linha(15, 9, 15, 4);
          Linha(8, 20, 8, 14);
          Linha(8, 14, 16, 14);
          Linha(16, 14, 16, 20);
        end;
      icSair:
        begin
          Arco(5, 5, 14, 14, -50, 280);
          Linha(12, 3, 12, 12);
        end;
      icUsuario:
        begin
          Elipse(8, 4, 8, 8);
          Arco(4, 14, 16, 14, 180, 180);
        end;
      icCadeado:
        begin
          Arco(8, 3, 8, 10, 180, 180);
          Linha(8, 8, 8, 11);
          Linha(16, 8, 16, 11);
          Linha(5, 11, 19, 11);
          Linha(19, 11, 19, 21);
          Linha(19, 21, 5, 21);
          Linha(5, 21, 5, 11);
          Linha(12, 15, 12, 17);
        end;
      icCaixa:
        begin
          Linha(12, 3, 20, 7.5);
          Linha(20, 7.5, 20, 16.5);
          Linha(20, 16.5, 12, 21);
          Linha(12, 21, 4, 16.5);
          Linha(4, 16.5, 4, 7.5);
          Linha(4, 7.5, 12, 3);
          Linha(4, 7.5, 12, 12);
          Linha(12, 12, 20, 7.5);
          Linha(12, 12, 12, 21);
        end;
      icErro:
        begin
          Elipse(3, 3, 18, 18);
          Linha(12, 7.5, 12, 13);
          Linha(12, 16.4, 12, 16.6);
        end;
      icInfo:
        begin
          Elipse(3, 3, 18, 18);
          Linha(12, 11, 12, 16.5);
          Linha(12, 7.4, 12, 7.6);
        end;
      icSucesso:
        begin
          Elipse(3, 3, 18, 18);
          Linha(8, 12.5, 11, 15.5);
          Linha(11, 15.5, 16, 9);
        end;
      icPasta:
        begin
          Linha(3, 6, 9, 6);
          Linha(9, 6, 11, 8);
          Linha(11, 8, 21, 8);
          Linha(21, 8, 21, 19);
          Linha(21, 19, 3, 19);
          Linha(3, 19, 3, 6);
        end;
    end;
  finally
    Pen.Free;
  end;
end;

end.
