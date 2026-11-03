unit Pedido.Infra.Persistencia.Base;

{ Base dos repositórios FireDAC: guarda a conexão e cria queries parametrizadas.
  Todo SQL do sistema fica nos repositórios, sempre como constante SQL_* e
  sempre com parâmetros. }

interface

uses
  System.Classes,
  FireDAC.Comp.Client;

type
  TRepositorioFireDACBase = class(TInterfacedObject)
  protected
    FConexao: TFDConnection;
    // Cria uma query ligada à conexão. Quem chama deve liberar.
    function NovaQuery(const ASql: string): TFDQuery;
  public
    constructor Create(AConexao: TFDConnection);
  end;

implementation

constructor TRepositorioFireDACBase.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TRepositorioFireDACBase.NovaQuery(const ASql: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := FConexao;
    Result.SQL.Text := ASql;
  except
    Result.Free;
    raise;
  end;
end;

end.
