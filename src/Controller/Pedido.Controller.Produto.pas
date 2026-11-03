unit Pedido.Controller.Produto;

interface

uses
  Pedido.Controller.Interfaces,
  Pedido.DAO.Interfaces,
  Pedido.Model.Produto;

type
  TProdutoController = class(TInterfacedObject, IProdutoController)
  private
    FProdutoDAO: IProdutoDAO;
  public
    constructor Create(const AProdutoDAO: IProdutoDAO);
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TProdutoController.Create(const AProdutoDAO: IProdutoDAO);
begin
  inherited Create;
  FProdutoDAO := AProdutoDAO;
end;

function TProdutoController.GetProduto(ACodigo: Integer): TProdutoModel;
begin
  Result := FProdutoDAO.GetProduto(ACodigo);
  if Result = nil then
    raise EProdutoNaoEncontrado.Create(ACodigo);
end;

end.
