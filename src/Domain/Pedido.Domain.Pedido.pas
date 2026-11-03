unit Pedido.Domain.Pedido;

{ Pedido: raiz do agregado. Tudo que muda os itens ou o total passa por aqui, e
  as regras (invariantes) ficam dentro do próprio agregado:
    - o total é SEMPRE a soma dos itens (nunca um valor guardado que possa ficar velho);
    - um pedido só pode ser gravado com cliente e com pelo menos um item;
    - índices de item inválidos são recusados. }

interface

uses
  System.Generics.Collections,
  Pedido.Domain.ObjetosValor,
  Pedido.Domain.PedidoItem;

type
  TPedido = class
  private
    FNumero: Integer;
    FDataEmissao: TDate;
    FCodigoCliente: Integer;
    FObservacao: string;
    FItens: TObjectList<TPedidoItem>;
    procedure ExigirIndiceValido(AIndice: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure InformarCliente(ACodigo: Integer);
    procedure RemoverCliente;
    procedure DefinirObservacao(const ATexto: string);

    function AdicionarItem(AItem: TPedidoItem): Integer;
    procedure AtualizarItem(AIndice: Integer; AItem: TPedidoItem);
    procedure RemoverItem(AIndice: Integer);

    // Soma dos totais dos itens, recalculada a cada chamada.
    function ValorTotal: TDinheiro;
    // Levanta EDominioErro se faltar cliente ou itens.
    procedure ValidarParaGravacao;

    // O número vem do banco (generator): é definido pelo repositório ao gravar ou carregar.
    property Numero: Integer read FNumero write FNumero;
    property DataEmissao: TDate read FDataEmissao write FDataEmissao;
    property CodigoCliente: Integer read FCodigoCliente;
    property Observacao: string read FObservacao;
    property Itens: TObjectList<TPedidoItem> read FItens;
  end;

const
  TAMANHO_MAXIMO_OBSERVACAO = 200;

implementation

uses
  System.SysUtils,
  Pedido.Domain.Erros;

constructor TPedido.Create;
begin
  inherited Create;
  FItens := TObjectList<TPedidoItem>.Create(True);
  FDataEmissao := Date;
end;

destructor TPedido.Destroy;
begin
  FItens.Free;
  inherited;
end;

procedure TPedido.InformarCliente(ACodigo: Integer);
begin
  if ACodigo <= 0 then
    raise EDominioErro.Create(ceSemCliente);
  FCodigoCliente := ACodigo;
end;

procedure TPedido.RemoverCliente;
begin
  FCodigoCliente := 0;
end;

procedure TPedido.DefinirObservacao(const ATexto: string);
begin
  if Length(Trim(ATexto)) > TAMANHO_MAXIMO_OBSERVACAO then
    raise EDominioErro.Create(ceObservacaoLonga, TAMANHO_MAXIMO_OBSERVACAO);
  FObservacao := Trim(ATexto);
end;

procedure TPedido.ExigirIndiceValido(AIndice: Integer);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
    raise EDominioErro.Create(ceItemInvalido, AIndice);
end;

function TPedido.AdicionarItem(AItem: TPedidoItem): Integer;
begin
  Result := FItens.Add(AItem);
end;

procedure TPedido.AtualizarItem(AIndice: Integer; AItem: TPedidoItem);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
  begin
    AItem.Free;
    raise EDominioErro.Create(ceItemInvalido, AIndice);
  end;
  // O setter de Items libera o objeto antigo (OwnsObjects = True).
  FItens[AIndice] := AItem;
end;

procedure TPedido.RemoverItem(AIndice: Integer);
begin
  ExigirIndiceValido(AIndice);
  FItens.Delete(AIndice);
end;

function TPedido.ValorTotal: TDinheiro;
var
  Item: TPedidoItem;
begin
  Result := TDinheiro.Zero;
  for Item in FItens do
    Result := Result.Somar(Item.VlrTotal);
end;

procedure TPedido.ValidarParaGravacao;
begin
  if FCodigoCliente <= 0 then
    raise EDominioErro.Create(ceSemCliente);
  if FItens.Count = 0 then
    raise EDominioErro.Create(ceSemItens);
end;

end.
