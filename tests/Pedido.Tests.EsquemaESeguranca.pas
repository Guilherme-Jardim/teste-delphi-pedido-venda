unit Pedido.Tests.EsquemaESeguranca;

{ Duas proteções contra "deriva" do projeto:
  1) o esquema embutido no executável continua igual ao db/db.sql;
  2) os DAOs continuam sem concatenar texto em SQL (injeção de SQL).
  Também confere o registro dos bancos já criados. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesEsquema = class
  private
    function ComandosDoDbSql: TArray<string>;
    function Normalizar(const ATexto: string): string;
  public
    [Test]
    procedure EsquemaEmbutidoEIgualAoDbSql;
    [Test]
    procedure TemAsQuatroTabelasDoTeste;
    [Test]
    procedure CargaInicialTemDezOuMaisRegistrosEmCadaCadastro;
    [Test]
    procedure PedidoTemObservacaoEOsIndicesPedidos;
    [Test]
    procedure PedidoItemTemIdentityEChavesEstrangeiras;
    [Test]
    procedure NenhumComandoTemPontoEVirgula;
    [Test]
    procedure TabelaDesconhecidaLevantaErro;
  end;

  [TestFixture]
  TTestesSeguranca = class
  private
    function ArquivosDoDAO: TArray<string>;
    function LerArquivo(const ACaminho: string): string;
  public
    [Test]
    procedure DAOsTemArquivosParaVarrer;
    [Test]
    procedure DAOsNaoMontamSqlComTextoVariavel;
    [Test]
    procedure TodaQueryNasceDeUmaConstanteSql;
    [Test]
    procedure ConstantesSqlSaoSoLiteraisDeTexto;
    [Test]
    procedure ValoresDeTelaSoChegamComoParametro;
    [Test]
    procedure SenhaNuncaVaiParaOLog;
  end;

  [TestFixture]
  TTestesRegistroBanco = class
  private
    FPasta: string;
    FCaminho: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure BancoNuncaRegistradoNaoFoiCriado;
    [Test]
    procedure BancoRegistradoPassaAFoiCriado;
    [Test]
    procedure RegistroSobreviveEntreExecucoes;
    [Test]
    procedure BancoDiferenteNaoEhConfundido;
    [Test]
    procedure MaiusculasNoCaminhoNaoImportam;
    [Test]
    procedure RegistroIlegivelContaComoNaoCriado;
    [Test]
    procedure RegistroNaoGuardaSenhaNemCaminho;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils,
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config,
  Pedido.Infra.EsquemaBanco,
  Pedido.Infra.RegistroBanco;

function ProcurarArquivo(const ARelativo: string): string;
var
  Pasta: string;
  Nivel: Integer;
begin
  Pasta := ExtractFilePath(ParamStr(0));
  for Nivel := 0 to 6 do
  begin
    Result := TPath.Combine(Pasta, ARelativo);
    if TFile.Exists(Result) or TDirectory.Exists(Result) then
      Exit;
    Pasta := ExtractFilePath(ExcludeTrailingPathDelimiter(Pasta));
  end;
  Result := '';
end;

{ TTestesEsquema }

function TTestesEsquema.Normalizar(const ATexto: string): string;
begin
  Result := UpperCase(TRegEx.Replace(Trim(ATexto), '\s+', ' '));
end;

function TTestesEsquema.ComandosDoDbSql: TArray<string>;
var
  Caminho, Texto, Parte: string;
  Lista: TArray<string>;
begin
  Caminho := ProcurarArquivo('db\db.sql');
  Assert.IsNotEmpty(Caminho, 'db\db.sql não encontrado');
  Texto := TFile.ReadAllText(Caminho, TEncoding.UTF8);
  Texto := TRegEx.Replace(Texto, '/\*.*?\*/', '', [roSingleLine]);
  Texto := TRegEx.Replace(Texto, '--[^\r\n]*', '');
  Result := [];
  Lista := Texto.Split([';']);
  for Parte in Lista do
    if (Trim(Parte) <> '') and not Normalizar(Parte).StartsWith('SET SQL DIALECT') and
       (Normalizar(Parte) <> 'COMMIT') then
      Result := Result + [Normalizar(Parte)];
end;

