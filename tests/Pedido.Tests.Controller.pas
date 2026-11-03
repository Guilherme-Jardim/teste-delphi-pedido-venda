unit Pedido.Tests.Controller;

{ Regras dos controllers, testadas com DAOs falsos (sem banco de dados).
  Mostra na prática a inversão de dependência: o controller recebe
  interfaces pelo construtor e não sabe de onde os dados vêm. }

interface

uses
  DUnitX.TestFramework,
  Pedido.Controller.Interfaces,
  Pedido.Model.Pedido,
  Pedido.Tests.Falsos;

type
  [TestFixture]
  TTestesController = class
  private
    FClientes: TClienteDAOFalso;
    FProdutos: TProdutoDAOFalso;
    FPedidosDAO: TPedidoDAOFalso;
    FClienteController: IClienteController;
    FProdutoController: IProdutoController;
    FController: IPedidoController;
    FPedido: TPedidoModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure ClienteExistenteEDevolvidoComDados;
    [Test]
    procedure ClienteInexistenteLevantaErro;
    [Test]
    procedure ProdutoInexistenteLevantaErro;
    [Test]
    procedure CriarItemUsaADescricaoDoCadastro;
    [Test]
    procedure CriarItemComProdutoInexistenteLevantaErro;
    [Test]
    procedure CriarItemRespeitaValorEQuantidadeInformados;
    [Test]
    procedure GravarSemClienteEInvalidoENaoChegaNoDAO;
    [Test]
    procedure GravarSemItensEInvalidoENaoChegaNoDAO;
    [Test]
    procedure GravarComObservacaoLongaEInvalidoENaoChegaNoDAO;
    [Test]
    procedure GravarComClienteInexistenteNaoChegaNoDAO;
    [Test]
    procedure GravarPedidoValidoChamaODAOEDefineONumero;
    [Test]
    procedure GetPedidoInexistenteLevantaErro;
    [Test]
    procedure GetPedidoGravadoDevolveCabecalhoEItens;
    [Test]
    procedure CancelarComNumeroZeroEInvalido;
    [Test]
    procedure CancelarComNumeroNegativoEInvalido;
    [Test]
    procedure CancelarPedidoGravadoExcluiNoDAO;
    [Test]
    procedure CancelarPedidoInexistenteLevantaErro;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Controller.Cliente,
  Pedido.Controller.Pedido,
  Pedido.Controller.Produto,
  Pedido.DAO.Interfaces,
  Pedido.Infra.Idioma,
  Pedido.Model.Cliente,
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem,
  Pedido.Model.Produto;

procedure TTestesController.Setup;
var
  ClienteDAO: IClienteDAO;
  ProdutoDAO: IProdutoDAO;
  PedidoDAO: IPedidoDAO;
begin
  DefinirIdioma(idEspanhol, False);
  FClientes := TClienteDAOFalso.Create;
  FProdutos := TProdutoDAOFalso.Create;
  FPedidosDAO := TPedidoDAOFalso.Create;
  FClientes.Adicionar(1, 'Construtora Serra Azul', 'Caxias do Sul', 'RS');
  FProdutos.Adicionar(10, 'Cimento CP-II 50kg', 39.9);

  // As interfaces seguram as instâncias (contagem de referências).
  ClienteDAO := FClientes;
  ProdutoDAO := FProdutos;
  PedidoDAO := FPedidosDAO;
  FClienteController := TClienteController.Create(ClienteDAO);
  FProdutoController := TProdutoController.Create(ProdutoDAO);
  FController := TPedidoController.Create(PedidoDAO, FClienteController, FProdutoController);
  FPedido := TPedidoModel.Create;
end;

procedure TTestesController.TearDown;
begin
  FPedido.Free;
  FController := nil;
  FProdutoController := nil;
  FClienteController := nil;
end;

procedure TTestesController.ClienteExistenteEDevolvidoComDados;
var
  Cliente: TClienteModel;
begin
  Cliente := FClienteController.GetCliente(1);
  try
    Assert.AreEqual('Construtora Serra Azul', Cliente.Nome);
    Assert.AreEqual('RS', Cliente.UF);
  finally
    Cliente.Free;
  end;
end;

procedure TTestesController.ClienteInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FClienteController.GetCliente(99).Free;
    end, EClienteNaoEncontrado);
end;

procedure TTestesController.ProdutoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FProdutoController.GetProduto(99).Free;
    end, EProdutoNaoEncontrado);
end;

procedure TTestesController.CriarItemUsaADescricaoDoCadastro;
var
  Item: TPedidoItemModel;
