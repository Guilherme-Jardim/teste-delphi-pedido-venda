unit Pedido.Repository.Base;

interface

uses
  System.Classes,
  FireDAC.Comp.Client;

type
  TRepositorioBase = class(TInterfacedObject)
  protected
    FConexao: TFDConnection;
    // Cria uma query já ligada à conexão. Quem chama deve liberar.
    function NovaQuery(const ASql: string): TFDQuery;
  public
    constructor Create(AConexao: TFDConnection);
  end;

implementation

constructor TRepositorioBase.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TRepositorioBase.NovaQuery(const ASql: string): TFDQuery;
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