procedure TTestesEsquema.EsquemaEmbutidoEIgualAoDbSql;
var
  DoArquivo, DoCodigo: TArray<string>;
  I: Integer;
begin
  DoArquivo := ComandosDoDbSql;
  DoCodigo := TEsquemaBanco.ScriptCompleto;
  Assert.AreEqual(Length(DoArquivo), Length(DoCodigo), 'Quantidade de comandos diferente entre db.sql e o esquema embutido');
  for I := 0 to High(DoArquivo) do
    Assert.AreEqual(DoArquivo[I], Normalizar(DoCodigo[I]), 'Comando ' + IntToStr(I + 1) + ' diferente');
end;

procedure TTestesEsquema.TemAsQuatroTabelasDoTeste;
begin
  Assert.AreEqual(4, Length(TEsquemaBanco.Tabelas));
  Assert.AreEqual('CLIENTE', TEsquemaBanco.Tabelas[0]);
  Assert.AreEqual('PRODUTO', TEsquemaBanco.Tabelas[1]);
  Assert.AreEqual('PEDIDO', TEsquemaBanco.Tabelas[2]);
  Assert.AreEqual('PEDIDO_ITEM', TEsquemaBanco.Tabelas[3]);
end;

procedure TTestesEsquema.CargaInicialTemDezOuMaisRegistrosEmCadaCadastro;
begin
  Assert.IsTrue(Length(TEsquemaBanco.CargaInicial('CLIENTE')) >= 10);
  Assert.IsTrue(Length(TEsquemaBanco.CargaInicial('PRODUTO')) >= 10);
  Assert.AreEqual(0, Length(TEsquemaBanco.CargaInicial('PEDIDO')));
end;

procedure TTestesEsquema.PedidoTemObservacaoEOsIndicesPedidos;
var
  Ddl: string;
begin
  Ddl := Normalizar(TEsquemaBanco.ComandoDaTabela('PEDIDO'));
  Assert.Contains(Ddl, 'OBSERVACAO');
  Assert.Contains(Ddl, 'NUMERO_PEDIDO');
  Assert.Contains(Ddl, 'USING INDEX IDX_PEDIDO_CLIENTE');
  Assert.Contains(Normalizar(TEsquemaBanco.ComandoDaTabela('PEDIDO_ITEM')), 'USING INDEX IDX_PEDIDO_ITEM_PEDIDO');
  Assert.Contains(Normalizar(TEsquemaBanco.ComandoDaTabela('PEDIDO_ITEM')), 'USING INDEX IDX_PEDIDO_ITEM_PRODUTO');
end;

procedure TTestesEsquema.PedidoItemTemIdentityEChavesEstrangeiras;
var
  Ddl: string;
begin
  Ddl := Normalizar(TEsquemaBanco.ComandoDaTabela('PEDIDO_ITEM'));
  Assert.Contains(Ddl, 'GENERATED BY DEFAULT AS IDENTITY');
  Assert.Contains(Ddl, 'FOREIGN KEY (NUMERO_PEDIDO) REFERENCES PEDIDO');
  Assert.Contains(Ddl, 'FOREIGN KEY (CODIGO_PRODUTO) REFERENCES PRODUTO');
  Assert.Contains(Normalizar(TEsquemaBanco.ComandoDoGenerator), 'GEN_PEDIDO_NUMERO');
end;

procedure TTestesEsquema.NenhumComandoTemPontoEVirgula;
var
  Comando: string;
begin
  // Cada comando é executado sozinho: um ";" no meio seria sinal de comando emendado.
  for Comando in TEsquemaBanco.ScriptCompleto do
    Assert.IsFalse(Comando.Contains(';'), Comando);
end;

procedure TTestesEsquema.TabelaDesconhecidaLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      TEsquemaBanco.ComandoDaTabela('USUARIO');
    end, EArgumentException);
end;

{ TTestesSeguranca }

function TTestesSeguranca.LerArquivo(const ACaminho: string): string;
begin
  Result := TFile.ReadAllText(ACaminho, TEncoding.UTF8);
end;

function TTestesSeguranca.ArquivosDoDAO: TArray<string>;
var
  Pasta: string;
begin
  Pasta := ProcurarArquivo('src\DAO');
  Assert.IsNotEmpty(Pasta, 'Pasta src\DAO não encontrada');
  Result := TDirectory.GetFiles(Pasta, '*.pas');
