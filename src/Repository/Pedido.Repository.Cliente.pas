unit Pedido.Repository.Cliente;

interface

uses
  Pedido.Model.Cliente,
  Pedido.Repository.Base,
  Pedido.Repository.Interfaces;

type
  TClienteRepository = class(TRepositorioBase, IClienteRepository)
  public
    function BuscarPorCodigo(ACodigo: Integer): TCliente;
  end;

implementation

uses
  FireDAC.Comp.Client;

const
  SQL_POR_CODIGO =
    'SELECT CODIGO, NOME, CIDADE, UF FROM CLIENTE WHERE CODIGO = :CODIGO';

function TClienteRepository.BuscarPorCodigo(ACodigo: Integer): TCliente;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := NovaQuery(SQL_POR_CODIGO);
  try
    Query.ParamByName('CODIGO').AsInteger := ACodigo;
    Query.Open;
    if not Query.IsEmpty then
      Result := TCliente.Create(
        Query.FieldByName('CODIGO').AsInteger,
        Query.FieldByName('NOME').AsString,
        Query.FieldByName('CIDADE').AsString,
        Query.FieldByName('UF').AsString);
  finally
    Query.Free;
  end;
end;

end.
