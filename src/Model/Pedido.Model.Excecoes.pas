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

{ EClienteNaoEncontrado }

constructor EClienteNaoEncontrado.Create(ACodigo: Integer);
begin
  inherited CreateFmt('Cliente %d não encontrado.', [ACodigo]);
end;

{ EProdutoNaoEncontrado }

constructor EProdutoNaoEncontrado.Create(ACodigo: Integer);
begin
  inherited CreateFmt('Produto %d não encontrado.', [ACodigo]);
end;

{ EPedidoNaoEncontrado }

constructor EPedidoNaoEncontrado.Create(ANumero: Integer);
begin
  inherited CreateFmt('Pedido %d não encontrado.', [ANumero]);
end;

end.
