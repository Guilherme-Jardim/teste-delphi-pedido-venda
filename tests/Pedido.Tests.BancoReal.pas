unit Pedido.Tests.BancoReal;

{ Criação e diagnóstico do banco contra um Firebird de verdade.
  Usa o servidor, o usuário e a biblioteca do config.ini, mas cada teste
  cria o seu próprio banco em uma pasta temporária e apaga tudo no final.
  Sem config.ini, sem servidor local ou sem permissão, os testes passam
  sem verificar nada (ficam como "ignorados" na leitura do resultado). }

interface

uses
  DUnitX.TestFramework,
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config;

type
  [TestFixture]
  TTestesBancoReal = class
  private
    FBase: TConfigBanco;
    FTemServidor: Boolean;
    FPasta: string;
    FConfig: TConfigBanco;
    procedure ExigirServidor;
    function NovoInspetor: IInspetorBanco;
    function NovoCriador: ICriadorBanco;
    function ContarLinhas(const ATabela: string): Integer;
    procedure Executar(const ASql: string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure BancoInexistenteEDiagnosticadoComoTal;
    [Test]
    procedure CriarBancoNovoCriaOArquivoAEstruturaEACarga;
    [Test]
    procedure CriarBancoNovoCriaAPastaQueNaoExiste;
    [Test]
    procedure CriarBancoNovoNaoSobrescreveBancoExistente;
    [Test]
    procedure BancoCriadoTemOGeneratorEOsIndicesPedidos;
    [Test]
    procedure CriarEstruturaEhIdempotenteENaoDuplicaDados;
    [Test]
    procedure BancoVazioEDiagnosticadoComoSemEstrutura;
    [Test]
    procedure CriarEstruturaEmBancoVazioDeixaTudoOk;
    [Test]
    procedure BancoSemObservacaoEDiagnosticadoComoDesatualizado;
    [Test]
    procedure AtualizarEstruturaAcrescentaObservacaoSemPerderDados;
    [Test]
    procedure BancoDeOutroSistemaNaoEhTocado;
    [Test]
    procedure BancoComAlgumasTabelasFaltandoEComplementado;
    [Test]
    procedure ServidorForaDoArEhReconhecido;
    [Test]
    procedure SenhaErradaEReconhecida;
    [Test]
    procedure BibliotecaInexistenteEReconhecida;
    [Test]
    procedure BibliotecaComBitsDiferentesEReconhecida;
    [Test]
    procedure ArquivoQueNaoEhBancoNaoDerrubaODiagnostico;
    [Test]
    procedure FluxoCompletoDePrimeiraExecucaoCriaTudoESegue;
    [Test]
    procedure BancoApagadoDepoisDeCriadoPerguntaEPodeSerRecriado;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  FireDAC.Comp.Client,
  Pedido.Infra.BancoDados.FireDAC,
  Pedido.Infra.Conexao,
  Pedido.Infra.EsquemaBanco,
  Pedido.Infra.Idioma,
  Pedido.Infra.Inicializador,
  Pedido.Infra.RegistroBanco,
  Pedido.Tests.Inicializador;

procedure TTestesBancoReal.SetupFixture;
var
  Repo: IConfigRepositorio;
  Motivo: string;
begin
  DefinirIdioma(idPortugues, False);
  Repo := TIniConfigRepositorio.Create;
  FTemServidor := (Repo.Carregar(FBase, Motivo) = rcOk) and FBase.EhServidorLocal and
    (Trim(FBase.Server) <> '');
  System.Writeln('[BancoReal] servidor Firebird local disponivel: ' + BoolToStr(FTemServidor, True));
end;

function TTestesBancoReal.NovoInspetor: IInspetorBanco;
begin
  Result := TInspetorBancoFireDAC.Create;
end;

function TTestesBancoReal.NovoCriador: ICriadorBanco;
begin
  Result := TCriadorBancoFireDAC.Create;
end;

procedure TTestesBancoReal.ExigirServidor;
begin
  if not FTemServidor then
    Assert.Pass('Sem servidor Firebird local configurado: teste ignorado.');
end;

procedure TTestesBancoReal.Setup;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'pedido_teste_db_' + TGUID.NewGuid.ToString.Substring(1, 8));
  FConfig := FBase;
  FConfig.Database := TPath.Combine(FPasta, 'TESTE.FDB');
end;

procedure TTestesBancoReal.TearDown;
begin
  try
    if TDirectory.Exists(FPasta) then
      TDirectory.Delete(FPasta, True);
  except
    // Arquivo ainda preso pelo servidor: a pasta temporária é limpa pelo sistema depois.
  end;
end;

function TTestesBancoReal.ContarLinhas(const ATabela: string): Integer;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono);
    Conexao.Connected := True;
    Result := Conexao.ExecSQLScalar('SELECT COUNT(*) FROM ' + ATabela);
  finally
    Dono.Free;
  end;
