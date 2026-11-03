unit Pedido.Model.PedidoItem;

interface

type
  TPedidoItemModel = class
  private
    FCodigoProduto: Integer;
    FDescricao: string;
    FQuantidade: Double;
    FVlrUnitario: Currency;
  public
    constructor Create(ACodigoProduto: Integer; const ADescricao: string;
      AQuantidade: Double; AVlrUnitario: Currency);
    function VlrTotal: Currency;
    function Clonar: TPedidoItemModel;
    property CodigoProduto: Integer read FCodigoProduto;
    property Descricao: string read FDescricao;
    property Quantidade: Double read FQuantidade;
    property VlrUnitario: Currency read FVlrUnitario;
  end;

implementation

uses
  System.Math,
  Pedido.Infra.Idioma,
  Pedido.Model.Excecoes;

const
  // Limites compatíveis com NUMERIC(15,3) e NUMERIC(15,2) do banco.
  QUANTIDADE_MAXIMA = 99999.999;
  VALOR_UNITARIO_MAXIMO = 9999999.99;

constructor TPedidoItemModel.Create(ACodigoProduto: Integer; const ADescricao: string;
  AQuantidade: Double; AVlrUnitario: Currency);
begin
  inherited Create;
  if ACodigoProduto <= 0 then
    raise EValidacao.Create(Tr('msg.produto_codigo'));
  if AQuantidade <= 0 then
    raise EValidacao.Create(Tr('msg.qtd_maior_zero'));
  if AQuantidade > QUANTIDADE_MAXIMA then
    raise EValidacao.Create(Tr('msg.qtd_limite'));
  if AVlrUnitario < 0 then
    raise EValidacao.Create(Tr('msg.vlr_negativo'));
  if AVlrUnitario > VALOR_UNITARIO_MAXIMO then
    raise EValidacao.Create(Tr('msg.vlr_limite'));

  FCodigoProduto := ACodigoProduto;
  FDescricao := ADescricao;
  FQuantidade := AQuantidade;
  FVlrUnitario := AVlrUnitario;
end;

function TPedidoItemModel.VlrTotal: Currency;
begin
  // Arredonda em centavos (meio para cima) para bater com NUMERIC(15,2).
  Result := SimpleRoundTo(FQuantidade * FVlrUnitario, -2);
end;

function TPedidoItemModel.Clonar: TPedidoItemModel;
begin
  Result := TPedidoItemModel.Create(FCodigoProduto, FDescricao, FQuantidade, FVlrUnitario);
end;

end.
