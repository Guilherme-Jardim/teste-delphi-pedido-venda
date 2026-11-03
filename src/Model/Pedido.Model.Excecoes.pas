unit Pedido.Model.Excecoes;

interface

uses
  System.SysUtils;

type
  EPedidoErro = class(Exception);

  EValidacao = class(EPedidoErro);

  EPersistencia = class(EPedidoErro);

  EClienteNaoEncontrado = class(EPedidoErro)
  public
    constructor Create(ACodigo: Integer); reintroduce;
  end;

  EProdutoNaoEncontrado = class(EPedidoErro)
  public
    constructor Create(ACodigo: Integer); reintroduce;
  end;

  EPedidoNaoEncontrado = class(EPedidoErro)
  public
    constructor Create(ANumero: Integer); reintroduce;
  end;

implementation

uses
  Pedido.Infra.Idioma;

{ EClienteNaoEncontrado }

constructor EClienteNaoEncontrado.Create(ACodigo: Integer);
begin
  inherited Create(Tr('msg.cliente_nao_encontrado', [ACodigo]));
end;

{ EProdutoNaoEncontrado }

constructor EProdutoNaoEncontrado.Create(ACodigo: Integer);
begin
  inherited Create(Tr('msg.produto_nao_encontrado', [ACodigo]));
end;

{ EPedidoNaoEncontrado }

constructor EPedidoNaoEncontrado.Create(ANumero: Integer);
begin
  inherited Create(Tr('msg.pedido_nao_encontrado', [ANumero]));
end;

end.
