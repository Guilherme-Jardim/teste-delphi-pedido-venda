unit Pedido.Tests.Inicializador;

{ Todos os cenários da inicialização, com peças falsas: config, inspetor,
  criador, registro e a "pessoa" (interação). Sem banco e sem janelas. }

interface

uses
  System.Generics.Collections,
  DUnitX.TestFramework,
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config,
  Pedido.Infra.Inicializador;

type
  TConfigRepositorioFalso = class(TInterfacedObject, IConfigRepositorio)
  public
    Resultado: TResultadoConfig;
    Config: TConfigBanco;
    Motivo: string;
    Salvos: TList<TConfigBanco>;
    Copias: Integer;
    FalharAoSalvar: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Caminho: string;
    function Carregar(out AConfig: TConfigBanco; out AMotivo: string): TResultadoConfig;
    procedure Salvar(const AConfig: TConfigBanco);
    function GuardarCopia: string;
  end;

  TInspetorFalso = class(TInterfacedObject, IInspetorBanco)
  public
    Fila: TQueue<TDiagnosticoBanco>;
    Padrao: TDiagnosticoBanco;
    Chamadas: Integer;
    constructor Create;
    destructor Destroy; override;
    function Diagnosticar(const AConfig: TConfigBanco): TDiagnosticoBanco;
  end;

  TCriadorFalso = class(TInterfacedObject, ICriadorBanco)
  public
    BancosCriados, EstruturasCriadas, EstruturasAtualizadas: Integer;
    Falhar: Boolean;
    procedure CriarBancoNovo(const AConfig: TConfigBanco);
    procedure CriarEstrutura(const AConfig: TConfigBanco);
    procedure AtualizarEstrutura(const AConfig: TConfigBanco);
  end;

  TRegistroFalso = class(TInterfacedObject, IRegistroBanco)
  public
    Criados: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function JaFoiCriado(const AConfig: TConfigBanco): Boolean;
    procedure Registrar(const AConfig: TConfigBanco);
  end;

  TInteracaoFalsa = class(TInterfacedObject, IInteracaoInicializacao)
  public
    Respostas: TQueue<TAcaoUsuario>;
    RespostaPadrao: TAcaoUsuario;
    ConfigurarResponde: Boolean;
    ConfigParaDevolver: TConfigBanco;
    Perguntas: TList<TProblemaInicializacao>;
    UltimasPermitidas: TAcoesUsuario;
    Avisos: TList<TAvisoInicializacao>;
    ConfigurarChamadas: Integer;
    UltimaFoiPrimeiraVez: Boolean;
    constructor Create;
    destructor Destroy; override;
    function ConfigurarBanco(const ASugestao: TConfigBanco; APrimeiraVez: Boolean;
      out AConfig: TConfigBanco): Boolean;
    function PerguntarAcao(AProblema: TProblemaInicializacao; const AConfig: TConfigBanco;
      const ADetalhe: string; const APermitidas: TAcoesUsuario): TAcaoUsuario;
    procedure Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
  end;

  [TestFixture]
  TTestesInicializador = class
  private
    FConfigRepo: TConfigRepositorioFalso;
    FInspetor: TInspetorFalso;
    FCriador: TCriadorFalso;
    FRegistro: TRegistroFalso;
    FInteracao: TInteracaoFalsa;
    FInicializador: TInicializadorSistema;
    FRepoIntf: IConfigRepositorio;
    FInspetorIntf: IInspetorBanco;
    FCriadorIntf: ICriadorBanco;
    FRegistroIntf: IRegistroBanco;
    FInteracaoIntf: IInteracaoInicializacao;
    function ConfigBoa: TConfigBanco;
    function Executar(out AConfig: TConfigBanco): Boolean;
    procedure ProximoDiagnostico(AEstado: TEstadoBanco);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure PrimeiraExecucaoCanceladaNaoGravaNada;
    [Test]
    procedure PrimeiraExecucaoGravaAConfiguracaoEContinua;
    [Test]
    procedure PrimeiraExecucaoAbreAConfiguracaoComoPrimeiraVez;
    [Test]
    procedure ConfigCorrompidaPerguntaEPodeSair;
    [Test]
    procedure ConfigCorrompidaReconfiguraGuardandoCopia;
    [Test]
    procedure ConfigCorrompidaReconfiguracaoCanceladaEncerra;
    [Test]
    procedure BancoOkConcluiERegistraOBanco;
    [Test]
    procedure BancoNuncaCriadoECriadoSemPerguntar;
    [Test]
    procedure BancoNuncaCriadoAvisaQueCriou;
    [Test]
    procedure BancoQueSumiuPerguntaAntesDeCriar;
    [Test]
    procedure BancoQueSumiuEPessoaEscolheSairNaoCriaNada;
    [Test]
    procedure BancoQueSumiuEPessoaEscolheCriarNovoCria;
    [Test]
    procedure BancoQueSumiuEPessoaEscolheReconfigurar;
    [Test]
    procedure BancoSemEstruturaPerguntaESoCriaSeConfirmar;
    [Test]
    procedure BancoSemEstruturaRecusadoEncerra;
    [Test]
    procedure EstruturaDesatualizadaAtualizaSozinha;
    [Test]
    procedure BancoDeOutroSistemaNuncaOfereceCriar;
    [Test]
    procedure ServidorIndisponivelPermiteTentarDeNovo;
    [Test]
    procedure ServidorIndisponivelNaoOfereceCriarBanco;
    [Test]
    procedure CredenciaisInvalidasOferecemReconfigurar;
    [Test]
    procedure BibliotecaIndisponivelOferecaSoReconfigurarOuSair;
    [Test]
    procedure ErroInesperadoNoDiagnosticoPergunta;
    [Test]
    procedure FalhaAoCriarBancoRegistraEPergunta;
    [Test]
    procedure FalhaAoCriarBancoNaoRegistraOBancoComoCriado;
    [Test]
    procedure FalhaAoGravarConfigPergunta;
    [Test]
    procedure RepetirParaSempreEhInterrompidoPeloLimite;
    [Test]
    procedure SairEmQualquerProblemaEncerraSemTentarMais;
  end;

