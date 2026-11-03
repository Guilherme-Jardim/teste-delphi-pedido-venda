unit Pedido.Domain.PedidoItem;

interface

uses
  Pedido.Domain.ObjetosValor;

type
  // Entidade interna do agregado Pedido: só existe dentro de um pedido.
  TPedidoItem = class
  private
    FCodigoProduto: Integer;
    FDescricao: string;
    FQuantidade: TQuantidade;
    FVlrUnitario: TDinheiro;
  public
    constructor Create(ACodigoProduto: Integer; const ADescricao: string;
      const AQuantidade: TQuantidade; const AVlrUnitario: TDinheiro);
    // Atalho que valida os números brutos e monta os objetos de valor.
    class function Criar(ACodigoProduto: Integer; const ADescricao: string;
      AQuantidade: Double; AVlrUnitario: Currency): TPedidoItem; static;
    function VlrTotal: TDinheiro;
    function Clonar: TPedidoItem;
    property CodigoProduto: Integer read FCodigoProduto;
    property Descricao: string read FDescricao;
    property Quantidade: TQuantidade read FQuantidade;
    property VlrUnitario: TDinheiro read FVlrUnitario;
  end;

implementation

uses
  Pedido.Domain.Erros;

constructor TPedidoItem.Create(ACodigoProduto: Integer; const ADescricao: string;
  const AQuantidade: TQuantidade; const AVlrUnitario: TDinheiro);
begin
  inherited Create;
  if ACodigoProduto <= 0 then
    raise EDominioErro.Create(ceCodigoProdutoInvalido, ACodigoProduto);
  FCodigoProduto := ACodigoProduto;
  FDescricao := ADescricao;
  FQuantidade := AQuantidade;
  FVlrUnitario := AVlrUnitario;
end;

class function TPedidoItem.Criar(ACodigoProduto: Integer; const ADescricao: string;
  AQuantidade: Double; AVlrUnitario: Currency): TPedidoItem;
begin
  if ACodigoProduto <= 0 then
    raise EDominioErro.Create(ceCodigoProdutoInvalido, ACodigoProduto);
  Result := TPedidoItem.Create(ACodigoProduto, ADescricao, TQuantidade.Criar(AQuantidade),
    TDinheiro.Criar(AVlrUnitario));
end;

function TPedidoItem.VlrTotal: TDinheiro;
begin
  Result := FVlrUnitario.Multiplicar(FQuantidade);
end;

function TPedidoItem.Clonar: TPedidoItem;
begin
  Result := TPedidoItem.Create(FCodigoProduto, FDescricao, FQuantidade, FVlrUnitario);
end;

end.
