unit Pedido.Application.Interfaces;

{ Portas de entrada da aplicação: um caso de uso por ação que a pessoa faz.
  A apresentação (telas) só conhece estas interfaces e o domínio; não sabe de
  banco, FireDAC nem de onde vêm os dados. }

interface

uses
  Pedido.Domain.Cliente,
  Pedido.Domain.Pedido,
  Pedido.Domain.PedidoItem,
  Pedido.Domain.Produto;

type
  IConsultarClienteUseCase = interface
    ['{2F6B1C84-9D37-4A05-B8E2-7C3A5D1F9E60}']
    // Levanta EDominioErro (ceClienteNaoEncontrado) se o código não existir.
    // O objeto retornado pertence a quem chamou.
    function Executar(ACodigo: Integer): TCliente;
  end;

  IConsultarProdutoUseCase = interface
    ['{7E2D9A41-5C68-4B13-9F0A-3D8B6E1C4A72}']
    // Levanta EDominioErro (ceProdutoNaoEncontrado) se o código não existir.
    function Executar(ACodigo: Integer): TProduto;
  end;

  ICriarItemPedidoUseCase = interface
    ['{91C5E3A8-0D47-4B2F-8A16-6F3E9D1B7C05}']
    // Monta o item a partir do cadastro do produto (a descrição vem do repositório)
    // e valida quantidade e valor pelos objetos de valor do domínio.
    function Executar(ACodigoProduto: Integer; AQuantidade: Double;
      AVlrUnitario: Currency): TPedidoItem;
  end;

  IGravarPedidoUseCase = interface
    ['{B5A83E19-6F42-4D70-A3C1-8E9D2F4B0C56}']
    // Valida o agregado, confere o cliente e grava. Publica PedidoGravado.
    procedure Executar(APedido: TPedido);
  end;

  ICarregarPedidoUseCase = interface
    ['{E8D14B63-9A27-4C50-B3F8-2A7C5E1D9B04}']
    // Levanta EDominioErro (cePedidoNaoEncontrado) se o número não existir.
    function Executar(ANumero: Integer): TPedido;
  end;

  ICancelarPedidoUseCase = interface
    ['{3A9F6D25-1C84-4E07-A5B2-7D0E8F4C1B96}']
    // Exclui o pedido e seus itens e publica PedidoCancelado.
    procedure Executar(ANumero: Integer);
  end;

  // Todos os casos de uso reunidos, para entregar à apresentação de uma vez.
  TCasosDeUsoPedido = record
    ConsultarCliente: IConsultarClienteUseCase;
    ConsultarProduto: IConsultarProdutoUseCase;
    CriarItem: ICriarItemPedidoUseCase;
    Gravar: IGravarPedidoUseCase;
    Carregar: ICarregarPedidoUseCase;
    Cancelar: ICancelarPedidoUseCase;
  end;

implementation

end.