begin
  Item := FController.CriarItem(10, 2, 39.9);
  try
    Assert.AreEqual('Cimento CP-II 50kg', Item.Descricao);
    Assert.AreEqual(10, Item.CodigoProduto);
  finally
    Item.Free;
  end;
end;

procedure TTestesController.CriarItemComProdutoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.CriarItem(99, 1, 10).Free;
    end, EProdutoNaoEncontrado);
end;

procedure TTestesController.CriarItemRespeitaValorEQuantidadeInformados;
var
  Item: TPedidoItemModel;
begin
  // O valor pode ser diferente do preço de venda cadastrado.
  Item := FController.CriarItem(10, 3, 35);
  try
    Assert.AreEqual(Currency(35), Item.VlrUnitario);
    Assert.AreEqual(Currency(105), Item.VlrTotal);
  finally
    Item.Free;
  end;
end;

procedure TTestesController.GravarSemClienteEInvalidoENaoChegaNoDAO;
begin
  FPedido.AdicionarItem(FController.CriarItem(10, 1, 39.9));
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EValidacao);
  Assert.AreEqual(0, FPedidosDAO.Gravacoes);
end;

procedure TTestesController.GravarSemItensEInvalidoENaoChegaNoDAO;
begin
  FPedido.CodigoCliente := 1;
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EValidacao);
  Assert.AreEqual(0, FPedidosDAO.Gravacoes);
end;

procedure TTestesController.GravarComObservacaoLongaEInvalidoENaoChegaNoDAO;
begin
  FPedido.CodigoCliente := 1;
  FPedido.AdicionarItem(FController.CriarItem(10, 1, 39.9));
  FPedido.Observacao := StringOfChar('x', OBSERVACAO_TAMANHO_MAXIMO + 1);
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EValidacao);
  Assert.AreEqual(0, FPedidosDAO.Gravacoes);
  FPedido.Observacao := StringOfChar('x', OBSERVACAO_TAMANHO_MAXIMO);
  FController.Gravar(FPedido);
  Assert.AreEqual(1, FPedidosDAO.Gravacoes);
end;

procedure TTestesController.GravarComClienteInexistenteNaoChegaNoDAO;
begin
  FPedido.CodigoCliente := 99;
  FPedido.AdicionarItem(FController.CriarItem(10, 1, 39.9));
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EClienteNaoEncontrado);
  Assert.AreEqual(0, FPedidosDAO.Gravacoes);
end;

procedure TTestesController.GravarPedidoValidoChamaODAOEDefineONumero;
begin
  FPedido.CodigoCliente := 1;
  FPedido.AdicionarItem(FController.CriarItem(10, 2, 39.9));
  FController.Gravar(FPedido);
  Assert.AreEqual(1, FPedidosDAO.Gravacoes);
  Assert.AreEqual(1, FPedido.Numero);
end;

procedure TTestesController.GetPedidoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.GetPedido(123).Free;
    end, EPedidoNaoEncontrado);
end;

procedure TTestesController.GetPedidoGravadoDevolveCabecalhoEItens;
var
  Carregado: TPedidoModel;
begin
  FPedido.CodigoCliente := 1;
  FPedido.Observacao := 'Entrega pela manhã';
  FPedido.AdicionarItem(FController.CriarItem(10, 2, 39.9));
  FPedido.AdicionarItem(FController.CriarItem(10, 1, 39.9));
  FController.Gravar(FPedido);

  Carregado := FController.GetPedido(FPedido.Numero);
  try
    Assert.AreEqual(1, Carregado.CodigoCliente);
    Assert.AreEqual('Entrega pela manhã', Carregado.Observacao);
    Assert.AreEqual(2, Carregado.Itens.Count);
    Assert.AreEqual(Currency(119.7), Carregado.ValorTotal);
  finally
    Carregado.Free;
  end;
end;

procedure TTestesController.CancelarComNumeroZeroEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.Cancelar(0);
    end, EValidacao);
  Assert.AreEqual(0, FPedidosDAO.Exclusoes);
end;

procedure TTestesController.CancelarComNumeroNegativoEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.Cancelar(-5);
    end, EValidacao);
end;

procedure TTestesController.CancelarPedidoGravadoExcluiNoDAO;
begin
  FPedido.CodigoCliente := 1;
  FPedido.AdicionarItem(FController.CriarItem(10, 1, 39.9));
  FController.Gravar(FPedido);
  FController.Cancelar(FPedido.Numero);
  Assert.AreEqual(1, FPedidosDAO.Exclusoes);
  Assert.WillRaise(
    procedure
    begin
      FController.GetPedido(FPedido.Numero).Free;
    end, EPedidoNaoEncontrado);
end;

procedure TTestesController.CancelarPedidoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.Cancelar(777);
    end, EPedidoNaoEncontrado);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesController);

end.