end;

procedure TTestesBancoReal.Executar(const ASql: string);
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono);
    Conexao.Connected := True;
    Conexao.ExecSQL(ASql);
  finally
    Dono.Free;
  end;
end;

procedure TTestesBancoReal.BancoInexistenteEDiagnosticadoComoTal;
var
  Diagnostico: TDiagnosticoBanco;
begin
  ExigirServidor;
  Diagnostico := NovoInspetor.Diagnosticar(FConfig);
  Assert.AreEqual(Ord(ebBancoInexistente), Ord(Diagnostico.Estado), Diagnostico.Detalhe);
end;

procedure TTestesBancoReal.CriarBancoNovoCriaOArquivoAEstruturaEACarga;
var
  Inspetor: IInspetorBanco;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  Assert.IsTrue(TFile.Exists(FConfig.Database), 'O arquivo .fdb deveria existir');
  Inspetor := NovoInspetor;
  Assert.AreEqual(Ord(ebOk), Ord(Inspetor.Diagnosticar(FConfig).Estado));
  Assert.IsTrue(ContarLinhas('CLIENTE') >= 10);
  Assert.IsTrue(ContarLinhas('PRODUTO') >= 10);
  Assert.AreEqual(0, ContarLinhas('PEDIDO'));
  Assert.AreEqual(0, ContarLinhas('PEDIDO_ITEM'));
end;

procedure TTestesBancoReal.CriarBancoNovoCriaAPastaQueNaoExiste;
begin
  ExigirServidor;
  FConfig.Database := TPath.Combine(TPath.Combine(TPath.Combine(FPasta, 'a'), 'b'), 'TESTE.FDB');
  Assert.IsFalse(TDirectory.Exists(FPasta));
  NovoCriador.CriarBancoNovo(FConfig);
  Assert.IsTrue(TFile.Exists(FConfig.Database));
end;

procedure TTestesBancoReal.CriarBancoNovoNaoSobrescreveBancoExistente;
var
  Antes: Integer;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  Executar('DELETE FROM PRODUTO WHERE CODIGO = 1');
  Antes := ContarLinhas('PRODUTO');
  try
    NovoCriador.CriarBancoNovo(FConfig);
    Assert.Fail('Deveria recusar sobrescrever o banco existente');
  except
    on EBancoNaoCriado do
      ; // esperado
  end;
  Assert.AreEqual(Antes, ContarLinhas('PRODUTO'), 'O banco existente não pode ser tocado');
end;

procedure TTestesBancoReal.BancoCriadoTemOGeneratorEOsIndicesPedidos;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono);
    Conexao.Connected := True;
    Assert.AreEqual(1, Integer(Conexao.ExecSQLScalar(
      'SELECT COUNT(*) FROM RDB$GENERATORS WHERE RDB$GENERATOR_NAME = ''GEN_PEDIDO_NUMERO''')));
    Assert.AreEqual(1, Integer(Conexao.ExecSQLScalar(
      'SELECT COUNT(*) FROM RDB$INDICES WHERE RDB$INDEX_NAME = ''IDX_PEDIDO_CLIENTE''')));
    Assert.AreEqual(1, Integer(Conexao.ExecSQLScalar(
      'SELECT COUNT(*) FROM RDB$INDICES WHERE RDB$INDEX_NAME = ''IDX_PEDIDO_ITEM_PEDIDO''')));
    Assert.AreEqual(1, Integer(Conexao.ExecSQLScalar(
      'SELECT COUNT(*) FROM RDB$INDICES WHERE RDB$INDEX_NAME = ''IDX_PEDIDO_ITEM_PRODUTO''')));
  finally
    Dono.Free;
  end;
end;

procedure TTestesBancoReal.CriarEstruturaEhIdempotenteENaoDuplicaDados;
var
  Clientes, Produtos: Integer;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  Clientes := ContarLinhas('CLIENTE');
  Produtos := ContarLinhas('PRODUTO');
  NovoCriador.CriarEstrutura(FConfig);
  NovoCriador.CriarEstrutura(FConfig);
  Assert.AreEqual(Clientes, ContarLinhas('CLIENTE'));
  Assert.AreEqual(Produtos, ContarLinhas('PRODUTO'));
end;

