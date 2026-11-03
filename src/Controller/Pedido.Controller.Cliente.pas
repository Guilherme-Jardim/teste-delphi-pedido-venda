unit Pedido.Controller.Cliente;

interface

uses
  FireDAC.Comp.Client,
  Pedido.DAO.Cliente,
  Pedido.Model.Cliente;

type
  TClienteController = class
  private
    FClienteDAO: TClienteDAO;
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    // Levanta EClienteNaoEncontrado se o código não existir.
    // O objeto retornado pertence a quem chamou.
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TClienteController.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FClienteDAO := TClienteDAO.Create(AConexao);
end;

destructor TClienteController.Destroy;
begin
  FClienteDAO.Free;
  inherited;
end;

function TClienteController.GetCliente(ACodigo: Integer): TClienteModel;
begin
  Result := FClienteDAO.GetCliente(ACodigo);
  if Result = nil then
    raise EClienteNaoEncontrado.Create(ACodigo);
end;

end.
