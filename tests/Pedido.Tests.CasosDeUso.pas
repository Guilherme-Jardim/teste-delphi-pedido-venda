unit Pedido.Tests.CasosDeUso;

{ Regras dos casos de uso, testadas com repositórios falsos (sem banco de dados).
  Mostra na prática a inversão de dependência: o caso de uso recebe
  interfaces do domínio pelo construtor e não sabe de onde os dados vêm. }

interface

uses
  DUnitX.TestFramework,
  Pedido.Application.Interfaces,
  Pedido.Domain.Pedido,
  Pedido.Tests.Falsos;

type
  [TestFixture]
  TTestesCasosDeUso = class
  private
    FClientes: TClienteRepositorioFalso;
    FProdutos: TProdutoRepositorioFalso;
    FPedidosRepo: TPedidoRepositorioFalso;
    FEventos: TAssinanteGravador;
    FCasos: TCasosDeUsoPedido;
    FPedido: TPedido;
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
    procedure GravarSemClienteEInvalidoENaoChegaAoRepositorio;
    [Test]
    procedure GravarSemItensEInvalidoENaoChegaAoRepositorio;
    [Test]
    procedure GravarComClienteInexistenteNaoChegaAoRepositorio;
    [Test]
    procedure GravarPedidoValidoChamaORepositorioEDefineONumero;
    [Test]
    procedure GetPedidoInexistenteLevantaErro;
    [Test]
    procedure GetPedidoGravadoDevolveCabecalhoEItens;
    [Test]
    procedure CancelarComNumeroZeroEInvalido;
    [Test]
    procedure CancelarComNumeroNegativoEInvalido;
    [Test]
    procedure CancelarPedidoGravadoExcluiNoRepositorio;
    [Test]
    procedure CancelarPedidoInexistenteLevantaErro;
    [Test]
    procedure GravarPublicaOEventoPedidoGravado;
    [Test]
    procedure GravarInvalidoNaoPublicaEvento;
    [Test]
    procedure CancelarPublicaOEventoPedidoCancelado;
    [Test]
    procedure ErrosCarregamCodigoEValorDoDominio;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Application.CasosDeUso,
  Pedido.Application.Eventos,
  Pedido.Domain.Cliente,
  Pedido.Domain.Erros,
  Pedido.Domain.Eventos,
  Pedido.Domain.PedidoItem,
  Pedido.Domain.Produto,
  Pedido.Domain.Repositorios,
  Pedido.Infra.Idioma;

procedure TTestesCasosDeUso.Setup;
var
  Clientes: IClienteRepository;
  Produtos: IProdutoRepository;
  Pedidos: IPedidoRepository;
  Publicador: IPublicadorEventos;
  Assinante: IAssinanteEventos;
  ConsultarCliente: IConsultarClienteUseCase;
  ConsultarProduto: IConsultarProdutoUseCase;
begin
  DefinirIdioma(idEspanhol, False);
  FClientes := TClienteRepositorioFalso.Create;
  FProdutos := TProdutoRepositorioFalso.Create;
  FPedidosRepo := TPedidoRepositorioFalso.Create;
  FEventos := TAssinanteGravador.Create;
  FClientes.Adicionar(1, 'Construtora Serra Azul', 'Caxias do Sul', 'RS');
  FProdutos.Adicionar(10, 'Cimento CP-II 50kg', 39.9);

  // As interfaces seguram as instâncias (contagem de referências).
  Clientes := FClientes;
  Produtos := FProdutos;
  Pedidos := FPedidosRepo;
  Assinante := FEventos;
  Publicador := TPublicadorEventosEmMemoria.Create;
  Publicador.Assinar(Assinante);

  ConsultarCliente := TConsultarClienteUseCase.Create(Clientes);
  ConsultarProduto := TConsultarProdutoUseCase.Create(Produtos);
  FCasos.ConsultarCliente := ConsultarCliente;
  FCasos.ConsultarProduto := ConsultarProduto;
  FCasos.CriarItem := TCriarItemPedidoUseCase.Create(ConsultarProduto);
  FCasos.Gravar := TGravarPedidoUseCase.Create(Pedidos, ConsultarCliente, Publicador);
  FCasos.Carregar := TCarregarPedidoUseCase.Create(Pedidos);
  FCasos.Cancelar := TCancelarPedidoUseCase.Create(Pedidos, Publicador);
  FPedido := TPedido.Create;
end;

procedure TTestesCasosDeUso.TearDown;
begin
  FPedido.Free;
  FCasos := Default(TCasosDeUsoPedido);
end;

procedure TTestesCasosDeUso.ClienteExistenteEDevolvidoComDados;
var
  Cliente: TCliente;
begin
  Cliente := FCasos.ConsultarCliente.Executar(1);
  try
    Assert.AreEqual('Construtora Serra Azul', Cliente.Nome);
    Assert.AreEqual('RS', Cliente.UF);
  finally
    Cliente.Free;
  end;
end;

procedure TTestesCasosDeUso.ClienteInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.ConsultarCliente.Executar(99).Free;
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.ProdutoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.ConsultarProduto.Executar(99).Free;
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.CriarItemUsaADescricaoDoCadastro;
var
  Item: TPedidoItem;
begin
  Item := FCasos.CriarItem.Executar(10, 2, 39.9);
  try
    Assert.AreEqual('Cimento CP-II 50kg', Item.Descricao);
    Assert.AreEqual(10, Item.CodigoProduto);
  finally
    Item.Free;
  end;
end;

