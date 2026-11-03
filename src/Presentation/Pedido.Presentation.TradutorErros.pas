unit Pedido.Presentation.TradutorErros;

{ Traduz os erros de domínio (que só têm código) para o texto no idioma
  escolhido. Fica na apresentação porque é ela que conhece a pessoa e o idioma. }

interface

uses
  Pedido.Domain.Erros;

function MensagemDoErro(E: EDominioErro): string;
// Chave da tabela de idiomas usada para cada código de erro.
function ChaveDoErro(ACodigo: TCodigoErro): string;

implementation

uses
  Pedido.Infra.Idioma;

function ChaveDoErro(ACodigo: TCodigoErro): string;
begin
  case ACodigo of
    ceClienteNaoEncontrado: Result := 'msg.cliente_nao_encontrado';
    ceProdutoNaoEncontrado: Result := 'msg.produto_nao_encontrado';
    cePedidoNaoEncontrado: Result := 'msg.pedido_nao_encontrado';
    ceSemCliente: Result := 'msg.sem_cliente';
    ceSemItens: Result := 'msg.sem_itens';
    ceCodigoProdutoInvalido: Result := 'msg.produto_codigo';
    ceQuantidadeInvalida: Result := 'msg.qtd_maior_zero';
    ceQuantidadeAcimaDoLimite: Result := 'msg.qtd_limite';
    ceValorNegativo: Result := 'msg.vlr_negativo';
    ceValorAcimaDoLimite: Result := 'msg.vlr_limite';
    ceNumeroPedidoInvalido: Result := 'msg.numero_invalido';
    ceItemInvalido: Result := 'msg.selecione_item';
    ceObservacaoLonga: Result := 'msg.obs_longa';
    ceFalhaAoGravar: Result := 'msg.falha_gravar';
    ceFalhaAoCancelar: Result := 'msg.falha_cancelar';
  else
    Result := 'msg.erro_inesperado';
  end;
end;

function MensagemDoErro(E: EDominioErro): string;
begin
  case E.Codigo of
    ceClienteNaoEncontrado, ceProdutoNaoEncontrado, cePedidoNaoEncontrado, ceObservacaoLonga:
      Result := Tr(ChaveDoErro(E.Codigo), [E.Valor]);
  else
    Result := Tr(ChaveDoErro(E.Codigo));
  end;
end;

end.
