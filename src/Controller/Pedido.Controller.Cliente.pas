unit Pedido.Controller.Cliente;

interface

uses
  Pedido.Controller.Interfaces,
  Pedido.DAO.Interfaces,
  Pedido.Model.Cliente;

type
  TClienteController = class(TInterfacedObject, IClienteController)
  private
    FClienteDAO: IClienteDAO;
  public
    constructor Create(const AClienteDAO: IClienteDAO);
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TClienteController.Create(const AClienteDAO: IClienteDAO);
begin
  inherited Create;
  FClienteDAO := AClienteDAO;
end;

function TClienteController.GetCliente(ACodigo: Integer): TClienteModel;
begin
  Result := FClienteDAO.GetCliente(ACodigo);
  if Result = nil then
    raise EClienteNaoEncontrado.Create(ACodigo);
end;

end.