implementation

uses
  System.SysUtils;

{ TConfigRepositorioFalso }

constructor TConfigRepositorioFalso.Create;
begin
  inherited Create;
  Salvos := TList<TConfigBanco>.Create;
end;

destructor TConfigRepositorioFalso.Destroy;
begin
  Salvos.Free;
  inherited;
end;

function TConfigRepositorioFalso.Caminho: string;
begin
  Result := 'C:\teste\config.ini';
end;

function TConfigRepositorioFalso.Carregar(out AConfig: TConfigBanco;
  out AMotivo: string): TResultadoConfig;
begin
  AConfig := Config;
  AMotivo := Motivo;
  Result := Resultado;
end;

procedure TConfigRepositorioFalso.Salvar(const AConfig: TConfigBanco);
begin
  if FalharAoSalvar then
    raise EInOutError.Create('Sem permissão para gravar');
  Salvos.Add(AConfig);
  // Depois de salvo, o arquivo passa a existir e a ser válido.
  Config := AConfig;
  Resultado := rcOk;
end;

function TConfigRepositorioFalso.GuardarCopia: string;
begin
  Inc(Copias);
  Result := 'C:\teste\config.ini.bak';
end;

{ TInspetorFalso }

constructor TInspetorFalso.Create;
begin
  inherited Create;
  Fila := TQueue<TDiagnosticoBanco>.Create;
  Padrao := TDiagnosticoBanco.Criar(ebOk);
end;

destructor TInspetorFalso.Destroy;
begin
  Fila.Free;
  inherited;
end;

function TInspetorFalso.Diagnosticar(const AConfig: TConfigBanco): TDiagnosticoBanco;
begin
  Inc(Chamadas);
  if Fila.Count > 0 then
    Result := Fila.Dequeue
  else
    Result := Padrao;
end;

{ TCriadorFalso }

procedure TCriadorFalso.CriarBancoNovo(const AConfig: TConfigBanco);
begin
  if Falhar then
    raise Exception.Create('Disco cheio');
  Inc(BancosCriados);
