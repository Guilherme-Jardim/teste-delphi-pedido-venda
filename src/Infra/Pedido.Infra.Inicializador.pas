unit Pedido.Infra.Inicializador;

{ Prepara o sistema para abrir: garante que existe um config.ini utilizável e
  um banco de dados utilizável, tratando cada situação que pode acontecer.

  Esta unit só tem a lógica (a "receita"). Ela não conhece FireDAC, janelas
  nem arquivos: tudo chega por interface (config, inspetor, criador, registro e
  interação com a pessoa). Por isso cada cenário é testado com peças falsas.

  Cenários tratados:
    - config.ini ausente (primeira execução): abre a configuração com sugestões
    - config.ini corrompido ou inválido: avisa, guarda cópia e pede para reconfigurar
    - banco inexistente e nunca criado: cria sozinho
    - banco inexistente mas que já foi criado antes (apagado/movido): avisa e pergunta
    - banco vazio ou incompleto: oferece criar a estrutura (sem apagar nada)
    - banco de outro sistema: não mexe; pede outro caminho
    - estrutura antiga (falta OBSERVACAO): atualiza sozinho
    - servidor parado, usuário/senha inválidos, biblioteca ausente ou com bits errados
    - falhas inesperadas: registra no log e oferece tentar de novo, ajustar ou sair }

interface

uses
  System.SysUtils,
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config;

type
  TProblemaInicializacao = (
    pbConfigInvalida,
    pbBancoSumiu,
    pbSemEstrutura,
    pbBancoDeOutroSistema,
    pbServidorIndisponivel,
    pbCredenciaisInvalidas,
    pbBibliotecaIndisponivel,
    pbErroInesperado);

  // A ordem define a ordem dos botões na tela: a ação principal vem primeiro.
  TAcaoUsuario = (auCriarBancoNovo, auCriarEstrutura, auTentarNovamente, auReconfigurar, auSair);
  TAcoesUsuario = set of TAcaoUsuario;

  TAvisoInicializacao = (avBancoCriado, avEstruturaCriada, avEstruturaAtualizada);

  // Tudo que precisa de uma pessoa (janelas) passa por aqui.
  IInteracaoInicializacao = interface
    ['{A2D64F58-1C97-4E03-B5A9-7F0E3C8D1B26}']
    // Abre a tela de configuração. False se a pessoa cancelou.
    function ConfigurarBanco(const ASugestao: TConfigBanco; APrimeiraVez: Boolean;
      out AConfig: TConfigBanco): Boolean;
    // Mostra o problema e devolve a ação escolhida entre as permitidas.
    function PerguntarAcao(AProblema: TProblemaInicializacao; const AConfig: TConfigBanco;
      const ADetalhe: string; const APermitidas: TAcoesUsuario): TAcaoUsuario;
    procedure Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
  end;

  TInicializadorSistema = class
  private
    type
      TPasso = (psConcluido, psRepetir, psAbortado);
    var
      FConfigRepositorio: IConfigRepositorio;
      FInspetor: IInspetorBanco;
      FCriador: ICriadorBanco;
      FRegistro: IRegistroBanco;
      FInteracao: IInteracaoInicializacao;
      FConfigAtual: TConfigBanco;
    function PassoPrimeiraConfiguracao: TPasso;
    function PassoConfigInvalida(const AConfigLida: TConfigBanco; const AMotivo: string): TPasso;
    function PassoReconfigurar(const AConfig: TConfigBanco): TPasso;
    function PassoBanco(const AConfig: TConfigBanco): TPasso;
    function PassoBancoInexistente(const AConfig: TConfigBanco): TPasso;
    function PassoServidorOuCredenciais(AProblema: TProblemaInicializacao;
      const AConfig: TConfigBanco; const ADetalhe: string): TPasso;
    function ExecutarComSeguranca(const AConfig: TConfigBanco; const AContexto: string;
      const AAcao: TProc; AAviso: TAvisoInicializacao; out APasso: TPasso): Boolean;
    function ResolverAcao(AAcao: TAcaoUsuario; const AConfig: TConfigBanco): TPasso;
    function ExecutarPasso: TPasso;
  public
    constructor Create(const AConfigRepositorio: IConfigRepositorio;
      const AInspetor: IInspetorBanco; const ACriador: ICriadorBanco;
      const ARegistro: IRegistroBanco; const AInteracao: IInteracaoInicializacao);
    // True quando há config e banco prontos (AConfig traz a configuração a usar).
    function Executar(out AConfig: TConfigBanco): Boolean;
  end;

const
  // Evita laço infinito se alguém ficar repetindo "tentar de novo" sem resolver.
  MAX_TENTATIVAS_INICIALIZACAO = 12;

implementation

uses
  Pedido.Infra.Log;

