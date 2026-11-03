unit Pedido.Infra.Composicao;

{ Raiz de composição: o único lugar que sabe quais classes concretas ligam
  uma interface à outra (FireDAC -> repositórios -> casos de uso). O resto do
  sistema só conhece interfaces. Aqui também se escolhe quem escuta os
  eventos de domínio. }

interface

uses
  FireDAC.Comp.Client,
  Pedido.Application.Interfaces,
  Pedido.Domain.Eventos;

type
  TComposicaoSistema = class
  private
    FEventos: IPublicadorEventos;
    FCasosDeUso: TCasosDeUsoPedido;
  public
    constructor Create(AConexao: TFDConnection);
    property CasosDeUso: TCasosDeUsoPedido read FCasosDeUso;
    property Eventos: IPublicadorEventos read FEventos;
  end;

implementation

uses
  Pedido.Application.CasosDeUso,
  Pedido.Application.Eventos,
  Pedido.Domain.Repositorios,
  Pedido.Infra.AssinanteLog,
  Pedido.Infra.Persistencia.Cliente,
  Pedido.Infra.Persistencia.Pedido,
  Pedido.Infra.Persistencia.Produto;

constructor TComposicaoSistema.Create(AConexao: TFDConnection);
var
  Clientes: IClienteRepository;
  Produtos: IProdutoRepository;
  Pedidos: IPedidoRepository;
begin
  inherited Create;

  // Eventos de domínio: por enquanto só o registro no log escuta.
  FEventos := TPublicadorEventosEmMemoria.Create;
  FEventos.Assinar(TAssinanteLogEventos.Create);

  // Infraestrutura (adaptadores FireDAC)
  Clientes := TClienteRepositorioFireDAC.Create(AConexao);
  Produtos := TProdutoRepositorioFireDAC.Create(AConexao);
  Pedidos := TPedidoRepositorioFireDAC.Create(AConexao);

  // Casos de uso (aplicação)
  FCasosDeUso.ConsultarCliente := TConsultarClienteUseCase.Create(Clientes);
  FCasosDeUso.ConsultarProduto := TConsultarProdutoUseCase.Create(Produtos);
  FCasosDeUso.CriarItem := TCriarItemPedidoUseCase.Create(FCasosDeUso.ConsultarProduto);
  FCasosDeUso.Gravar := TGravarPedidoUseCase.Create(Pedidos, FCasosDeUso.ConsultarCliente, FEventos);
  FCasosDeUso.Carregar := TCarregarPedidoUseCase.Create(Pedidos);
  FCasosDeUso.Cancelar := TCancelarPedidoUseCase.Create(Pedidos, FEventos);
end;

end.
