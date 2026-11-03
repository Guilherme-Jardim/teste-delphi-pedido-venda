unit Pedido.Infra.Composicao;

{ Raiz de composição: o único lugar que sabe quais classes concretas ligam
  uma interface à outra (FireDAC -> DAOs -> controllers). O resto do sistema só
  conhece interfaces. }

interface

uses
  FireDAC.Comp.Client,
  Pedido.Controller.Interfaces;

type
  TComposicaoSistema = class
  private
    FPedidos: IPedidoController;
    FClientes: IClienteController;
    FProdutos: IProdutoController;
  public
    constructor Create(AConexao: TFDConnection);
    property Pedidos: IPedidoController read FPedidos;
    property Clientes: IClienteController read FClientes;
    property Produtos: IProdutoController read FProdutos;
  end;

implementation

uses
  Pedido.Controller.Cliente,
  Pedido.Controller.Pedido,
  Pedido.Controller.Produto,
  Pedido.DAO.Cliente,
  Pedido.DAO.Pedido,
  Pedido.DAO.Produto;

constructor TComposicaoSistema.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FClientes := TClienteController.Create(TClienteDAO.Create(AConexao));
  FProdutos := TProdutoController.Create(TProdutoDAO.Create(AConexao));
  FPedidos := TPedidoController.Create(TPedidoDAO.Create(AConexao), FClientes, FProdutos);
end;

end.
