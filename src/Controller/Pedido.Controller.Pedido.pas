unit Pedido.Controller.Pedido;

{ Regras de negócio do pedido. Não tem SQL (fica no DAO) nem conhece a tela. }

interface

uses
  FireDAC.Comp.Client,
  Pedido.Controller.Cliente,
  Pedido.Controller.Produto,
  Pedido.DAO.Pedido,
  Pedido.Model.Pedido,
  Pedido.Model.PedidoItem;

type
  TPedidoController = class
  private
    FPedidoDAO: TPedidoDAO;
    FClienteController: TClienteController;
    FProdutoController: TProdutoController;
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    // Monta o item a partir do cadastro do produto (descrição vem do banco).
    function CriarItem(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): TPedidoItemModel;

    procedure Gravar(APedido: TPedidoModel);
    // Levanta EPedidoNaoEncontrado se o número não existir.
    function GetPedido(ANumero: Integer): TPedidoModel;
    procedure Cancelar(ANumero: Integer);
  end;

implementation

uses
  Pedido.Infra.Idioma,
  Pedido.Model.Cliente,
  Pedido.Model.Produto,
  Pedido.Model.Excecoes;

constructor TPedidoController.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FPedidoDAO := TPedidoDAO.Create(AConexao);
  FClienteController := TClienteController.Create(AConexao);
  FProdutoController := TProdutoController.Create(AConexao);
end;

destructor TPedidoController.Destroy;
begin
  FProdutoController.Free;
  FClienteController.Free;
  FPedidoDAO.Free;
  inherited;
end;

function TPedidoController.CriarItem(ACodigoProduto: Integer; AQuantidade: Double;
  AVlrUnitario: Currency): TPedidoItemModel;
var
  Produto: TProdutoModel;
begin
  Produto := FProdutoController.GetProduto(ACodigoProduto);
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

  // Garante que o cliente ainda existe antes de abrir a transação.
  Cliente := FClienteController.GetCliente(APedido.CodigoCliente);
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
