unit Pedido.Tests.Config;

{ config.ini: arquivo ausente, válido, corrompido e com campos inválidos;
  gravação atômica, cópia de segurança e sugestões da primeira execução.
  Tudo em pasta temporária, nunca no config.ini real. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesConfig = class
  private
    FPasta: string;
    FCaminho: string;
    procedure EscreverIni(const ATexto: string);
    function LerIni: string;
    function ConfigValida: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure ArquivoAusenteIndicaPrimeiraExecucao;
    [Test]
    procedure ArquivoValidoELidoComTodosOsCampos;
    [Test]
    procedure BibliotecaRelativaEResolvidaPelaPastaDoIni;
    [Test]
    procedure ArquivoComLixoBinarioEInvalido;
    [Test]
    procedure ArquivoVazioEInvalido;
    [Test]
    procedure ArquivoSemASecaoDatabaseEInvalido;
    [TestCase('Sem Database', 'Database')]
    [TestCase('Sem Username', 'Username')]
    [TestCase('Sem Port', 'Port')]
    [TestCase('Sem ClientLibrary', 'ClientLibrary')]
    procedure CampoObrigatorioAusenteEInvalido(const ACampo: string);
    [TestCase('Porta texto', 'Port=abc')]
    [TestCase('Porta zero', 'Port=0')]
    [TestCase('Porta alta', 'Port=70000')]
    [TestCase('Banco com volta de pasta', 'Database=C:\a\..\b.fdb')]
    [TestCase('Banco com extensao errada', 'Database=C:\a\b.txt')]
    [TestCase('Usuario com espaco', 'Username=a b')]
    [TestCase('Servidor invalido', 'Server=a;b')]
    [TestCase('Biblioteca exe', 'ClientLibrary=x.exe')]
    procedure ValorInvalidoEhRecusadoEMotivoCitaOCampo(const ASubstituicao: string);
    [Test]
    procedure ConfigInvalidaDevolveOQueFoiPossivelLer;
    [Test]
    procedure SalvarELerDevolveOMesmoConteudo;
    [Test]
    procedure SalvarPreservaAcentosNoCaminho;
    [Test]
    procedure SalvarCriaAPastaSeNaoExistir;
    [Test]
    procedure SalvarConfigInvalidaLevantaErroEMantemOArquivoAntigo;
    [Test]
    procedure SalvarNaoDeixaArquivoTemporario;
    [Test]
    procedure SalvarGravaBibliotecaRelativaQuandoEstaNaPastaDoIni;
    [Test]
    procedure GuardarCopiaDuplicaOArquivoAtual;
    [Test]
    procedure GuardarCopiaSemArquivoNaoFazNada;
    [Test]
    procedure SugestaoDaPrimeiraExecucaoEhValida;
    [Test]
    procedure CompletarSubstituiSoOsCamposInvalidos;
    [Test]
    procedure ServidorLocalEReconhecido;
    [Test]
    procedure ChaveDoBancoIgnoraMaiusculas;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Pedido.Infra.Config,
  Pedido.Infra.Idioma,
  Pedido.Infra.Validacao;

procedure TTestesConfig.Setup;
begin
  DefinirIdioma(idPortugues, False);
  FPasta := TPath.Combine(TPath.GetTempPath, 'pedido_teste_cfg_' + TGUID.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FPasta);
  FCaminho := TPath.Combine(FPasta, 'config.ini');
end;

procedure TTestesConfig.TearDown;
begin
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

procedure TTestesConfig.EscreverIni(const ATexto: string);
begin
  TFile.WriteAllText(FCaminho, ATexto, TEncoding.UTF8);
end;

function TTestesConfig.LerIni: string;
begin
  Result := TFile.ReadAllText(FCaminho, TEncoding.UTF8);
end;

function TTestesConfig.ConfigValida: string;
begin
  Result := '[Database]' + sLineBreak +
    'Database=C:\dados\PEDIDOS.FDB' + sLineBreak +
    'Username=SYSDBA' + sLineBreak +
    'Password=segredo' + sLineBreak +
    'Server=localhost' + sLineBreak +
    'Port=3050' + sLineBreak +
    'ClientLibrary=bin\Win32\fbclient.dll' + sLineBreak;
end;

procedure TTestesConfig.ArquivoAusenteIndicaPrimeiraExecucao;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcAusente), Ord(Repo.Carregar(Config, Motivo)));
end;

procedure TTestesConfig.ArquivoValidoELidoComTodosOsCampos;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  EscreverIni(ConfigValida);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcOk), Ord(Repo.Carregar(Config, Motivo)), Motivo);
  Assert.AreEqual('C:\dados\PEDIDOS.FDB', Config.Database);
  Assert.AreEqual('SYSDBA', Config.Username);
  Assert.AreEqual('segredo', Config.Password);
  Assert.AreEqual('localhost', Config.Server);
  Assert.AreEqual(3050, Config.Port);
end;

procedure TTestesConfig.BibliotecaRelativaEResolvidaPelaPastaDoIni;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  EscreverIni(ConfigValida);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Repo.Carregar(Config, Motivo);
  Assert.AreEqual(TPath.GetFullPath(TPath.Combine(FPasta, 'bin\Win32\fbclient.dll')), Config.ClientLibrary);
