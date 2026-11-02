unit Pedido.Repository.Interfaces;

interface

uses
  Pedido.Model.Cliente,
  Pedido.Model.Produto,
  Pedido.Model.Pedido;

type
  IClienteRepository = interface
    ['{F2085D37-875C-46A6-B1F4-7421C7490684}']
    // Devolve nil quando não existe. Quem chama é dono do objeto retornado.
    function BuscarPorCodigo(ACodigo: Integer): TCliente;
  end;

  IProdutoRepository = interface
    ['{6313C267-EA8B-4BB7-8298-7FBAAA1F16FA}']
    function BuscarPorCodigo(ACodigo: Integer): TProduto;
  end;

  IPedidoRepository = interface
    ['{84A283C0-6091-47C9-9B1F-F223F138621C}']
    // Grava cabeçalho e itens na mesma transação. Em pedido novo
    // (Numero = 0) o número vem do generator e é devolvido em APedido.
    procedure Gravar(APedido: TPedido);
    function BuscarPorNumero(ANumero: Integer): TPedido;
    procedure Excluir(ANumero: Integer);
  end;

implementation

end.
