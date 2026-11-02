unit Pedido.Model.PedidoItem;

interface

type
  TPedidoItem = class
  private
    FCodigoProduto: Integer;
    FDescricao: string;
    FQuantidade: Double;
    FVlrUnitario: Currency;
  public
    constructor Create(ACodigoProduto: Integer; const ADescricao: string;
      AQuantidade: Double; AVlrUnitario: Currency);
    function VlrTotal: Currency;
    function Clonar: TPedidoItem;
    property CodigoProduto: Integer read FCodigoProduto;
    property Descricao: string read FDescricao;
    property Quantidade: Double read FQuantidade;
    property VlrUnitario: Currency read FVlrUnitario;
  end;

implementation

uses
  System.Math,
  Pedido.Model.Excecoes;

constructor TPedidoItem.Create(ACodigoProduto: Integer; const ADescricao: string;
  AQuantidade: Double; AVlrUnitario: Currency);
begin
  inherited Create;
  if ACodigoProduto <= 0 then
    raise EValidacao.Create('Informe o código do produto.');
  if AQuantidade <= 0 then
    raise EValidacao.Create('A quantidade deve ser maior que zero.');
  if AVlrUnitario < 0 then
    raise EValidacao.Create('O valor unitário não pode ser negativo.');

  FCodigoProduto := ACodigoProduto;
  FDescricao := ADescricao;
  FQuantidade := AQuantidade;
  FVlrUnitario := AVlrUnitario;
end;

function TPedidoItem.VlrTotal: Currency;
begin
  // Arredonda em centavos (meio para cima) para bater com NUMERIC(15,2).
  Result := SimpleRoundTo(FQuantidade * FVlrUnitario, -2);
end;

function TPedidoItem.Clonar: TPedidoItem;
begin
  Result := TPedidoItem.Create(FCodigoProduto, FDescricao, FQuantidade, FVlrUnitario);
end;

end.
