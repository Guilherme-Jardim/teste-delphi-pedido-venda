unit Pedido.Controller.Produto;

interface

uses
  FireDAC.Comp.Client,
  Pedido.DAO.Produto,
  Pedido.Model.Produto;

type
  TProdutoController = class
  private
    FProdutoDAO: TProdutoDAO;
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    // Levanta EProdutoNaoEncontrado se o código não existir.
    // O objeto retornado pertence a quem chamou.
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

implementation

uses
  Pedido.Model.Excecoes;

constructor TProdutoController.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FProdutoDAO := TProdutoDAO.Create(AConexao);
end;

destructor TProdutoController.Destroy;
begin
  FProdutoDAO.Free;
  inherited;
end;

function TProdutoController.GetProduto(ACodigo: Integer): TProdutoModel;
begin
  Result := FProdutoDAO.GetProduto(ACodigo);
  if Result = nil then
    raise EProdutoNaoEncontrado.Create(ACodigo);
end;

end.
