unit Pedido.Tests.Idioma;

{ Troca de idioma: português do Brasil é o padrão e o espanhol é a alternativa. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesIdioma = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure PortuguesEOIdiomaPadrao;
    [Test]
    procedure TrocarParaPortuguesMudaOsTextos;
    [Test]
    procedure VoltarParaEspanholRestauraOsTextos;
    [Test]
    procedure TextosComParametrosSaoFormatados;
    [Test]
    procedure ChaveDesconhecidaDevolveAPropriaChave;
    [Test]
    procedure MensagensDeErroDeNegocioSeguemOIdioma;
    [Test]
    procedure TodasAsTelasTemTextoNosDoisIdiomas;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Idioma,
  Pedido.Model.Excecoes;

procedure TTestesIdioma.Setup;
begin
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesIdioma.TearDown;
begin
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesIdioma.PortuguesEOIdiomaPadrao;
begin
  Assert.AreEqual(Ord(idPortugues), Ord(IdiomaPadrao));
  DefinirIdioma(IdiomaPadrao, False);
  Assert.AreEqual('Gravar pedido', Tr('btn.gravar'));
end;

procedure TTestesIdioma.TrocarParaPortuguesMudaOsTextos;
begin
  DefinirIdioma(idPortugues, False);
  Assert.AreEqual('Gravar pedido', Tr('btn.gravar'));
  Assert.AreEqual('Itens do pedido', Tr('grade.titulo'));
  DefinirIdioma(idEspanhol, False);
  Assert.AreEqual('Guardar pedido', Tr('btn.gravar'));
end;

procedure TTestesIdioma.VoltarParaEspanholRestauraOsTextos;
begin
  DefinirIdioma(idPortugues, False);
  DefinirIdioma(idEspanhol, False);
  Assert.AreEqual('Guardar pedido', Tr('btn.gravar'));
end;

procedure TTestesIdioma.TextosComParametrosSaoFormatados;
begin
  Assert.AreEqual('Pedido n.º 15', Tr('pedido.numero', [15]));
  DefinirIdioma(idPortugues, False);
  Assert.AreEqual('Pedido nº 15', Tr('pedido.numero', [15]));
end;

procedure TTestesIdioma.ChaveDesconhecidaDevolveAPropriaChave;
begin
  Assert.AreEqual('chave.que.nao.existe', Tr('chave.que.nao.existe'));
end;

procedure TTestesIdioma.MensagensDeErroDeNegocioSeguemOIdioma;
var
  Erro: EClienteNaoEncontrado;
begin
  Erro := EClienteNaoEncontrado.Create(99);
  try
    Assert.Contains(Erro.Message, 'No encontramos al cliente 99');
  finally
    Erro.Free;
  end;

  DefinirIdioma(idPortugues, False);
  Erro := EClienteNaoEncontrado.Create(99);
  try
    Assert.Contains(Erro.Message, 'Não encontramos o cliente 99');
  finally
    Erro.Free;
  end;
end;

procedure TTestesIdioma.TodasAsTelasTemTextoNosDoisIdiomas;
const
  CHAVES: array[0..19] of string = (
    'app.titulo', 'app.subtitulo', 'pedido.novo', 'cliente.titulo', 'item.titulo',
    'campo.codigo', 'campo.nome', 'campo.quantidade', 'item.inserir', 'grade.titulo',
    'total.rotulo', 'btn.novo', 'btn.carregar', 'btn.cancelar', 'btn.gravar',
    'hint.sair', 'hint.gravar', 'msg.sem_itens', 'msg.gravado', 'dlg.sim');
var
  Chave, TextoEs, TextoPt: string;
begin
  for Chave in CHAVES do
  begin
    DefinirIdioma(idEspanhol, False);
    TextoEs := Tr(Chave);
    DefinirIdioma(idPortugues, False);
    TextoPt := Tr(Chave);
    Assert.AreNotEqual(Chave, TextoEs, 'Falta o texto em espanhol: ' + Chave);
    Assert.AreNotEqual(Chave, TextoPt, 'Falta o texto em português: ' + Chave);
    Assert.IsNotEmpty(TextoEs);
    Assert.IsNotEmpty(TextoPt);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesIdioma);

end.
