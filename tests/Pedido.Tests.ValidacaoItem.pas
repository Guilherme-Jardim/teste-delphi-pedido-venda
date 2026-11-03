unit Pedido.Tests.ValidacaoItem;

{ Regras de validação do item de pedido (sem banco de dados). }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesValidacaoItem = class
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure ItemValidoNaoGeraErro;
    [Test]
    procedure CodigoDeProdutoZeroEInvalido;
    [Test]
    procedure QuantidadeNegativaEInvalida;
    [Test]
    procedure QuantidadeAcimaDoLimiteEInvalida;
    [Test]
    procedure QuantidadeNoLimiteEValida;
    [Test]
    procedure ValorAcimaDoLimiteEInvalido;
    [Test]
    procedure ValorZeroEPermitido;
    [Test]
    procedure MensagemSegueOIdiomaEscolhido;
    [Test]
    procedure ClonarCopiaTodosOsCampos;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Domain.Erros,
  Pedido.Domain.PedidoItem,
  Pedido.Infra.Idioma,
  Pedido.Presentation.TradutorErros;

procedure TTestesValidacaoItem.Setup;
begin
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesValidacaoItem.ItemValidoNaoGeraErro;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Cemento', 2, 39.9).Free;
    end);
end;

procedure TTestesValidacaoItem.CodigoDeProdutoZeroEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Criar(0, 'Cemento', 1, 10).Free;
    end, EDominioErro);
end;

procedure TTestesValidacaoItem.QuantidadeNegativaEInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Cemento', -1, 10).Free;
    end, EDominioErro);
end;

procedure TTestesValidacaoItem.QuantidadeAcimaDoLimiteEInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Cemento', 100000, 10).Free;
    end, EDominioErro);
end;

procedure TTestesValidacaoItem.QuantidadeNoLimiteEValida;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Cemento', 99999.999, 1).Free;
    end);
end;

procedure TTestesValidacaoItem.ValorAcimaDoLimiteEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Cemento', 1, 10000000).Free;
    end, EDominioErro);
end;

procedure TTestesValidacaoItem.ValorZeroEPermitido;
begin
  // Brinde ou bonificação: valor zero é aceito.
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItem.Criar(1, 'Brinde', 1, 0).Free;
    end);
end;

procedure TTestesValidacaoItem.MensagemSegueOIdiomaEscolhido;
var
  MensagemEs, MensagemPt: string;
begin
  DefinirIdioma(idEspanhol, False);
  try
    TPedidoItem.Criar(1, 'X', 0, 1).Free;
  except
    on E: EDominioErro do
      MensagemEs := MensagemDoErro(E);
  end;

  DefinirIdioma(idPortugues, False);
  try
    TPedidoItem.Criar(1, 'X', 0, 1).Free;
  except
    on E: EDominioErro do
      MensagemPt := MensagemDoErro(E);
  end;

  Assert.AreNotEqual(MensagemEs, MensagemPt);
  Assert.Contains(MensagemEs, 'cantidad');
  Assert.Contains(MensagemPt, 'quantidade');
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesValidacaoItem.ClonarCopiaTodosOsCampos;
var
  Original, Copia: TPedidoItem;
begin
  Original := TPedidoItem.Criar(7, 'Arena', 3, 8.5);
  try
    Copia := Original.Clonar;
    try
      Assert.AreEqual(Original.CodigoProduto, Copia.CodigoProduto);
      Assert.AreEqual(Original.Descricao, Copia.Descricao);
      Assert.AreEqual(Original.Quantidade.Valor, Copia.Quantidade.Valor);
      Assert.AreEqual(Original.VlrUnitario.Valor, Copia.VlrUnitario.Valor);
      Assert.AreNotSame(Original, Copia);
    finally
      Copia.Free;
    end;
  finally
    Original.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesValidacaoItem);

end.
