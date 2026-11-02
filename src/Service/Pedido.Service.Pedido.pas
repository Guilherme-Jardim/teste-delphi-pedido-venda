unit Pedido.Service.Pedido;

{ Regras de negócio do pedido. Não conhece FireDAC nem a tela. }

interface

uses
  Pedido.Model.Cliente,
  Pedido.Model.Produto,
  Pedido.Model.Pedido,
  Pedido.Repository.Interfaces;

type
  TPedidoService = class
  private
    FClientes: IClienteRepository;
    FProdutos: IProdutoRepository;
    FPedidos: IPedidoRepository;
  public
    constructor Create(AClientes: IClienteRepository; AProdutos: IProdutoRepository;
      APedidos: IPedidoRepository);

    // Os objetos retornados pertencem a quem chamou.
    function BuscarCliente(ACodigo: Integer): TCliente;
    function BuscarProduto(ACodigo: Integer): TProduto;
    function CarregarPedido(ANumero: Integer): TPedido;

    procedure GravarPedido(APedido: TPedido);
    procedure CancelarPedido(ANumero: Integer);
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TPedidoService.Create(AClientes: IClienteRepository;
  AProdutos: IProdutoRepository; APedidos: IPedidoRepository);
begin
  inherited Create;
  FClientes := AClientes;
  FProdutos := AProdutos;
  FPedidos := APedidos;
end;

function TPedidoService.BuscarCliente(ACodigo: Integer): TCliente;
begin
  Result := FClientes.BuscarPorCodigo(ACodigo);
  if Result = nil then
    raise EClienteNaoEncontrado.Create(ACodigo);
end;

function TPedidoService.BuscarProduto(ACodigo: Integer): TProduto;
begin
  Result := FProdutos.BuscarPorCodigo(ACodigo);
  if Result = nil then
    raise EProdutoNaoEncontrado.Create(ACodigo);
end;

function TPedidoService.CarregarPedido(ANumero: Integer): TPedido;
begin
  Result := FPedidos.BuscarPorNumero(ANumero);
  if Result = nil then
    raise EPedidoNaoEncontrado.Create(ANumero);
end;

procedure TPedidoService.GravarPedido(APedido: TPedido);
var
  Cliente: TCliente;
begin
  if APedido.CodigoCliente <= 0 then
    raise EValidacao.Create('Informe o cliente do pedido.');
  if APedido.Itens.Count = 0 then
    raise EValidacao.Create('Inclua ao menos um item no pedido.');

  // Garante que o cliente ainda existe antes de abrir a transação.
  Cliente := BuscarCliente(APedido.CodigoCliente);
  Cliente.Free;

  FPedidos.Gravar(APedido);
end;

procedure TPedidoService.CancelarPedido(ANumero: Integer);
begin
  if ANumero <= 0 then
    raise EValidacao.Create('Informe o número do pedido.');
  FPedidos.Excluir(ANumero);
end;

end.
