unit Pedido.DAO.Produto;

interface

uses
  Pedido.DAO.Base,
  Pedido.DAO.Interfaces,
  Pedido.Model.Produto;

type
  TProdutoDAO = class(TDAOBase, IProdutoDAO)
  public
    // Devolve nil quando o produto não existe. Quem chama é dono do objeto.
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

implementation

uses
  FireDAC.Comp.Client;

const
  SQL_POR_CODIGO =
    'SELECT CODIGO, DESCRICAO, PRECO_VENDA FROM PRODUTO WHERE CODIGO = :CODIGO';

function TProdutoDAO.GetProduto(ACodigo: Integer): TProdutoModel;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := NovaQuery(SQL_POR_CODIGO);
  try
    Query.ParamByName('CODIGO').AsInteger := ACodigo;
    Query.Open;
    if not Query.IsEmpty then
      Result := TProdutoModel.Create(
        Query.FieldByName('CODIGO').AsInteger,
        Query.FieldByName('DESCRICAO').AsString,
        Query.FieldByName('PRECO_VENDA').AsCurrency);
  finally
    Query.Free;
  end;
end;

end.
