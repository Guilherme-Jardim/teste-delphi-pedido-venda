unit Pedido.Controller.Pedido;

{ Mantém o pedido em edição e coordena tela e service.
  A tela só pergunta e mostra; as decisões ficam aqui e no service. }

interface

uses
  Pedido.Model.Cliente,
  Pedido.Model.Produto,
  Pedido.Model.Pedido,
  Pedido.Model.PedidoItem,
  Pedido.Service.Pedido;

type
  TPedidoController = class
  private
    FService: TPedidoService;
    FPedido: TPedido;
    FIndiceEmEdicao: Integer;
  public
    constructor Create(AService: TPedidoService);
    destructor Destroy; override;

    procedure NovoPedido;
    procedure CarregarPedido(ANumero: Integer);
    procedure CancelarPedido(ANumero: Integer);
    procedure GravarPedido;

    function InformarCliente(ACodigo: Integer): TCliente;
    function ConsultarProduto(ACodigo: Integer): TProduto;

    // Inclui um item novo ou, se um item foi carregado para edição,
    // atualiza esse item. Devolve o índice afetado.
    function SalvarItem(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): Integer;
    function IniciarEdicaoItem(AIndice: Integer): TPedidoItem;
    procedure CancelarEdicaoItem;
    procedure ExcluirItem(AIndice: Integer);

    function EmEdicao: Boolean;
    property Pedido: TPedido read FPedido;
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TPedidoController.Create(AService: TPedidoService);
begin
  inherited Create;
  FService := AService;
  NovoPedido;
end;

destructor TPedidoController.Destroy;
begin
  FPedido.Free;
  inherited;
end;

procedure TPedidoController.NovoPedido;
begin
  FPedido.Free;
  FPedido := TPedido.Create;
  FIndiceEmEdicao := -1;
end;

procedure TPedidoController.CarregarPedido(ANumero: Integer);
var
  Carregado: TPedido;
begin
  Carregado := FService.CarregarPedido(ANumero);
  FPedido.Free;
  FPedido := Carregado;
  FIndiceEmEdicao := -1;
end;

procedure TPedidoController.CancelarPedido(ANumero: Integer);
begin
  FService.CancelarPedido(ANumero);
  // Se o pedido cancelado era o que estava na tela, limpa a tela.
  if FPedido.Numero = ANumero then
    NovoPedido;
end;

procedure TPedidoController.GravarPedido;
begin
  FService.GravarPedido(FPedido);
end;

function TPedidoController.InformarCliente(ACodigo: Integer): TCliente;
begin
  Result := FService.BuscarCliente(ACodigo);
  FPedido.CodigoCliente := Result.Codigo;
end;

function TPedidoController.ConsultarProduto(ACodigo: Integer): TProduto;
begin
  Result := FService.BuscarProduto(ACodigo);
end;

function TPedidoController.SalvarItem(ACodigoProduto: Integer; AQuantidade: Double;
  AVlrUnitario: Currency): Integer;
var
  Produto: TProduto;
  Item: TPedidoItem;
begin
  Produto := FService.BuscarProduto(ACodigoProduto);
  try
    Item := TPedidoItem.Create(Produto.Codigo, Produto.Descricao, AQuantidade,
      AVlrUnitario);
  finally
    Produto.Free;
  end;

  if FIndiceEmEdicao >= 0 then
  begin
    Result := FIndiceEmEdicao;
    FPedido.AtualizarItem(Result, Item);
    FIndiceEmEdicao := -1;
  end
  else
    Result := FPedido.AdicionarItem(Item);
end;

function TPedidoController.IniciarEdicaoItem(AIndice: Integer): TPedidoItem;
begin
  if (AIndice < 0) or (AIndice >= FPedido.Itens.Count) then
    raise EValidacao.Create('Selecione um item do grid.');
  FIndiceEmEdicao := AIndice;
  Result := FPedido.Itens[AIndice];
end;

procedure TPedidoController.CancelarEdicaoItem;
begin
  FIndiceEmEdicao := -1;
end;

procedure TPedidoController.ExcluirItem(AIndice: Integer);
begin
  FPedido.RemoverItem(AIndice);
  // Se o item excluído estava em edição (ou ficou antes dele), ajusta o índice.
  if FIndiceEmEdicao = AIndice then
    FIndiceEmEdicao := -1
  else if (FIndiceEmEdicao > AIndice) then
    Dec(FIndiceEmEdicao);
end;

function TPedidoController.EmEdicao: Boolean;
begin
  Result := FIndiceEmEdicao >= 0;
end;

end.