end;

procedure TTestesConfig.ArquivoComLixoBinarioEInvalido;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
  Lixo: TBytes;
  I: Integer;
begin
  SetLength(Lixo, 512);
  for I := 0 to High(Lixo) do
    Lixo[I] := Byte((I * 37 + 11) mod 256);
  TFile.WriteAllBytes(FCaminho, Lixo);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcInvalida), Ord(Repo.Carregar(Config, Motivo)));
  Assert.IsNotEmpty(Motivo);
end;

procedure TTestesConfig.ArquivoVazioEInvalido;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  EscreverIni('');
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcInvalida), Ord(Repo.Carregar(Config, Motivo)));
end;

procedure TTestesConfig.ArquivoSemASecaoDatabaseEInvalido;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  EscreverIni('[Outra]' + sLineBreak + 'Database=C:\x.fdb' + sLineBreak);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcInvalida), Ord(Repo.Carregar(Config, Motivo)));
  Assert.Contains(Motivo, 'Database');
end;

procedure TTestesConfig.CampoObrigatorioAusenteEInvalido(const ACampo: string);
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo, Texto: string;
  Linha: string;
  Linhas: TStringList;
begin
  Linhas := TStringList.Create;
  try
    Linhas.Text := ConfigValida;
    for Linha in Linhas.ToStringArray do
      if Linha.StartsWith(ACampo + '=') then
      begin
        Linhas.Delete(Linhas.IndexOf(Linha));
        Break;
      end;
    Texto := Linhas.Text;
  finally
    Linhas.Free;
  end;
  EscreverIni(Texto);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcInvalida), Ord(Repo.Carregar(Config, Motivo)));
  Assert.Contains(Motivo, ACampo);
end;

procedure TTestesConfig.ValorInvalidoEhRecusadoEMotivoCitaOCampo(const ASubstituicao: string);
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo, Campo, Texto: string;
  Linhas: TStringList;
  I: Integer;
begin
  Campo := Copy(ASubstituicao, 1, Pos('=', ASubstituicao) - 1);
  Linhas := TStringList.Create;
  try
    Linhas.Text := ConfigValida;
    for I := 0 to Linhas.Count - 1 do
      if Linhas[I].StartsWith(Campo + '=') then
        Linhas[I] := ASubstituicao;
    Texto := Linhas.Text;
  finally
    Linhas.Free;
  end;
  EscreverIni(Texto);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual(Ord(rcInvalida), Ord(Repo.Carregar(Config, Motivo)));
  Assert.Contains(Motivo, Campo);
end;

procedure TTestesConfig.ConfigInvalidaDevolveOQueFoiPossivelLer;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  EscreverIni(StringReplace(ConfigValida, 'Port=3050', 'Port=abc', []));
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Repo.Carregar(Config, Motivo);
  // Os campos bons seguem preenchidos para a tela de configuração aproveitar.
  Assert.AreEqual('SYSDBA', Config.Username);
  Assert.AreEqual('C:\dados\PEDIDOS.FDB', Config.Database);
end;

procedure TTestesConfig.SalvarELerDevolveOMesmoConteudo;
var
  Repo: IConfigRepositorio;
  Entrada, Saida: TConfigBanco;
  Motivo: string;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Entrada := TConfigPadrao.Sugerir(FCaminho);
  Entrada.Password := 'S3nh@ ''forte''; ok';
  Repo.Salvar(Entrada);
  Assert.AreEqual(Ord(rcOk), Ord(Repo.Carregar(Saida, Motivo)), Motivo);
  Assert.AreEqual(Entrada.Database, Saida.Database);
  Assert.AreEqual(Entrada.Username, Saida.Username);
  Assert.AreEqual(Entrada.Password, Saida.Password);
  Assert.AreEqual(Entrada.Server, Saida.Server);
  Assert.AreEqual(Entrada.Port, Saida.Port);
  Assert.AreEqual(Entrada.ClientLibrary, Saida.ClientLibrary);
end;

procedure TTestesConfig.SalvarPreservaAcentosNoCaminho;
var
  Repo: IConfigRepositorio;
  Entrada, Saida: TConfigBanco;
  Motivo: string;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Entrada := TConfigPadrao.Sugerir(FCaminho);
  Entrada.Database := 'C:\Dados do João\Pedidos Açaí.fdb';
  Repo.Salvar(Entrada);
  Repo.Carregar(Saida, Motivo);
  Assert.AreEqual(Entrada.Database, Saida.Database);
end;

procedure TTestesConfig.SalvarCriaAPastaSeNaoExistir;
var
  Repo: IConfigRepositorio;
  Caminho: string;
begin
  Caminho := TPath.Combine(TPath.Combine(FPasta, 'nova\subpasta'), 'config.ini');
  Repo := TIniConfigRepositorio.Create(Caminho);
  Repo.Salvar(TConfigPadrao.Sugerir(Caminho));
  Assert.IsTrue(TFile.Exists(Caminho));