end;

procedure TCriadorFalso.CriarEstrutura(const AConfig: TConfigBanco);
begin
  if Falhar then
    raise Exception.Create('Sem permissão');
  Inc(EstruturasCriadas);
end;

procedure TCriadorFalso.AtualizarEstrutura(const AConfig: TConfigBanco);
begin
  if Falhar then
    raise Exception.Create('Sem permissão');
  Inc(EstruturasAtualizadas);
end;

{ TRegistroFalso }

constructor TRegistroFalso.Create;
begin
  inherited Create;
  Criados := TList<string>.Create;
end;

destructor TRegistroFalso.Destroy;
begin
  Criados.Free;
  inherited;
end;

function TRegistroFalso.JaFoiCriado(const AConfig: TConfigBanco): Boolean;
begin
  Result := Criados.Contains(AConfig.Chave);
end;

procedure TRegistroFalso.Registrar(const AConfig: TConfigBanco);
begin
  if not Criados.Contains(AConfig.Chave) then
    Criados.Add(AConfig.Chave);
end;

{ TInteracaoFalsa }

constructor TInteracaoFalsa.Create;
begin
  inherited Create;
  Respostas := TQueue<TAcaoUsuario>.Create;
  Perguntas := TList<TProblemaInicializacao>.Create;
  Avisos := TList<TAvisoInicializacao>.Create;
  RespostaPadrao := auSair;
  ConfigurarResponde := True;
end;

destructor TInteracaoFalsa.Destroy;
begin
  Avisos.Free;
  Perguntas.Free;
  Respostas.Free;
  inherited;
end;

function TInteracaoFalsa.ConfigurarBanco(const ASugestao: TConfigBanco; APrimeiraVez: Boolean;
  out AConfig: TConfigBanco): Boolean;
begin
  Inc(ConfigurarChamadas);
  UltimaFoiPrimeiraVez := APrimeiraVez;
  AConfig := ConfigParaDevolver;
  Result := ConfigurarResponde;
end;

function TInteracaoFalsa.PerguntarAcao(AProblema: TProblemaInicializacao;
  const AConfig: TConfigBanco; const ADetalhe: string;
  const APermitidas: TAcoesUsuario): TAcaoUsuario;
begin
  Perguntas.Add(AProblema);
  UltimasPermitidas := APermitidas;
  if Respostas.Count > 0 then
    Result := Respostas.Dequeue
  else
    Result := RespostaPadrao;
end;

procedure TInteracaoFalsa.Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
begin
  Avisos.Add(AAviso);
end;

{ TTestesInicializador }

function TTestesInicializador.ConfigBoa: TConfigBanco;
begin
  Result := Default(TConfigBanco);
  Result.Database := 'C:\dados\PEDIDOS.FDB';
  Result.Username := 'SYSDBA';
  Result.Password := 'segredo';
  Result.Server := 'localhost';
  Result.Port := 3050;
  Result.ClientLibrary := 'C:\bin\Win32\fbclient.dll';
end;

procedure TTestesInicializador.Setup;
begin
  FConfigRepo := TConfigRepositorioFalso.Create;
  FInspetor := TInspetorFalso.Create;
  FCriador := TCriadorFalso.Create;
  FRegistro := TRegistroFalso.Create;
  FInteracao := TInteracaoFalsa.Create;
  FRepoIntf := FConfigRepo;
  FInspetorIntf := FInspetor;
  FCriadorIntf := FCriador;
  FRegistroIntf := FRegistro;
  FInteracaoIntf := FInteracao;

  FConfigRepo.Resultado := rcOk;
  FConfigRepo.Config := ConfigBoa;
  FInteracao.ConfigParaDevolver := ConfigBoa;
  FInicializador := TInicializadorSistema.Create(FRepoIntf, FInspetorIntf, FCriadorIntf,
    FRegistroIntf, FInteracaoIntf);
end;

procedure TTestesInicializador.TearDown;
begin
  FInicializador.Free;
  FInteracaoIntf := nil;
  FRegistroIntf := nil;
  FCriadorIntf := nil;
  FInspetorIntf := nil;
  FRepoIntf := nil;
