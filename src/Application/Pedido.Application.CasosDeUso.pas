unit Pedido.Application.CasosDeUso;

{ Implementação dos casos de uso. Dependem só do domínio (entidades,
  repositórios e eventos), recebidos pelo construtor. Nenhuma linha daqui
  conhece FireDAC, telas ou idiomas. }

interface

uses
  Pedido.Application.Interfaces,
  Pedido.Domain.Cliente,
  Pedido.Domain.Eventos,
  Pedido.Domain.Pedido,
  Pedido.Domain.PedidoItem,
  Pedido.Domain.Produto,
  Pedido.Domain.Repositorios;

type
  TConsultarClienteUseCase = class(TInterfacedObject, IConsultarClienteUseCase)
  private
    FClientes: IClienteRepository;
  public
    constructor Create(const AClientes: IClienteRepository);
    function Executar(ACodigo: Integer): TCliente;
  end;

  TConsultarProdutoUseCase = class(TInterfacedObject, IConsultarProdutoUseCase)
  private
    FProdutos: IProdutoRepository;
  public
    constructor Create(const AProdutos: IProdutoRepository);
    function Executar(ACodigo: Integer): TProduto;
  end;

  TCriarItemPedidoUseCase = class(TInterfacedObject, ICriarItemPedidoUseCase)
  private
    FConsultarProduto: IConsultarProdutoUseCase;
  public
    constructor Create(const AConsultarProduto: IConsultarProdutoUseCase);
    function Executar(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): TPedidoItem;
  end;

  TGravarPedidoUseCase = class(TInterfacedObject, IGravarPedidoUseCase)
  private
    FPedidos: IPedidoRepository;
    FConsultarCliente: IConsultarClienteUseCase;
    FEventos: IPublicadorEventos;
  public
    constructor Create(const APedidos: IPedidoRepository;
      const AConsultarCliente: IConsultarClienteUseCase; const AEventos: IPublicadorEventos);
    procedure Executar(APedido: TPedido);
  end;

  TCarregarPedidoUseCase = class(TInterfacedObject, ICarregarPedidoUseCase)
  private
    FPedidos: IPedidoRepository;
  public
    constructor Create(const APedidos: IPedidoRepository);
    function Executar(ANumero: Integer): TPedido;
  end;

  TCancelarPedidoUseCase = class(TInterfacedObject, ICancelarPedidoUseCase)
  private
    FPedidos: IPedidoRepository;
    FEventos: IPublicadorEventos;
  public
    constructor Create(const APedidos: IPedidoRepository; const AEventos: IPublicadorEventos);
    procedure Executar(ANumero: Integer);
  end;

implementation

uses
  Pedido.Domain.Erros;

{ TConsultarClienteUseCase }

constructor TConsultarClienteUseCase.Create(const AClientes: IClienteRepository);
begin
  inherited Create;
  FClientes := AClientes;
end;

function TConsultarClienteUseCase.Executar(ACodigo: Integer): TCliente;
begin
  Result := FClientes.ObterPorCodigo(ACodigo);
  if Result = nil then
    raise EDominioErro.Create(ceClienteNaoEncontrado, ACodigo);
end;

{ TConsultarProdutoUseCase }

constructor TConsultarProdutoUseCase.Create(const AProdutos: IProdutoRepository);
begin
  inherited Create;
  FProdutos := AProdutos;
end;

function TConsultarProdutoUseCase.Executar(ACodigo: Integer): TProduto;
begin
  Result := FProdutos.ObterPorCodigo(ACodigo);
  if Result = nil then
    raise EDominioErro.Create(ceProdutoNaoEncontrado, ACodigo);
end;

{ TCriarItemPedidoUseCase }

constructor TCriarItemPedidoUseCase.Create(const AConsultarProduto: IConsultarProdutoUseCase);
begin
  inherited Create;
  FConsultarProduto := AConsultarProduto;
end;

function TCriarItemPedidoUseCase.Executar(ACodigoProduto: Integer; AQuantidade: Double;
  AVlrUnitario: Currency): TPedidoItem;
var
  Produto: TProduto;
begin
  Produto := FConsultarProduto.Executar(ACodigoProduto);
  try
    Result := TPedidoItem.Criar(Produto.Codigo, Produto.Descricao, AQuantidade, AVlrUnitario);
  finally
    Produto.Free;
  end;
end;

{ TGravarPedidoUseCase }

constructor TGravarPedidoUseCase.Create(const APedidos: IPedidoRepository;
  const AConsultarCliente: IConsultarClienteUseCase; const AEventos: IPublicadorEventos);
begin
  inherited Create;
  FPedidos := APedidos;
  FConsultarCliente := AConsultarCliente;
  FEventos := AEventos;
end;

procedure TGravarPedidoUseCase.Executar(APedido: TPedido);
var
  Cliente: TCliente;
begin
  // 1) regras do próprio agregado
  APedido.ValidarParaGravacao;
  // 2) o cliente ainda existe? (antes de abrir a transação)
  Cliente := FConsultarCliente.Executar(APedido.CodigoCliente);
  Cliente.Free;
  // 3) grava e avisa quem se interessa
  FPedidos.Salvar(APedido);
  FEventos.Publicar(TPedidoGravadoEvento.Create(APedido.Numero, APedido.Itens.Count,
    APedido.ValorTotal.Valor));
end;

{ TCarregarPedidoUseCase }

constructor TCarregarPedidoUseCase.Create(const APedidos: IPedidoRepository);
begin
  inherited Create;
  FPedidos := APedidos;
end;

function TCarregarPedidoUseCase.Executar(ANumero: Integer): TPedido;
begin
  Result := FPedidos.ObterPorNumero(ANumero);
  if Result = nil then
    raise EDominioErro.Create(cePedidoNaoEncontrado, ANumero);
end;

{ TCancelarPedidoUseCase }

constructor TCancelarPedidoUseCase.Create(const APedidos: IPedidoRepository;
  const AEventos: IPublicadorEventos);
begin
  inherited Create;
  FPedidos := APedidos;
  FEventos := AEventos;
end;

procedure TCancelarPedidoUseCase.Executar(ANumero: Integer);
begin
  if ANumero <= 0 then
    raise EDominioErro.Create(ceNumeroPedidoInvalido, ANumero);
  FPedidos.Excluir(ANumero);
  FEventos.Publicar(TPedidoCanceladoEvento.Create(ANumero));
end;

end.