procedure TTestesCasosDeUso.CriarItemComProdutoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.CriarItem.Executar(99, 1, 10).Free;
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.CriarItemRespeitaValorEQuantidadeInformados;
var
  Item: TPedidoItem;
begin
  // O valor pode ser diferente do preço de venda cadastrado.
  Item := FCasos.CriarItem.Executar(10, 3, 35);
  try
    Assert.AreEqual(Currency(35), Item.VlrUnitario.Valor);
    Assert.AreEqual(Currency(105), Item.VlrTotal.Valor);
  finally
    Item.Free;
  end;
end;

procedure TTestesCasosDeUso.GravarSemClienteEInvalidoENaoChegaAoRepositorio;
begin
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  Assert.WillRaise(
    procedure
    begin
      FCasos.Gravar.Executar(FPedido);
    end, EDominioErro);
  Assert.AreEqual(0, FPedidosRepo.Gravacoes);
end;

procedure TTestesCasosDeUso.GravarSemItensEInvalidoENaoChegaAoRepositorio;
begin
  FPedido.InformarCliente(1);
  Assert.WillRaise(
    procedure
    begin
      FCasos.Gravar.Executar(FPedido);
    end, EDominioErro);
  Assert.AreEqual(0, FPedidosRepo.Gravacoes);
end;

procedure TTestesCasosDeUso.GravarComClienteInexistenteNaoChegaAoRepositorio;
begin
  FPedido.InformarCliente(99);
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  Assert.WillRaise(
    procedure
    begin
      FCasos.Gravar.Executar(FPedido);
    end, EDominioErro);
  Assert.AreEqual(0, FPedidosRepo.Gravacoes);
end;

procedure TTestesCasosDeUso.GravarPedidoValidoChamaORepositorioEDefineONumero;
begin
  FPedido.InformarCliente(1);
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 2, 39.9));
  FCasos.Gravar.Executar(FPedido);
  Assert.AreEqual(1, FPedidosRepo.Gravacoes);
  Assert.AreEqual(1, FPedido.Numero);
end;

procedure TTestesCasosDeUso.GetPedidoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.Carregar.Executar(123).Free;
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.GetPedidoGravadoDevolveCabecalhoEItens;
var
  Carregado: TPedido;
begin
  FPedido.InformarCliente(1);
  FPedido.DefinirObservacao('Entrega pela manhã');
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 2, 39.9));
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  FCasos.Gravar.Executar(FPedido);

  Carregado := FCasos.Carregar.Executar(FPedido.Numero);
  try
    Assert.AreEqual(1, Carregado.CodigoCliente);
    Assert.AreEqual('Entrega pela manhã', Carregado.Observacao);
    Assert.AreEqual(2, Carregado.Itens.Count);
    Assert.AreEqual(Currency(119.7), Carregado.ValorTotal.Valor);
  finally
    Carregado.Free;
  end;
end;

procedure TTestesCasosDeUso.CancelarComNumeroZeroEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.Cancelar.Executar(0);
    end, EDominioErro);
  Assert.AreEqual(0, FPedidosRepo.Exclusoes);
end;

procedure TTestesCasosDeUso.CancelarComNumeroNegativoEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.Cancelar.Executar(-5);
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.CancelarPedidoGravadoExcluiNoRepositorio;
begin
  FPedido.InformarCliente(1);
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  FCasos.Gravar.Executar(FPedido);
  FCasos.Cancelar.Executar(FPedido.Numero);
  Assert.AreEqual(1, FPedidosRepo.Exclusoes);
  Assert.WillRaise(
    procedure
    begin
      FCasos.Carregar.Executar(FPedido.Numero).Free;
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.CancelarPedidoInexistenteLevantaErro;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.Cancelar.Executar(777);
    end, EDominioErro);
end;

procedure TTestesCasosDeUso.GravarPublicaOEventoPedidoGravado;
begin
  FPedido.InformarCliente(1);
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  FCasos.Gravar.Executar(FPedido);
  Assert.AreEqual(1, FEventos.Nomes.Count);
  Assert.AreEqual('PedidoGravado', FEventos.Nomes[0]);
end;

procedure TTestesCasosDeUso.GravarInvalidoNaoPublicaEvento;
begin
  Assert.WillRaise(
    procedure
    begin
      FCasos.Gravar.Executar(FPedido);
    end, EDominioErro);
  Assert.AreEqual(0, FEventos.Nomes.Count);
end;

procedure TTestesCasosDeUso.CancelarPublicaOEventoPedidoCancelado;
begin
  FPedido.InformarCliente(1);
  FPedido.AdicionarItem(FCasos.CriarItem.Executar(10, 1, 39.9));
  FCasos.Gravar.Executar(FPedido);
  FCasos.Cancelar.Executar(FPedido.Numero);
  Assert.AreEqual(2, FEventos.Nomes.Count);
  Assert.AreEqual('PedidoCancelado', FEventos.Nomes[1]);
end;

procedure TTestesCasosDeUso.ErrosCarregamCodigoEValorDoDominio;
var
  Codigo: TCodigoErro;
  Valor: Integer;
begin
  Codigo := ceSemItens;
  Valor := -1;
  try
    FCasos.ConsultarCliente.Executar(99).Free;
  except
    on E: EDominioErro do
    begin
      Codigo := E.Codigo;
      Valor := E.Valor;
    end;
  end;
  Assert.AreEqual(Ord(ceClienteNaoEncontrado), Ord(Codigo));
  Assert.AreEqual(99, Valor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesCasosDeUso);

end.
