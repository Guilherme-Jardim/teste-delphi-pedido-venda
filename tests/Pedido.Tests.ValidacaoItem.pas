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
  Pedido.Infra.Idioma,
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem;

procedure TTestesValidacaoItem.Setup;
begin
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesValidacaoItem.ItemValidoNaoGeraErro;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Cemento', 2, 39.9).Free;
    end);
end;

procedure TTestesValidacaoItem.CodigoDeProdutoZeroEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItemModel.Create(0, 'Cemento', 1, 10).Free;
    end, EValidacao);
end;

procedure TTestesValidacaoItem.QuantidadeNegativaEInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Cemento', -1, 10).Free;
    end, EValidacao);
end;

procedure TTestesValidacaoItem.QuantidadeAcimaDoLimiteEInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Cemento', 100000, 10).Free;
    end, EValidacao);
end;

procedure TTestesValidacaoItem.QuantidadeNoLimiteEValida;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Cemento', 99999.999, 1).Free;
    end);
end;

procedure TTestesValidacaoItem.ValorAcimaDoLimiteEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Cemento', 1, 10000000).Free;
    end, EValidacao);
end;

procedure TTestesValidacaoItem.ValorZeroEPermitido;
begin
  // Brinde ou bonificação: valor zero é aceito.
  Assert.WillNotRaise(
    procedure
    begin
      TPedidoItemModel.Create(1, 'Brinde', 1, 0).Free;
    end);
end;

procedure TTestesValidacaoItem.MensagemSegueOIdiomaEscolhido;
var
  MensagemEs, MensagemPt: string;
begin
  DefinirIdioma(idEspanhol, False);
  try
    TPedidoItemModel.Create(1, 'X', 0, 1).Free;
  except
    on E: EValidacao do
      MensagemEs := E.Message;
  end;

  DefinirIdioma(idPortugues, False);
  try
    TPedidoItemModel.Create(1, 'X', 0, 1).Free;
  except
    on E: EValidacao do
      MensagemPt := E.Message;
  end;

  Assert.AreNotEqual(MensagemEs, MensagemPt);
  Assert.Contains(MensagemEs, 'cantidad');
  Assert.Contains(MensagemPt, 'quantidade');
  DefinirIdioma(idEspanhol, False);
end;

procedure TTestesValidacaoItem.ClonarCopiaTodosOsCampos;
var
  Original, Copia: TPedidoItemModel;
begin
  Original := TPedidoItemModel.Create(7, 'Arena', 3, 8.5);
  try
    Copia := Original.Clonar;
    try
      Assert.AreEqual(Original.CodigoProduto, Copia.CodigoProduto);
      Assert.AreEqual(Original.Descricao, Copia.Descricao);
      Assert.AreEqual(Original.Quantidade, Copia.Quantidade);
      Assert.AreEqual(Original.VlrUnitario, Copia.VlrUnitario);
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