end;

function TTestesInicializador.Executar(out AConfig: TConfigBanco): Boolean;
begin
  Result := FInicializador.Executar(AConfig);
end;

procedure TTestesInicializador.ProximoDiagnostico(AEstado: TEstadoBanco);
begin
  FInspetor.Fila.Enqueue(TDiagnosticoBanco.Criar(AEstado, 'detalhe técnico'));
end;

procedure TTestesInicializador.PrimeiraExecucaoCanceladaNaoGravaNada;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcAusente;
  FInteracao.ConfigurarResponde := False;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(0, FConfigRepo.Salvos.Count);
  Assert.AreEqual(0, FInspetor.Chamadas);
end;

procedure TTestesInicializador.PrimeiraExecucaoGravaAConfiguracaoEContinua;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcAusente;
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(1, FConfigRepo.Salvos.Count);
  Assert.AreEqual(ConfigBoa.Database, FConfigRepo.Salvos[0].Database);
  Assert.AreEqual(ConfigBoa.Database, Config.Database);
end;

procedure TTestesInicializador.PrimeiraExecucaoAbreAConfiguracaoComoPrimeiraVez;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcAusente;
  Executar(Config);
  Assert.IsTrue(FInteracao.UltimaFoiPrimeiraVez);
  Assert.AreEqual(0, FInteracao.Perguntas.Count, 'Na primeira execução não há o que perguntar além da configuração');
end;

procedure TTestesInicializador.ConfigCorrompidaPerguntaEPodeSair;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcInvalida;
  FConfigRepo.Motivo := 'Port: precisa ser um número';
  FInteracao.RespostaPadrao := auSair;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(Ord(pbConfigInvalida), Ord(FInteracao.Perguntas[0]));
  Assert.AreEqual(0, FConfigRepo.Salvos.Count, 'Nada é sobrescrito sem autorização');
  Assert.AreEqual(0, FConfigRepo.Copias);
end;

procedure TTestesInicializador.ConfigCorrompidaReconfiguraGuardandoCopia;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcInvalida;
  FInteracao.Respostas.Enqueue(auReconfigurar);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(1, FConfigRepo.Copias, 'O arquivo antigo é copiado antes de ser trocado');
  Assert.AreEqual(1, FConfigRepo.Salvos.Count);
  Assert.IsFalse(FInteracao.UltimaFoiPrimeiraVez);
end;

procedure TTestesInicializador.ConfigCorrompidaReconfiguracaoCanceladaEncerra;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcInvalida;
  FInteracao.Respostas.Enqueue(auReconfigurar);
  FInteracao.ConfigurarResponde := False;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(0, FConfigRepo.Salvos.Count);
end;

procedure TTestesInicializador.BancoOkConcluiERegistraOBanco;
var
  Config: TConfigBanco;
begin
  Assert.IsTrue(Executar(Config));
  Assert.IsTrue(FRegistro.JaFoiCriado(ConfigBoa), 'Banco que abriu passa a ser lembrado');
  Assert.AreEqual(0, FInteracao.Perguntas.Count);
  Assert.AreEqual(0, FCriador.BancosCriados);
end;

procedure TTestesInicializador.BancoNuncaCriadoECriadoSemPerguntar;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBancoInexistente);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(1, FCriador.BancosCriados);
  Assert.AreEqual(0, FInteracao.Perguntas.Count, 'Primeira vez: cria sozinho');
  Assert.IsTrue(FRegistro.JaFoiCriado(ConfigBoa));
  Assert.AreEqual(2, FInspetor.Chamadas, 'Confere de novo depois de criar');
end;

procedure TTestesInicializador.BancoNuncaCriadoAvisaQueCriou;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBancoInexistente);
  Executar(Config);
  Assert.AreEqual(1, FInteracao.Avisos.Count);
  Assert.AreEqual(Ord(avBancoCriado), Ord(FInteracao.Avisos[0]));
end;

procedure TTestesInicializador.BancoQueSumiuPerguntaAntesDeCriar;
var
  Config: TConfigBanco;
