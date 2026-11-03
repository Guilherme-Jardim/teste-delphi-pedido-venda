unit Pedido.Domain.Erros;

{ Erros do domínio. Cada erro tem um CÓDIGO (e, quando faz sentido, um número,
  como o código do cliente que não foi encontrado). Não há texto traduzido aqui:
  o domínio não conhece idiomas nem telas. Quem mostra a mensagem (a camada de
  apresentação) traduz o código para o idioma escolhido. }

interface

uses
  System.SysUtils;

type
  TCodigoErro = (
    ceClienteNaoEncontrado,
    ceProdutoNaoEncontrado,
    cePedidoNaoEncontrado,
    ceSemCliente,
    ceSemItens,
    ceCodigoProdutoInvalido,
    ceQuantidadeInvalida,
    ceQuantidadeAcimaDoLimite,
    ceValorNegativo,
    ceValorAcimaDoLimite,
    ceNumeroPedidoInvalido,
    ceItemInvalido,
    ceObservacaoLonga,
    ceFalhaAoGravar,
    ceFalhaAoCancelar);

  EDominioErro = class(Exception)
  private
    FCodigo: TCodigoErro;
    FValor: Integer;
  public
    constructor Create(ACodigo: TCodigoErro; AValor: Integer = 0);
    property Codigo: TCodigoErro read FCodigo;
    // Número relacionado ao erro (por exemplo, o código do cliente procurado).
    property Valor: Integer read FValor;
  end;

// Nome técnico do código (para logs e testes), por exemplo "ClienteNaoEncontrado".
function NomeDoCodigo(ACodigo: TCodigoErro): string;

implementation

uses
  System.TypInfo;

function NomeDoCodigo(ACodigo: TCodigoErro): string;
begin
  Result := Copy(GetEnumName(TypeInfo(TCodigoErro), Ord(ACodigo)), 3, MaxInt);
end;

constructor EDominioErro.Create(ACodigo: TCodigoErro; AValor: Integer);
begin
  inherited Create(Format('%s (%d)', [NomeDoCodigo(ACodigo), AValor]));
  FCodigo := ACodigo;
  FValor := AValor;
end;

end.