constructor TInicializadorSistema.Create(const AConfigRepositorio: IConfigRepositorio;
  const AInspetor: IInspetorBanco; const ACriador: ICriadorBanco;
  const ARegistro: IRegistroBanco; const AInteracao: IInteracaoInicializacao);
begin
  inherited Create;
  FConfigRepositorio := AConfigRepositorio;
  FInspetor := AInspetor;
  FCriador := ACriador;
  FRegistro := ARegistro;
  FInteracao := AInteracao;
end;

function TInicializadorSistema.Executar(out AConfig: TConfigBanco): Boolean;
var
  Tentativa: Integer;
  Resultado: TPasso;
begin
  AConfig := Default(TConfigBanco);
  for Tentativa := 1 to MAX_TENTATIVAS_INICIALIZACAO do
  begin
    FConfigAtual := Default(TConfigBanco);
    Resultado := ExecutarPasso;
    case Resultado of
      psConcluido:
        begin
          AConfig := FConfigAtual;
          Exit(True);
        end;
      psAbortado:
        Exit(False);
    end;
  end;
  RegistrarInformacao('Inicialização interrompida: número máximo de tentativas atingido');
  Result := False;
end;

function TInicializadorSistema.ExecutarPasso: TPasso;
var
  Config: TConfigBanco;
  Motivo: string;
begin
  case FConfigRepositorio.Carregar(Config, Motivo) of
    rcAusente:
      Result := PassoPrimeiraConfiguracao;
    rcInvalida:
      Result := PassoConfigInvalida(Config, Motivo);
  else
    FConfigAtual := Config;
    Result := PassoBanco(Config);
  end;
end;

function TInicializadorSistema.PassoPrimeiraConfiguracao: TPasso;
var
  Nova: TConfigBanco;
begin
  // Primeira execução: abre a configuração já preenchida com sugestões.
  if not FInteracao.ConfigurarBanco(TConfigPadrao.Sugerir(FConfigRepositorio.Caminho), True, Nova) then
    Exit(psAbortado);
  try
    FConfigRepositorio.Salvar(Nova);
  except
    on E: Exception do
    begin
      RegistrarLog('Falha ao gravar o config.ini', E);
      Exit(ResolverAcao(FInteracao.PerguntarAcao(pbErroInesperado, Nova, E.Message,
        [auTentarNovamente, auSair]), Nova));
    end;
  end;
  Result := psRepetir;
end;

function TInicializadorSistema.PassoConfigInvalida(const AConfigLida: TConfigBanco;
  const AMotivo: string): TPasso;
var
  Parcial: TConfigBanco;
begin
  Parcial := TConfigPadrao.Completar(AConfigLida, TConfigPadrao.Sugerir(FConfigRepositorio.Caminho));
  case FInteracao.PerguntarAcao(pbConfigInvalida, Parcial, AMotivo, [auReconfigurar, auSair]) of
    auReconfigurar:
      Result := PassoReconfigurar(Parcial);
  else
    Result := psAbortado;
  end;
end;

function TInicializadorSistema.PassoReconfigurar(const AConfig: TConfigBanco): TPasso;
var
  Nova: TConfigBanco;
begin
  if not FInteracao.ConfigurarBanco(AConfig, False, Nova) then
    Exit(psAbortado);
  try
    FConfigRepositorio.GuardarCopia;
    FConfigRepositorio.Salvar(Nova);
  except
    on E: Exception do
    begin
      RegistrarLog('Falha ao gravar o config.ini', E);
      Exit(ResolverAcao(FInteracao.PerguntarAcao(pbErroInesperado, Nova, E.Message,
        [auTentarNovamente, auSair]), Nova));
    end;
  end;
  Result := psRepetir;
end;

function TInicializadorSistema.ResolverAcao(AAcao: TAcaoUsuario; const AConfig: TConfigBanco): TPasso;
begin
  case AAcao of
    auTentarNovamente:
      Result := psRepetir;
    auReconfigurar:
      Result := PassoReconfigurar(AConfig);
  else
    Result := psAbortado;
  end;
end;

function TInicializadorSistema.ExecutarComSeguranca(const AConfig: TConfigBanco;
  const AContexto: string; const AAcao: TProc; AAviso: TAvisoInicializacao;
  out APasso: TPasso): Boolean;
begin
  Result := False;
  try
    AAcao();
    FRegistro.Registrar(AConfig);
    FInteracao.Informar(AAviso, AConfig);
    APasso := psRepetir; // confere de novo se ficou tudo certo
    Result := True;
  except
    on E: Exception do
    begin
      RegistrarLog(AContexto, E);
      APasso := ResolverAcao(FInteracao.PerguntarAcao(pbErroInesperado, AConfig, E.Message,
        [auTentarNovamente, auReconfigurar, auSair]), AConfig);
    end;
  end;