begin
  FRegistro.Registrar(ConfigBoa); // já foi criado antes neste computador
  ProximoDiagnostico(ebBancoInexistente);
  FInteracao.RespostaPadrao := auSair;
  Executar(Config);
  Assert.AreEqual(1, FInteracao.Perguntas.Count);
  Assert.AreEqual(Ord(pbBancoSumiu), Ord(FInteracao.Perguntas[0]));
  Assert.IsTrue(auCriarBancoNovo in FInteracao.UltimasPermitidas);
  Assert.IsTrue(auReconfigurar in FInteracao.UltimasPermitidas);
end;

procedure TTestesInicializador.BancoQueSumiuEPessoaEscolheSairNaoCriaNada;
var
  Config: TConfigBanco;
begin
  FRegistro.Registrar(ConfigBoa);
  ProximoDiagnostico(ebBancoInexistente);
  FInteracao.Respostas.Enqueue(auSair);
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(0, FCriador.BancosCriados);
end;

procedure TTestesInicializador.BancoQueSumiuEPessoaEscolheCriarNovoCria;
var
  Config: TConfigBanco;
begin
  FRegistro.Registrar(ConfigBoa);
  ProximoDiagnostico(ebBancoInexistente);
  FInteracao.Respostas.Enqueue(auCriarBancoNovo);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(1, FCriador.BancosCriados);
end;

procedure TTestesInicializador.BancoQueSumiuEPessoaEscolheReconfigurar;
var
  Config: TConfigBanco;
begin
  FRegistro.Registrar(ConfigBoa);
  ProximoDiagnostico(ebBancoInexistente);
  FInteracao.Respostas.Enqueue(auReconfigurar);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(0, FCriador.BancosCriados);
  Assert.AreEqual(1, FConfigRepo.Salvos.Count);
end;

procedure TTestesInicializador.BancoSemEstruturaPerguntaESoCriaSeConfirmar;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebSemEstrutura);
  FInteracao.Respostas.Enqueue(auCriarEstrutura);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(Ord(pbSemEstrutura), Ord(FInteracao.Perguntas[0]));
  Assert.AreEqual(1, FCriador.EstruturasCriadas);
  Assert.AreEqual(Ord(avEstruturaCriada), Ord(FInteracao.Avisos[0]));
end;

procedure TTestesInicializador.BancoSemEstruturaRecusadoEncerra;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebSemEstrutura);
  FInteracao.Respostas.Enqueue(auSair);
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(0, FCriador.EstruturasCriadas);
end;

procedure TTestesInicializador.EstruturaDesatualizadaAtualizaSozinha;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebEstruturaDesatualizada);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(1, FCriador.EstruturasAtualizadas);
  Assert.AreEqual(0, FInteracao.Perguntas.Count);
  Assert.AreEqual(Ord(avEstruturaAtualizada), Ord(FInteracao.Avisos[0]));
end;

procedure TTestesInicializador.BancoDeOutroSistemaNuncaOfereceCriar;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBancoDeOutroSistema);
  FInteracao.RespostaPadrao := auSair;
  Executar(Config);
  Assert.AreEqual(Ord(pbBancoDeOutroSistema), Ord(FInteracao.Perguntas[0]));
  Assert.IsFalse(auCriarEstrutura in FInteracao.UltimasPermitidas);
  Assert.IsFalse(auCriarBancoNovo in FInteracao.UltimasPermitidas);
  Assert.AreEqual(0, FCriador.EstruturasCriadas);
  Assert.AreEqual(0, FCriador.BancosCriados);
end;

procedure TTestesInicializador.ServidorIndisponivelPermiteTentarDeNovo;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebServidorIndisponivel);
  FInteracao.Respostas.Enqueue(auTentarNovamente);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(2, FInspetor.Chamadas);
  Assert.AreEqual(Ord(pbServidorIndisponivel), Ord(FInteracao.Perguntas[0]));
end;