end;

procedure TTestesSeguranca.DAOsTemArquivosParaVarrer;
begin
  Assert.IsTrue(Length(ArquivosDoDAO) >= 5);
end;

procedure TTestesSeguranca.DAOsNaoMontamSqlComTextoVariavel;
var
  Arquivo, Texto: string;
begin
  for Arquivo in ArquivosDoDAO do
  begin
    Texto := LerArquivo(Arquivo);
    Assert.IsFalse(TRegEx.IsMatch(Texto, '\.SQL\.(Add|Text)\s*(\(|:=)', [roIgnoreCase]) and
      not Arquivo.EndsWith('Pedido.DAO.Base.pas'), 'SQL montado fora da base em ' + Arquivo);
    Assert.IsFalse(TRegEx.IsMatch(Texto, 'Format\s*\(\s*''\s*(SELECT|INSERT|UPDATE|DELETE)', [roIgnoreCase]),
      'Format com SQL em ' + Arquivo);
    Assert.IsFalse(TRegEx.IsMatch(Texto, '(SELECT|INSERT|UPDATE|DELETE)[^'';]*''\s*\+\s*[A-Za-z_]+\s*\+', [roIgnoreCase]) and
      TRegEx.IsMatch(Texto, '\+\s*(Query|Edit|Texto|Valor|Codigo|Nome)\w*\.', [roIgnoreCase]),
      'Concatenação suspeita em ' + Arquivo);
  end;
end;

procedure TTestesSeguranca.TodaQueryNasceDeUmaConstanteSql;
var
  Arquivo, Texto: string;
  Combinacao: TMatch;
begin
  for Arquivo in ArquivosDoDAO do
  begin
    if Arquivo.EndsWith('Pedido.DAO.Base.pas') then
      Continue;
    Texto := LerArquivo(Arquivo);
    for Combinacao in TRegEx.Matches(Texto, 'NovaQuery\(([^)]*)\)') do
      Assert.IsTrue(TRegEx.IsMatch(Combinacao.Groups[1].Value, '^SQL_[A-Z_]+$'),
        'NovaQuery com argumento que não é constante SQL_*: ' + Combinacao.Groups[1].Value + ' em ' + Arquivo);
  end;
end;

procedure TTestesSeguranca.ConstantesSqlSaoSoLiteraisDeTexto;
var
  Arquivo, Texto, Bloco, Linha: string;
  Combinacao: TMatch;