end;

procedure TTestesConfig.SalvarConfigInvalidaLevantaErroEMantemOArquivoAntigo;
var
  Repo: IConfigRepositorio;
  Ruim: TConfigBanco;
  Antes: string;
begin
  EscreverIni(ConfigValida);
  Antes := LerIni;
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Ruim := TConfigPadrao.Sugerir(FCaminho);
  Ruim.Database := 'C:\a.fdb''; DROP TABLE CLIENTE;--';
  Assert.WillRaise(
    procedure
    begin
      Repo.Salvar(Ruim);
    end, EConfigInvalida);
  Assert.AreEqual(Antes, LerIni);
end;

procedure TTestesConfig.SalvarNaoDeixaArquivoTemporario;
var
  Repo: IConfigRepositorio;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Repo.Salvar(TConfigPadrao.Sugerir(FCaminho));
  Assert.IsFalse(TFile.Exists(FCaminho + '.tmp'));
end;

procedure TTestesConfig.SalvarGravaBibliotecaRelativaQuandoEstaNaPastaDoIni;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Config := TConfigPadrao.Sugerir(FCaminho);
  Repo.Salvar(Config);
  Assert.Contains(LerIni, 'ClientLibrary=bin\');
  Assert.IsFalse(LerIni.Contains('ClientLibrary=' + FPasta));
end;

procedure TTestesConfig.GuardarCopiaDuplicaOArquivoAtual;
var
  Repo: IConfigRepositorio;
  Copia: string;
begin
  EscreverIni(ConfigValida);
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Copia := Repo.GuardarCopia;
  Assert.IsNotEmpty(Copia);
  Assert.IsTrue(TFile.Exists(Copia));
  Assert.AreEqual(LerIni, TFile.ReadAllText(Copia, TEncoding.UTF8));
  Assert.IsTrue(TFile.Exists(FCaminho), 'O original continua no lugar');
end;

procedure TTestesConfig.GuardarCopiaSemArquivoNaoFazNada;
var
  Repo: IConfigRepositorio;
begin
  Repo := TIniConfigRepositorio.Create(FCaminho);
  Assert.AreEqual('', Repo.GuardarCopia);
end;

procedure TTestesConfig.SugestaoDaPrimeiraExecucaoEhValida;
var
  Sugestao: TConfigBanco;
  Motivo: string;
begin
  Sugestao := TConfigPadrao.Sugerir(FCaminho);
  Assert.IsTrue(TValidadorEntrada.CaminhoBanco(Sugestao.Database, Motivo), Motivo);
  Assert.IsTrue(TValidadorEntrada.Usuario(Sugestao.Username, Motivo), Motivo);
  Assert.IsTrue(TValidadorEntrada.Servidor(Sugestao.Server, Motivo), Motivo);
  Assert.IsTrue(TValidadorEntrada.Porta(Sugestao.Port, Motivo), Motivo);
  Assert.IsTrue(TValidadorEntrada.BibliotecaCliente(Sugestao.ClientLibrary, Motivo), Motivo);
  Assert.AreEqual(3050, Sugestao.Port);
  // A senha nunca é adivinhada.
  Assert.AreEqual('', Sugestao.Password);
end;

procedure TTestesConfig.CompletarSubstituiSoOsCamposInvalidos;
var
  Lido, Sugestao, Resultado: TConfigBanco;
begin
  Sugestao := TConfigPadrao.Sugerir(FCaminho);
  Lido := Default(TConfigBanco);
  Lido.Username := 'app_pedidos';
  Lido.Password := 'minha';
  Lido.Port := 0;
  Lido.Database := '';
  Resultado := TConfigPadrao.Completar(Lido, Sugestao);
  Assert.AreEqual('app_pedidos', Resultado.Username);
  Assert.AreEqual('minha', Resultado.Password);
  Assert.AreEqual(Sugestao.Port, Resultado.Port);
  Assert.AreEqual(Sugestao.Database, Resultado.Database);
end;

procedure TTestesConfig.ServidorLocalEReconhecido;
var
  Config: TConfigBanco;
begin
  Config := Default(TConfigBanco);
  Config.Server := '';
  Assert.IsTrue(Config.EhServidorLocal);
  Config.Server := 'localhost';
  Assert.IsTrue(Config.EhServidorLocal);
  Config.Server := '127.0.0.1';
  Assert.IsTrue(Config.EhServidorLocal);
  Config.Server := 'srv-remoto.empresa.com';
  Assert.IsFalse(Config.EhServidorLocal);
end;

procedure TTestesConfig.ChaveDoBancoIgnoraMaiusculas;
var
  A, B: TConfigBanco;
begin
  A := Default(TConfigBanco);
  A.Server := 'LocalHost';
  A.Port := 3050;
  A.Database := 'C:\Dados\PEDIDOS.FDB';
  B := A;
  B.Server := 'localhost';
  B.Database := 'c:\dados\pedidos.fdb';
  Assert.AreEqual(A.Chave, B.Chave);
  B.Port := 3051;
  Assert.AreNotEqual(A.Chave, B.Chave);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesConfig);

end.