procedure TTestesInicializador.ServidorIndisponivelNaoOfereceCriarBanco;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebServidorIndisponivel);
  Executar(Config);
  Assert.IsFalse(auCriarBancoNovo in FInteracao.UltimasPermitidas);
  Assert.IsTrue(auTentarNovamente in FInteracao.UltimasPermitidas);
  Assert.AreEqual(0, FCriador.BancosCriados);
end;

procedure TTestesInicializador.CredenciaisInvalidasOferecemReconfigurar;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebCredenciaisInvalidas);
  FInteracao.Respostas.Enqueue(auReconfigurar);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(Ord(pbCredenciaisInvalidas), Ord(FInteracao.Perguntas[0]));
  Assert.AreEqual(1, FConfigRepo.Salvos.Count);
end;

procedure TTestesInicializador.BibliotecaIndisponivelOferecaSoReconfigurarOuSair;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBibliotecaIndisponivel);
  Executar(Config);
  Assert.AreEqual(Ord(pbBibliotecaIndisponivel), Ord(FInteracao.Perguntas[0]));
  Assert.IsTrue(FInteracao.UltimasPermitidas = [auReconfigurar, auSair]);
end;

procedure TTestesInicializador.ErroInesperadoNoDiagnosticoPergunta;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebErroInesperado);
  FInteracao.Respostas.Enqueue(auTentarNovamente);
  Assert.IsTrue(Executar(Config));
  Assert.AreEqual(Ord(pbErroInesperado), Ord(FInteracao.Perguntas[0]));
end;

procedure TTestesInicializador.FalhaAoCriarBancoRegistraEPergunta;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBancoInexistente);
  FCriador.Falhar := True;
  FInteracao.RespostaPadrao := auSair;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(Ord(pbErroInesperado), Ord(FInteracao.Perguntas[0]));
  Assert.IsTrue(auTentarNovamente in FInteracao.UltimasPermitidas);
end;

procedure TTestesInicializador.FalhaAoCriarBancoNaoRegistraOBancoComoCriado;
var
  Config: TConfigBanco;
begin
  ProximoDiagnostico(ebBancoInexistente);
  FCriador.Falhar := True;
  Executar(Config);
  Assert.IsFalse(FRegistro.JaFoiCriado(ConfigBoa));
  Assert.AreEqual(0, FInteracao.Avisos.Count, 'Não avisa "criado" quando falhou');
end;

procedure TTestesInicializador.FalhaAoGravarConfigPergunta;
var
  Config: TConfigBanco;
begin
  FConfigRepo.Resultado := rcAusente;
  FConfigRepo.FalharAoSalvar := True;
  FInteracao.RespostaPadrao := auSair;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(Ord(pbErroInesperado), Ord(FInteracao.Perguntas[0]));
end;

procedure TTestesInicializador.RepetirParaSempreEhInterrompidoPeloLimite;
var
  Config: TConfigBanco;
begin
  FInspetor.Padrao := TDiagnosticoBanco.Criar(ebServidorIndisponivel);
  FInteracao.RespostaPadrao := auTentarNovamente;
  Assert.IsFalse(Executar(Config));
  Assert.AreEqual(MAX_TENTATIVAS_INICIALIZACAO, FInspetor.Chamadas);
end;

procedure TTestesInicializador.SairEmQualquerProblemaEncerraSemTentarMais;
var
  Estado: TEstadoBanco;
  Config: TConfigBanco;
  Antes: Integer;
begin
  for Estado in [ebBancoInexistente, ebSemEstrutura, ebBancoDeOutroSistema, ebServidorIndisponivel,
    ebCredenciaisInvalidas, ebBibliotecaIndisponivel, ebErroInesperado] do
  begin
    // Cada rodada recomeça "limpa": banco já criado antes, para que o inexistente pergunte.
    FRegistro.Registrar(ConfigBoa);
    FInspetor.Fila.Clear;
    ProximoDiagnostico(Estado);
    FInteracao.RespostaPadrao := auSair;
    Antes := FInspetor.Chamadas;
    Assert.IsFalse(Executar(Config), 'Estado: ' + IntToStr(Ord(Estado)));
    Assert.AreEqual(Antes + 1, FInspetor.Chamadas, 'Só um diagnóstico por rodada');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesInicializador);

end.
