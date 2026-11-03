unit Pedido.Infra.Log;

{ Registro técnico de falhas. A tela mostra uma mensagem simples; o detalhe
  (que pode citar tabelas e SQL) vai só para este arquivo, em
  %LOCALAPPDATA%\PedidoVenda\pedido.log. Nunca grava senhas nem dados do pedido. }

interface

uses
  System.SysUtils;

procedure RegistrarLog(const AContexto: string; AErro: Exception);
// Registra uma linha informativa (por exemplo, a versão ao abrir o sistema).
procedure RegistrarInformacao(const AMensagem: string);

implementation

uses
  System.IOUtils;

const
  TAMANHO_MAXIMO_ARQUIVO = 1024 * 1024; // 1 MB: depois disso o arquivo recomeça

function CaminhoDoLog: string;
begin
  Result := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'PedidoVenda'),
    'pedido.log');
end;

procedure GravarLinha(const ALinha: string);
var
  Caminho: string;
begin
  try
    Caminho := CaminhoDoLog;
    TDirectory.CreateDirectory(TPath.GetDirectoryName(Caminho));
    if TFile.Exists(Caminho) and (TFile.GetSize(Caminho) > TAMANHO_MAXIMO_ARQUIVO) then
      TFile.Delete(Caminho);
    TFile.AppendAllText(Caminho, ALinha + sLineBreak, TEncoding.UTF8);
  except
    // O log nunca pode derrubar o sistema.
  end;
end;

procedure RegistrarLog(const AContexto: string; AErro: Exception);
begin
  GravarLinha(Format('%s | %s | %s: %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AContexto, AErro.ClassName, AErro.Message]));
end;

procedure RegistrarInformacao(const AMensagem: string);
begin
  GravarLinha(Format('%s | info | %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMensagem]));
end;

end.
