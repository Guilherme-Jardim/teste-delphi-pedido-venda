unit Pedido.Infra.Persistencia.Produto;

interface

uses
  Pedido.Domain.Produto,
  Pedido.Domain.Repositorios,
  Pedido.Infra.Persistencia.Base;

type
  TProdutoRepositorioFireDAC = class(TRepositorioFireDACBase, IProdutoRepository)
  public
    function ObterPorCodigo(ACodigo: Integer): TProduto;
  end;

implementation

uses
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  Pedido.Domain.ObjetosValor;

const
  SQL_POR_CODIGO =
    'SELECT CODIGO, DESCRICAO, PRECO_VENDA FROM PRODUTO WHERE CODIGO = :CODIGO';

function TProdutoRepositorioFireDAC.ObterPorCodigo(ACodigo: Integer): TProduto;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := NovaQuery(SQL_POR_CODIGO);
  try
    Query.ParamByName('CODIGO').AsInteger := ACodigo;
    Query.Open;
    if not Query.IsEmpty then
      Result := TProduto.Create(
        Query.FieldByName('CODIGO').AsInteger,
        Query.FieldByName('DESCRICAO').AsString,
        TDinheiro.DeResultado(Query.FieldByName('PRECO_VENDA').AsCurrency));
  finally
    Query.Free;
  end;
end;

end.
