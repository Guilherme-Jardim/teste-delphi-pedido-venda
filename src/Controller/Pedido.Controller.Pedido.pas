unit Pedido.Controller.Pedido;

{ Regras de negócio do pedido. Não tem SQL (fica no DAO) nem conhece a tela,
  e depende só de interfaces: o DAO e os controllers de cliente e produto
  chegam pelo construtor. }

interface

uses
  Pedido.Controller.Interfaces,
  Pedido.DAO.Interfaces,
  Pedido.Model.Pedido,
  Pedido.Model.PedidoItem;

type
  TPedidoController = class(TInterfacedObject, IPedidoController)
  private
    FPedidoDAO: IPedidoDAO;
    FClientes: IClienteController;
    FProdutos: IProdutoController;
  public
    constructor Create(const APedidoDAO: IPedidoDAO; const AClientes: IClienteController;
      const AProdutos: IProdutoController);

    function CriarItem(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): TPedidoItemModel;
    procedure Gravar(APedido: TPedidoModel);
    function GetPedido(ANumero: Integer): TPedidoModel;
    procedure Cancelar(ANumero: Integer);
  end;

implementation

uses
  Pedido.Infra.Idioma,
  Pedido.Model.Cliente,
  Pedido.Model.Excecoes,
  Pedido.Model.Produto;

constructor TPedidoController.Create(const APedidoDAO: IPedidoDAO;
  const AClientes: IClienteController; const AProdutos: IProdutoController);
begin
  inherited Create;
  FPedidoDAO := APedidoDAO;
  FClientes := AClientes;
  FProdutos := AProdutos;
end;

function TPedidoController.CriarItem(ACodigoProduto: Integer; AQuantidade: Double;
  AVlrUnitario: Currency): TPedidoItemModel;
var
  Produto: TProdutoModel;
begin
  Produto := FProdutos.GetProduto(ACodigoProduto);
  try
    Result := TPedidoItemModel.Create(Produto.Codigo, Produto.Descricao,
      AQuantidade, AVlrUnitario);
  finally
    Produto.Free;
  end;
end;

procedure TPedidoController.Gravar(APedido: TPedidoModel);
var
  Cliente: TClienteModel;
begin
  if APedido.CodigoCliente <= 0 then
    raise EValidacao.Create(Tr('msg.sem_cliente'));
  if APedido.Itens.Count = 0 then
    raise EValidacao.Create(Tr('msg.sem_itens'));
  if Length(APedido.Observacao) > OBSERVACAO_TAMANHO_MAXIMO then
    raise EValidacao.Create(Tr('msg.obs_longa', [OBSERVACAO_TAMANHO_MAXIMO]));

  // Garante que o cliente ainda existe antes de abrir a transação.
  Cliente := FClientes.GetCliente(APedido.CodigoCliente);
  Cliente.Free;

  FPedidoDAO.Gravar(APedido);
end;

function TPedidoController.GetPedido(ANumero: Integer): TPedidoModel;
begin
  Result := FPedidoDAO.GetPedido(ANumero);
  if Result = nil then
    raise EPedidoNaoEncontrado.Create(ANumero);
end;

procedure TPedidoController.Cancelar(ANumero: Integer);
begin
  if ANumero <= 0 then
    raise EValidacao.Create(Tr('msg.numero_invalido'));
  FPedidoDAO.Excluir(ANumero);
end;

end.
