unit Pedido.Domain.Produto;

interface

uses
  Pedido.Domain.ObjetosValor;

type
  // Entidade: o produto é identificado pelo código; o preço de venda é um objeto de valor.
  TProduto = class
  private
    FCodigo: Integer;
    FDescricao: string;
    FPrecoVenda: TDinheiro;
  public
    constructor Create(ACodigo: Integer; const ADescricao: string; const APrecoVenda: TDinheiro);
    property Codigo: Integer read FCodigo;
    property Descricao: string read FDescricao;
    property PrecoVenda: TDinheiro read FPrecoVenda;
  end;

implementation

constructor TProduto.Create(ACodigo: Integer; const ADescricao: string;
  const APrecoVenda: TDinheiro);
begin
  inherited Create;
  FCodigo := ACodigo;
  FDescricao := ADescricao;
  FPrecoVenda := APrecoVenda;
end;

end.
