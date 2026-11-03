unit Pedido.Infra.Persistencia.Cliente;

interface

uses
  Pedido.Domain.Cliente,
  Pedido.Domain.Repositorios,
  Pedido.Infra.Persistencia.Base;

type
  TClienteRepositorioFireDAC = class(TRepositorioFireDACBase, IClienteRepository)
  public
    function ObterPorCodigo(ACodigo: Integer): TCliente;
  end;

implementation

uses
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client;

const
  SQL_POR_CODIGO =
    'SELECT CODIGO, NOME, CIDADE, UF FROM CLIENTE WHERE CODIGO = :CODIGO';

function TClienteRepositorioFireDAC.ObterPorCodigo(ACodigo: Integer): TCliente;
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
