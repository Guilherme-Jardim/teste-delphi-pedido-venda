unit Pedido.Domain.Repositorios;

{ Contratos de persistência do domínio. Quem implementa (FireDAC, memória,
  outro banco) fica na camada de infraestrutura; o domínio e os casos de uso só
  conhecem estas interfaces. }

interface

uses
  Pedido.Domain.Cliente,
  Pedido.Domain.Pedido,
  Pedido.Domain.Produto;

type
  IClienteRepository = interface
    ['{4D0F4B8E-6A52-4F0C-9E3A-0B7A1C2D3E41}']
    // Devolve nil quando o cliente não existe. Quem chama é dono do objeto.
    function ObterPorCodigo(ACodigo: Integer): TCliente;
  end;

  IProdutoRepository = interface
    ['{8A3C5D17-2B94-4E6F-A1D0-5C9E7F8B2A63}']
    // Devolve nil quando o produto não existe. Quem chama é dono do objeto.
    function ObterPorCodigo(ACodigo: Integer): TProduto;
  end;

  // Repositório do agregado Pedido: sempre grava e carrega o pedido inteiro (cabeçalho + itens).
  IPedidoRepository = interface
    ['{C1E7A9B4-3D58-4F21-8B6C-9A4D2E0F7135}']
    // Grava o pedido todo na mesma transação (commit ou rollback).
    // Em pedido novo (Numero = 0) o número vem do generator e é definido no próprio pedido.
    procedure Salvar(APedido: TPedido);
    // Devolve nil quando o pedido não existe. Quem chama é dono do objeto.
    function ObterPorNumero(ANumero: Integer): TPedido;
    // Exclui o pedido e seus itens na mesma transação.
    procedure Excluir(ANumero: Integer);
  end;

implementation

end.