begin
  for Arquivo in ArquivosDoDAO do
  begin
    Texto := LerArquivo(Arquivo);
    // Cada "SQL_XXX = ... ;" deve conter só literais entre aspas unidos por "+".
    for Combinacao in TRegEx.Matches(Texto, 'SQL_[A-Z_]+\s*=\s*([^;]*);') do
    begin
      Bloco := Combinacao.Groups[1].Value;
      for Linha in Bloco.Split([#10]) do
        if Trim(Linha) <> '' then
          Assert.IsTrue(TRegEx.IsMatch(Trim(Linha), '^''.*''(\s*\+)?$'),
            'Constante SQL com algo que não é literal: ' + Trim(Linha) + ' em ' + Arquivo);
    end;
  end;
end;

procedure TTestesSeguranca.ValoresDeTelaSoChegamComoParametro;
var
  Arquivo, Texto: string;
begin
  // Todo parâmetro SQL (":NOME") é preenchido com ParamByName: nunca por texto.
  for Arquivo in ArquivosDoDAO do
  begin
    Texto := LerArquivo(Arquivo);
    if TRegEx.IsMatch(Texto, ':[A-Z_]+', []) then
      Assert.IsTrue(Texto.Contains('ParamByName('), 'Parâmetros declarados mas não usados em ' + Arquivo);
  end;
end;

procedure TTestesSeguranca.SenhaNuncaVaiParaOLog;
var
  Caminho, Texto: string;
begin
  // O log só recebe a mensagem da exceção; o código-fonte do log não pode citar Password.
  Caminho := ProcurarArquivo('src\Infra\Pedido.Infra.Log.pas');
  Assert.IsNotEmpty(Caminho);
  Texto := LerArquivo(Caminho);
  Assert.IsFalse(TRegEx.IsMatch(Texto, 'password|senha', [roIgnoreCase]) and
    TRegEx.IsMatch(Texto, 'AppendAllText\([^)]*(Password|Senha)', [roIgnoreCase]));
end;

{ TTestesRegistroBanco }

procedure TTestesRegistroBanco.Setup;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'pedido_teste_reg_' + TGUID.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FPasta);
  FCaminho := TPath.Combine(FPasta, 'bancos.ini');
end;

procedure TTestesRegistroBanco.TearDown;
begin
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

procedure TTestesRegistroBanco.BancoNuncaRegistradoNaoFoiCriado;
var
  Registro: IRegistroBanco;
  Config: TConfigBanco;
begin
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  Config := TConfigPadrao.Sugerir(FCaminho);
  Assert.IsFalse(Registro.JaFoiCriado(Config));
end;

procedure TTestesRegistroBanco.BancoRegistradoPassaAFoiCriado;
var
  Registro: IRegistroBanco;
  Config: TConfigBanco;
begin
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  Config := TConfigPadrao.Sugerir(FCaminho);
  Registro.Registrar(Config);
  Assert.IsTrue(Registro.JaFoiCriado(Config));
end;

procedure TTestesRegistroBanco.RegistroSobreviveEntreExecucoes;
var
  Config: TConfigBanco;
  Primeira, Segunda: IRegistroBanco;
begin
  Config := TConfigPadrao.Sugerir(FCaminho);
  Primeira := TRegistroBancoArquivo.Create(FCaminho);
  Primeira.Registrar(Config);
  Primeira := nil;
  Segunda := TRegistroBancoArquivo.Create(FCaminho);
  Assert.IsTrue(Segunda.JaFoiCriado(Config));
end;

procedure TTestesRegistroBanco.BancoDiferenteNaoEhConfundido;
var
  Registro: IRegistroBanco;
  A, B: TConfigBanco;
begin
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  A := TConfigPadrao.Sugerir(FCaminho);
  B := A;
  B.Database := 'D:\outro\banco.fdb';
  Registro.Registrar(A);
  Assert.IsTrue(Registro.JaFoiCriado(A));
  Assert.IsFalse(Registro.JaFoiCriado(B));
  B := A;
  B.Port := 3051;
  Assert.IsFalse(Registro.JaFoiCriado(B));
end;

procedure TTestesRegistroBanco.MaiusculasNoCaminhoNaoImportam;
var
  Registro: IRegistroBanco;
  A, B: TConfigBanco;
begin
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  A := TConfigPadrao.Sugerir(FCaminho);
  A.Database := 'C:\Dados\PEDIDOS.FDB';
  B := A;
  B.Database := 'c:\dados\pedidos.fdb';
  Registro.Registrar(A);
  Assert.IsTrue(Registro.JaFoiCriado(B));
end;

procedure TTestesRegistroBanco.RegistroIlegivelContaComoNaoCriado;
var
  Registro: IRegistroBanco;
  Config: TConfigBanco;
  Lixo: TBytes;
  I: Integer;
begin
  SetLength(Lixo, 256);
  for I := 0 to High(Lixo) do
    Lixo[I] := Byte(I * 7);
  TFile.WriteAllBytes(FCaminho, Lixo);
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  Config := TConfigPadrao.Sugerir(FCaminho);
  Assert.IsFalse(Registro.JaFoiCriado(Config));
end;

procedure TTestesRegistroBanco.RegistroNaoGuardaSenhaNemCaminho;
var
  Registro: IRegistroBanco;
  Config: TConfigBanco;
  Conteudo: string;
begin
  Registro := TRegistroBancoArquivo.Create(FCaminho);
  Config := TConfigPadrao.Sugerir(FCaminho);
  Config.Password := 'SenhaSuperSecreta123';
  Registro.Registrar(Config);
  Conteudo := TFile.ReadAllText(FCaminho, TEncoding.UTF8);
  Assert.IsFalse(Conteudo.Contains('SenhaSuperSecreta123'));
  Assert.IsFalse(Conteudo.ToUpper.Contains('PEDIDOS.FDB'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesEsquema);
  TDUnitX.RegisterTestFixture(TTestesSeguranca);
  TDUnitX.RegisterTestFixture(TTestesRegistroBanco);

end.
