unit Pedido.DAO.Base;

{ Base dos DAOs: guarda a conexão e cria queries parametrizadas.
  Todo SQL do sistema fica nos DAOs. }

interface

uses
  FireDAC.Comp.Client;

type
  TDAOBase = class
  protected
    FConexao: TFDConnection;
    // Cria uma query ligada à conexão. Quem chama deve liberar.
    function NovaQuery(const ASql: string): TFDQuery;
  public
    constructor Create(AConexao: TFDConnection);
  end;

implementation

constructor TDAOBase.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TDAOBase.NovaQuery(const ASql: string): TFDQuery;
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