procedure TTestesBancoReal.BancoVazioEDiagnosticadoComoSemEstrutura;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirServidor;
  TDirectory.CreateDirectory(FPasta);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono, True);
    Conexao.Connected := True; // só cria o arquivo vazio
  finally
    Dono.Free;
  end;
  Assert.AreEqual(Ord(ebSemEstrutura), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
end;

procedure TTestesBancoReal.CriarEstruturaEmBancoVazioDeixaTudoOk;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirServidor;
  TDirectory.CreateDirectory(FPasta);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono, True);
    Conexao.Connected := True;
  finally
    Dono.Free;
  end;
  NovoCriador.CriarEstrutura(FConfig);
  Assert.AreEqual(Ord(ebOk), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
  Assert.IsTrue(ContarLinhas('CLIENTE') >= 10);
end;

procedure TTestesBancoReal.BancoSemObservacaoEDiagnosticadoComoDesatualizado;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  // Simula um banco criado antes de existir o campo Observação.
  Executar('ALTER TABLE PEDIDO DROP OBSERVACAO');
  Assert.AreEqual(Ord(ebEstruturaDesatualizada),
    Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
end;

procedure TTestesBancoReal.AtualizarEstruturaAcrescentaObservacaoSemPerderDados;
begin
  ExigirServidor;
  NovoCriador.CriarBancoNovo(FConfig);
  Executar('INSERT INTO PEDIDO (NUMERO_PEDIDO, CODIGO_CLIENTE, VALOR_TOTAL) VALUES (900, 1, 10)');
  Executar('ALTER TABLE PEDIDO DROP OBSERVACAO');
  NovoCriador.AtualizarEstrutura(FConfig);
  Assert.AreEqual(Ord(ebOk), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
  Assert.AreEqual(1, ContarLinhas('PEDIDO'), 'O pedido existente não pode se perder');
end;

procedure TTestesBancoReal.BancoDeOutroSistemaNaoEhTocado;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirServidor;
  TDirectory.CreateDirectory(FPasta);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono, True);
    Conexao.Connected := True;
    Conexao.ExecSQL('CREATE TABLE FOLHA_PAGAMENTO (ID INTEGER NOT NULL PRIMARY KEY, SALARIO NUMERIC(15,2))');
  finally
    Dono.Free;
  end;
  Assert.AreEqual(Ord(ebBancoDeOutroSistema), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
end;

procedure TTestesBancoReal.BancoComAlgumasTabelasFaltandoEComplementado;
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirServidor;
  TDirectory.CreateDirectory(FPasta);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(FConfig, Dono, True);
    Conexao.Connected := True;
    Conexao.ExecSQL(TEsquemaBanco.ComandoDaTabela('CLIENTE')); // só uma tabela existe
    Conexao.ExecSQL('INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (77, ''Preservado'', ''Caxias'', ''RS'')');
  finally
    Dono.Free;
  end;
  Assert.AreEqual(Ord(ebSemEstrutura), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
  NovoCriador.CriarEstrutura(FConfig);
  Assert.AreEqual(Ord(ebOk), Ord(NovoInspetor.Diagnosticar(FConfig).Estado));
  // O cliente que já existia continua lá e a carga de CLIENTE não foi duplicada por cima.
  Assert.AreEqual(1, ContarLinhas('CLIENTE'));
  Assert.IsTrue(ContarLinhas('PRODUTO') >= 10);
end;

procedure TTestesBancoReal.ServidorForaDoArEhReconhecido;
var
  Config: TConfigBanco;
begin
  ExigirServidor;
  Config := FConfig;
  Config.Port := 1; // ninguém escuta aqui
  Assert.AreEqual(Ord(ebServidorIndisponivel), Ord(NovoInspetor.Diagnosticar(Config).Estado));
end;

procedure TTestesBancoReal.SenhaErradaEReconhecida;
var
  Config: TConfigBanco;
begin
  ExigirServidor;
  Config := FConfig;
  Config.Password := 'senha-que-nao-existe-' + TGUID.NewGuid.ToString;
  Assert.AreEqual(Ord(ebCredenciaisInvalidas), Ord(NovoInspetor.Diagnosticar(Config).Estado));
end;

procedure TTestesBancoReal.BibliotecaInexistenteEReconhecida;
var
  Config: TConfigBanco;
begin
  Config := FBase;
  Config.ClientLibrary := TPath.Combine(TPath.GetTempPath, 'nao_existe_' + TGUID.NewGuid.ToString + '.dll');
  Config.Database := 'C:\x\y.fdb';
  Assert.AreEqual(Ord(ebBibliotecaIndisponivel), Ord(NovoInspetor.Diagnosticar(Config).Estado));
end;

procedure TTestesBancoReal.BibliotecaComBitsDiferentesEReconhecida;
var
  Config: TConfigBanco;
  Bytes: TBytes;
  Maquina: Word;
begin
  // DLL "falsa" com cabeçalho PE do tipo contrário ao do aplicativo.
  TDirectory.CreateDirectory(FPasta);
  SetLength(Bytes, 256);
  FillChar(Bytes[0], Length(Bytes), 0);
  Bytes[0] := Ord('M');
  Bytes[1] := Ord('Z');
  Bytes[$3C] := $80;
  Bytes[$80] := Ord('P');
  Bytes[$81] := Ord('E');
  {$IFDEF WIN64}
  Maquina := $014C; // 32 bits
  {$ELSE}
  Maquina := $8664; // 64 bits
  {$ENDIF}
  Bytes[$84] := Lo(Maquina);
  Bytes[$85] := Hi(Maquina);
  Config := FBase;
  Config.ClientLibrary := TPath.Combine(FPasta, 'fbclient.dll');
  Config.Database := 'C:\x\y.fdb';
  TFile.WriteAllBytes(Config.ClientLibrary, Bytes);
  Assert.AreEqual(Ord(ebBibliotecaIndisponivel), Ord(NovoInspetor.Diagnosticar(Config).Estado));
end;

procedure TTestesBancoReal.ArquivoQueNaoEhBancoNaoDerrubaODiagnostico;
var
  Diagnostico: TDiagnosticoBanco;
begin
  ExigirServidor;
  TDirectory.CreateDirectory(FPasta);
  TFile.WriteAllText(FConfig.Database, 'isto não é um banco Firebird');
  Diagnostico := NovoInspetor.Diagnosticar(FConfig);
  Assert.AreNotEqual(Ord(ebOk), Ord(Diagnostico.Estado));
  Assert.IsNotEmpty(Diagnostico.Detalhe);
end;

procedure TTestesBancoReal.FluxoCompletoDePrimeiraExecucaoCriaTudoESegue;
var
  Repo: TConfigRepositorioFalso;
  Interacao: TInteracaoFalsa;
  Inicializador: TInicializadorSistema;
  Config: TConfigBanco;
  RepoIntf: IConfigRepositorio;
  InteracaoIntf: IInteracaoInicializacao;
begin
  ExigirServidor;
  Repo := TConfigRepositorioFalso.Create;
  RepoIntf := Repo;
  Repo.Resultado := rcOk;
  Repo.Config := FConfig;
  Interacao := TInteracaoFalsa.Create;
  InteracaoIntf := Interacao;
  Inicializador := TInicializadorSistema.Create(RepoIntf, TInspetorBancoFireDAC.Create,
    TCriadorBancoFireDAC.Create, TRegistroBancoArquivo.Create(TPath.Combine(FPasta + '_reg', 'bancos.ini')),
    InteracaoIntf);
  try
    Assert.IsTrue(Inicializador.Executar(Config));
    Assert.IsTrue(TFile.Exists(FConfig.Database));
    Assert.AreEqual(0, Interacao.Perguntas.Count, 'Primeira vez: nada de perguntas');
    Assert.AreEqual(Ord(avBancoCriado), Ord(Interacao.Avisos[0]));
  finally
    Inicializador.Free;
    if TDirectory.Exists(FPasta + '_reg') then
      TDirectory.Delete(FPasta + '_reg', True);
  end;
end;

procedure TTestesBancoReal.BancoApagadoDepoisDeCriadoPerguntaEPodeSerRecriado;
var
  Repo: TConfigRepositorioFalso;
  Interacao: TInteracaoFalsa;
  Inicializador: TInicializadorSistema;
  Config: TConfigBanco;
  RepoIntf: IConfigRepositorio;
  InteracaoIntf: IInteracaoInicializacao;
  Registro: IRegistroBanco;
begin
  ExigirServidor;
  Repo := TConfigRepositorioFalso.Create;
  RepoIntf := Repo;
  Repo.Resultado := rcOk;
  Repo.Config := FConfig;
  Interacao := TInteracaoFalsa.Create;
  InteracaoIntf := Interacao;
  Registro := TRegistroBancoArquivo.Create(TPath.Combine(FPasta + '_reg', 'bancos.ini'));
  Inicializador := TInicializadorSistema.Create(RepoIntf, TInspetorBancoFireDAC.Create,
    TCriadorBancoFireDAC.Create, Registro, InteracaoIntf);
  try
    Assert.IsTrue(Inicializador.Executar(Config)); // primeira vez: cria e registra
    TFile.Delete(FConfig.Database);                // alguém apaga o arquivo

    Interacao.Respostas.Enqueue(auCriarBancoNovo);
    Assert.IsTrue(Inicializador.Executar(Config));
    Assert.AreEqual(Ord(pbBancoSumiu), Ord(Interacao.Perguntas[0]));
    Assert.IsTrue(TFile.Exists(FConfig.Database), 'O banco novo deveria ter sido criado');
    Assert.IsTrue(ContarLinhas('CLIENTE') >= 10);
  finally
    Inicializador.Free;
    if TDirectory.Exists(FPasta + '_reg') then
      TDirectory.Delete(FPasta + '_reg', True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesBancoReal);

end.
