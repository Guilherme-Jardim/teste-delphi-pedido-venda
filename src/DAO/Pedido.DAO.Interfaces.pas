unit Pedido.DAO.Interfaces;

{ Contratos de acesso a dados. Os controllers dependem destas interfaces e
  não das classes FireDAC, então dá para trocar o banco (ou usar DAOs falsos
  nos testes) sem mexer nas regras de negócio. }

interface

uses
  Pedido.Model.Cliente,
  Pedido.Model.Pedido,
  Pedido.Model.Produto;

type
  IClienteDAO = interface
    ['{4D0F4B8E-6A52-4F0C-9E3A-0B7A1C2D3E41}']
    // Devolve nil quando o cliente não existe. Quem chama é dono do objeto.
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

  IProdutoDAO = interface
    ['{8A3C5D17-2B94-4E6F-A1D0-5C9E7F8B2A63}']
    // Devolve nil quando o produto não existe. Quem chama é dono do objeto.
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

  IPedidoDAO = interface
    ['{C1E7A9B4-3D58-4F21-8B6C-9A4D2E0F7135}']
    // Grava cabeçalho e itens na mesma transação (commit ou rollback).
    // Em pedido novo (Numero = 0) o número vem do generator.
    procedure Gravar(APedido: TPedidoModel);
    // Devolve nil quando o pedido não existe. Quem chama é dono do objeto.
    function GetPedido(ANumero: Integer): TPedidoModel;
    // Exclui o pedido e seus itens na mesma transação.
    procedure Excluir(ANumero: Integer);
  end;

implementation

end.
