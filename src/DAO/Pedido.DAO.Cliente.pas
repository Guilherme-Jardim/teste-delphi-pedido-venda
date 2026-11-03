unit Pedido.DAO.Cliente;

interface

uses
  Pedido.DAO.Base,
  Pedido.DAO.Interfaces,
  Pedido.Model.Cliente;

type
  TClienteDAO = class(TDAOBase, IClienteDAO)
  public
    // Devolve nil quando o cliente não existe. Quem chama é dono do objeto.
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

implementation

uses
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client;

const
  SQL_POR_CODIGO =
    'SELECT CODIGO, NOME, CIDADE, UF FROM CLIENTE WHERE CODIGO = :CODIGO';

function TClienteDAO.GetCliente(ACodigo: Integer): TClienteModel;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := NovaQuery(SQL_POR_CODIGO);
  try
    Query.ParamByName('CODIGO').AsInteger := ACodigo;
    Query.Open;
    if not Query.IsEmpty then
      Result := TClienteModel.Create(
        Query.FieldByName('CODIGO').AsInteger,
        Query.FieldByName('NOME').AsString,
        Query.FieldByName('CIDADE').AsString,
        Query.FieldByName('UF').AsString);
  finally
    Query.Free;
  end;
end;

end.
