unit Pedido.View.Dialogos;

{ Diálogos padronizados do sistema, no mesmo visual das telas e com os textos
  no idioma escolhido (em vez das caixas do Windows). }

interface

uses
  ComponentIcons;

// Mostra a pergunta e devolve True se a pessoa escolheu "Sim".
// APerigosa pinta o botão principal de vermelho (exclusões e cancelamentos).
function ConfirmarAcao(const APergunta: string; APerigosa: Boolean = False): Boolean;

// Aviso com um botão "OK".
procedure MostrarAviso(const ATitulo, ATexto: string; AIcone: TIcone = icInfo);

// Mostra de 1 a 4 opções e devolve o índice escolhido, ou -1 se a janela foi fechada.
function EscolherAcao(const ATitulo, ATexto: string; AIcone: TIcone;
  const ALegendas: array of string): Integer;

implementation

uses
  Pedido.Infra.Idioma,
  Pedido.View.DialogoModerno;

function ConfirmarAcao(const APergunta: string; APerigosa: Boolean): Boolean;
var
  Icone: TIcone;
begin
  if APerigosa then
    Icone := icLixeira
  else
    Icone := icInfo;
  Result := TfrmDialogoModerno.Mostrar(Tr('dlg.confirmar_titulo'), APergunta, Icone,
    [Tr('dlg.sim'), Tr('dlg.nao')], APerigosa) = 0;
end;

procedure MostrarAviso(const ATitulo, ATexto: string; AIcone: TIcone);
begin
  TfrmDialogoModerno.Mostrar(ATitulo, ATexto, AIcone, [Tr('dlg.ok')]);
end;

function EscolherAcao(const ATitulo, ATexto: string; AIcone: TIcone;
  const ALegendas: array of string): Integer;
begin
  Result := TfrmDialogoModerno.Mostrar(ATitulo, ATexto, AIcone, ALegendas);
end;

end.