end;

function TInicializadorSistema.PassoBancoInexistente(const AConfig: TConfigBanco): TPasso;
var
  Proximo: TPasso;
begin
  if not FRegistro.JaFoiCriado(AConfig) then
  begin
    // Nunca foi criado neste computador: cria sem perguntar.
    ExecutarComSeguranca(AConfig, 'Falha ao criar o banco',
      procedure
      begin
        FCriador.CriarBancoNovo(AConfig);
      end, avBancoCriado, Proximo);
    Exit(Proximo);
  end;

  // Já existiu e não está mais lá (apagado, movido ou fora de alcance): pergunta.
  case FInteracao.PerguntarAcao(pbBancoSumiu, AConfig, '',
    [auCriarBancoNovo, auReconfigurar, auSair]) of
    auCriarBancoNovo:
      begin
        ExecutarComSeguranca(AConfig, 'Falha ao criar o banco novo',
          procedure
          begin
            FCriador.CriarBancoNovo(AConfig);
          end, avBancoCriado, Proximo);
        Result := Proximo;
      end;
    auReconfigurar:
      Result := PassoReconfigurar(AConfig);
  else
    Result := psAbortado;
  end;
end;

function TInicializadorSistema.PassoServidorOuCredenciais(AProblema: TProblemaInicializacao;
  const AConfig: TConfigBanco; const ADetalhe: string): TPasso;
begin
  case FInteracao.PerguntarAcao(AProblema, AConfig, ADetalhe,
    [auTentarNovamente, auReconfigurar, auSair]) of
    auTentarNovamente:
      Result := psRepetir;
    auReconfigurar:
      Result := PassoReconfigurar(AConfig);
  else
    Result := psAbortado;
  end;
end;

function TInicializadorSistema.PassoBanco(const AConfig: TConfigBanco): TPasso;
var
  Diagnostico: TDiagnosticoBanco;
  Proximo: TPasso;
begin
  Diagnostico := FInspetor.Diagnosticar(AConfig);
  if Diagnostico.Detalhe <> '' then
    RegistrarInformacao('Diagnóstico do banco: ' + Diagnostico.Detalhe);

  case Diagnostico.Estado of
    ebOk:
      begin
        // Banco funcionando: passa a ser lembrado (para avisar se um dia sumir).
        FRegistro.Registrar(AConfig);
        Result := psConcluido;
      end;

    ebBancoInexistente:
      Result := PassoBancoInexistente(AConfig);

    ebSemEstrutura:
      case FInteracao.PerguntarAcao(pbSemEstrutura, AConfig, Diagnostico.Detalhe,
        [auCriarEstrutura, auReconfigurar, auSair]) of
        auCriarEstrutura:
          begin
            ExecutarComSeguranca(AConfig, 'Falha ao criar a estrutura',
              procedure
              begin
                FCriador.CriarEstrutura(AConfig);
              end, avEstruturaCriada, Proximo);
            Result := Proximo;
          end;
        auReconfigurar:
          Result := PassoReconfigurar(AConfig);
      else
        Result := psAbortado;
      end;

    ebEstruturaDesatualizada:
      begin
        // Só acrescenta a coluna que falta: não perde dado e não precisa perguntar.
        ExecutarComSeguranca(AConfig, 'Falha ao atualizar a estrutura',
          procedure
          begin
            FCriador.AtualizarEstrutura(AConfig);
          end, avEstruturaAtualizada, Proximo);
        Result := Proximo;
      end;

    ebBancoDeOutroSistema:
      case FInteracao.PerguntarAcao(pbBancoDeOutroSistema, AConfig, Diagnostico.Detalhe,
        [auReconfigurar, auSair]) of
        auReconfigurar:
          Result := PassoReconfigurar(AConfig);
      else
        Result := psAbortado;
      end;

    ebServidorIndisponivel:
      Result := PassoServidorOuCredenciais(pbServidorIndisponivel, AConfig, Diagnostico.Detalhe);

    ebCredenciaisInvalidas:
      Result := PassoServidorOuCredenciais(pbCredenciaisInvalidas, AConfig, Diagnostico.Detalhe);

    ebBibliotecaIndisponivel:
      case FInteracao.PerguntarAcao(pbBibliotecaIndisponivel, AConfig, Diagnostico.Detalhe,
        [auReconfigurar, auSair]) of
        auReconfigurar:
          Result := PassoReconfigurar(AConfig);
      else
        Result := psAbortado;
      end;
  else
    // ebErroInesperado
    Result := PassoServidorOuCredenciais(pbErroInesperado, AConfig, Diagnostico.Detalhe);
  end;
end;

end.
