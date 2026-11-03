unit Pedido.Infra.BancoDados.Tipos;

{ Tipos e contratos da inicialização do banco. São interfaces pequenas, uma
  para cada responsabilidade: diagnosticar, criar/atualizar e lembrar o que já
  foi criado. Assim cada peça pode ser testada e trocada sozinha. }

interface

uses
  Pedido.Infra.Config;

type
  TEstadoBanco = (
    ebOk,
    ebBancoInexistente,
    ebSemEstrutura,
    ebEstruturaDesatualizada,
    ebBancoDeOutroSistema,
    ebServidorIndisponivel,
    ebCredenciaisInvalidas,
    ebBibliotecaIndisponivel,
    ebErroInesperado);

  TDiagnosticoBanco = record
    Estado: TEstadoBanco;
    // Texto técnico para o log (nunca vai para a tela).
    Detalhe: string;
    class function Criar(AEstado: TEstadoBanco; const ADetalhe: string = ''): TDiagnosticoBanco; static;
  end;

  // Olha o banco e diz em que situação ele está, sem alterar nada.
  IInspetorBanco = interface
    ['{9C4A7E31-5D02-48B6-A1F8-2B6E0D3C7A95}']
    function Diagnosticar(const AConfig: TConfigBanco): TDiagnosticoBanco;
  end;

  // Cria ou ajusta o banco. Só roda depois que a pessoa (ou a regra da primeira vez) autorizou.
  ICriadorBanco = interface
    ['{E1B65D28-0F93-4A7C-8D46-A5C3921E7B04}']
    procedure CriarBancoNovo(const AConfig: TConfigBanco);
    procedure CriarEstrutura(const AConfig: TConfigBanco);
    procedure AtualizarEstrutura(const AConfig: TConfigBanco);
  end;

  // Lembra quais bancos este computador já criou, para distinguir
  // "nunca foi criado" de "foi criado e sumiu".
  IRegistroBanco = interface
    ['{37D9A2C6-8E15-4B40-B7F3-6A1C5E9D0842}']
    function JaFoiCriado(const AConfig: TConfigBanco): Boolean;
    procedure Registrar(const AConfig: TConfigBanco);
  end;

implementation

class function TDiagnosticoBanco.Criar(AEstado: TEstadoBanco;
  const ADetalhe: string): TDiagnosticoBanco;
begin
  Result.Estado := AEstado;
  Result.Detalhe := ADetalhe;
end;

end.
