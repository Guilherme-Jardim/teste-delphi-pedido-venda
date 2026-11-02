unit Pedido.Tests.Totalizacao;

{ Testes das regras de totalização do pedido (sem banco de dados). }

interface

uses
  DUnitX.TestFramework,
  Pedido.Model.Pedido;

type
  [TestFixture]
  TTestesTotalizacao = class
  private
    FPedido: TPedido;
    procedure AdicionarItem(ACodigo: Integer; AQuantidade: Double; AValor: Currency);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure PedidoSemItensTemTotalZero;
    [Test]
    procedure TotalDoItemEQuantidadeVezesValor;
    [Test]
    procedure TotalDoPedidoESomaDosItens;
    [Test]
    procedure ProdutosRepetidosFicamEmLinhasDistintas;
    [Test]
    procedure TotalArredondaEmCentavos;
    [Test]
    procedure ExcluirItemRecalculaOTotal;
    [Test]
    procedure ExcluirTodosOsItensZeraOTotal;
    [Test]
    procedure AtualizarItemRecalculaOTotal;
    [Test]
    procedure QuantidadeZeroEInvalida;
    [Test]
    procedure ValorNegativoEInvalido;
    [Test]
    procedure ExcluirIndiceInvalidoGeraErro;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem;

procedure TTestesTotalizacao.Setup;
begin
  FPedido := TPedido.Create;
end;

procedure TTestesTotalizacao.TearDown;
begin
  FPedido.Free;
end;

procedure TTestesTotalizacao.AdicionarItem(ACodigo: Integer; AQuantidade: Double;
  AValor: Currency);
begin
  FPedido.AdicionarItem(TPedidoItem.Create(ACodigo, 'Produto ' + IntToStr(ACodigo),
    AQuantidade, AValor));
end;

procedure TTestesTotalizacao.PedidoSemItensTemTotalZero;
begin
  Assert.AreEqual(Currency(0), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.TotalDoItemEQuantidadeVezesValor;
begin
  AdicionarItem(1, 3, 10.5);
  Assert.AreEqual(Currency(31.5), FPedido.Itens[0].VlrTotal);
end;

procedure TTestesTotalizacao.TotalDoPedidoESomaDosItens;
begin
  AdicionarItem(1, 2, 39.9);
  AdicionarItem(2, 10, 8.5);
  AdicionarItem(3, 1, 289);
  // 79,80 + 85,00 + 289,00
  Assert.AreEqual(Currency(453.8), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.ProdutosRepetidosFicamEmLinhasDistintas;
begin
  AdicionarItem(1, 1, 39.9);
  AdicionarItem(1, 2, 39.9);
  Assert.AreEqual(2, FPedido.Itens.Count);
  Assert.AreEqual(Currency(119.7), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.TotalArredondaEmCentavos;
begin
  // 3 x 0,333 = 0,999 -> 1,00
  AdicionarItem(1, 3, 0.333);
  Assert.AreEqual(Currency(1), FPedido.Itens[0].VlrTotal);
end;

procedure TTestesTotalizacao.ExcluirItemRecalculaOTotal;
begin
  AdicionarItem(1, 2, 39.9);
  AdicionarItem(2, 10, 8.5);
  AdicionarItem(3, 1, 289);
  Assert.AreEqual(Currency(453.8), FPedido.ValorTotal);

  FPedido.RemoverItem(1);

  Assert.AreEqual(2, FPedido.Itens.Count);
  Assert.AreEqual(Currency(368.8), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.ExcluirTodosOsItensZeraOTotal;
begin
  AdicionarItem(1, 2, 39.9);
  AdicionarItem(2, 1, 8.5);
  FPedido.RemoverItem(0);
  FPedido.RemoverItem(0);
  Assert.AreEqual(Currency(0), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.AtualizarItemRecalculaOTotal;
begin
  AdicionarItem(1, 2, 10);
  AdicionarItem(2, 1, 5);
  FPedido.AtualizarItem(0, TPedidoItem.Create(1, 'Produto 1', 4, 10));
  Assert.AreEqual(Currency(45), FPedido.ValorTotal);
end;

procedure TTestesTotalizacao.QuantidadeZeroEInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Create(1, 'Produto 1', 0, 10).Free;
    end,
    EValidacao);
end;

procedure TTestesTotalizacao.ValorNegativoEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItem.Create(1, 'Produto 1', 1, -1).Free;
    end,
    EValidacao);
end;

procedure TTestesTotalizacao.ExcluirIndiceInvalidoGeraErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FPedido.RemoverItem(3);
    end,
    EValidacao);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesTotalizacao);

end.
