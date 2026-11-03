unit Pedido.Tests.Versao;

{ Versão do aplicativo: montagem, leitura de texto e consulta ao executável. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesVersao = class
  public
    [Test]
    procedure VersaoResumidaTemTresNumeros;
    [Test]
    procedure VersaoCompletaTemQuatroNumeros;
    [TestCase('Tres partes', '1.2.3,1,2,3,0')]
    [TestCase('Quatro partes', '2.0.10.7,2,0,10,7')]
    [TestCase('Com espacos', ' 3.4.5 ,3,4,5,0')]
    procedure TextoValidoEInterpretado(const ATexto: string; AMaior, AMenor, ACorrecao,
      ACompilacao: Integer);
    [TestCase('Duas partes', '1.2')]
    [TestCase('Cinco partes', '1.2.3.4.5')]
    [TestCase('Letras', 'a.b.c')]
    [TestCase('Negativo', '-1.0.0')]
    [TestCase('Acima do limite', '70000.1.1')]
    [TestCase('Vazio', '')]
    procedure TextoInvalidoEhRecusado(const ATexto: string);
    [Test]
    procedure ExecutavelSemVersaoDevolveZeros;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Versao;

procedure TTestesVersao.VersaoResumidaTemTresNumeros;
begin
  Assert.AreEqual('1.1.0', CriarVersao(1, 1, 0, 9).Resumida);
end;

procedure TTestesVersao.VersaoCompletaTemQuatroNumeros;
begin
  Assert.AreEqual('1.1.0.9', CriarVersao(1, 1, 0, 9).Completa);
end;

procedure TTestesVersao.TextoValidoEInterpretado(const ATexto: string; AMaior, AMenor,
  ACorrecao, ACompilacao: Integer);
var
  Versao: TVersaoAplicacao;
begin
  Assert.IsTrue(TentarLerVersao(ATexto, Versao));
  Assert.AreEqual(AMaior, Integer(Versao.Maior));
  Assert.AreEqual(AMenor, Integer(Versao.Menor));
  Assert.AreEqual(ACorrecao, Integer(Versao.Correcao));
  Assert.AreEqual(ACompilacao, Integer(Versao.Compilacao));
end;

procedure TTestesVersao.TextoInvalidoEhRecusado(const ATexto: string);
var
  Versao: TVersaoAplicacao;
begin
  Assert.IsFalse(TentarLerVersao(ATexto, Versao));
  Assert.AreEqual('0.0.0', Versao.Resumida);
end;

procedure TTestesVersao.ExecutavelSemVersaoDevolveZeros;
var
  Versao: TVersaoAplicacao;
begin
  // O executável de teste pode ou não ter informações de versão: o que importa
  // é que a consulta nunca falha e sempre devolve algo no formato esperado.
  Versao := VersaoDoExecutavel;
  Assert.IsTrue(Length(Versao.Resumida) >= 5);
  Assert.AreEqual(3, Length(Versao.Resumida.Split(['.'])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesVersao);

end.
