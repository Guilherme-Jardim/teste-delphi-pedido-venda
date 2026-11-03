unit Pedido.Controller.Interfaces;

{ Contratos usados pela tela. A View só conhece estas interfaces. }

interface

uses
  Pedido.Model.Cliente,
  Pedido.Model.Pedido,
  Pedido.Model.PedidoItem,
  Pedido.Model.Produto;

type
  IClienteController = interface
    ['{2F6B1C84-9D37-4A05-B8E2-7C3A5D1F9E60}']
    // Levanta EClienteNaoEncontrado se o código não existir.
    // O objeto retornado pertence a quem chamou.
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

  IProdutoController = interface
    ['{7E2D9A41-5C68-4B13-9F0A-3D8B6E1C4A72}']
    // Levanta EProdutoNaoEncontrado se o código não existir.
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

  IPedidoController = interface
    ['{B5A83E19-6F42-4D70-A3C1-8E9D2F4B0C56}']
    // Monta o item a partir do cadastro do produto (a descrição vem do banco).
    function CriarItem(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): TPedidoItemModel;
    procedure Gravar(APedido: TPedidoModel);
    // Levanta EPedidoNaoEncontrado se o número não existir.
    function GetPedido(ANumero: Integer): TPedidoModel;
    procedure Cancelar(ANumero: Integer);
  end;

implementation

end.
