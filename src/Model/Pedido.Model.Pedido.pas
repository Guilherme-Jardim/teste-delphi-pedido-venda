unit Pedido.Model.Pedido;

interface

uses
  System.Generics.Collections,
  Pedido.Model.PedidoItem;

type
  TPedido = class
  private
    FNumero: Integer;
    FDataEmissao: TDate;
    FCodigoCliente: Integer;
    FItens: TObjectList<TPedidoItem>;
    function GetValorTotal: Currency;
  public
    constructor Create;
    destructor Destroy; override;

    function AdicionarItem(AItem: TPedidoItem): Integer;
    procedure AtualizarItem(AIndice: Integer; AItem: TPedidoItem);
    procedure RemoverItem(AIndice: Integer);

    property Numero: Integer read FNumero write FNumero;
    property DataEmissao: TDate read FDataEmissao write FDataEmissao;
    property CodigoCliente: Integer read FCodigoCliente write FCodigoCliente;
    property Itens: TObjectList<TPedidoItem> read FItens;
    // Sempre calculado a partir dos itens: não existe total "guardado"
    // que possa ficar desatualizado depois de uma exclusão.
    property ValorTotal: Currency read GetValorTotal;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Model.Excecoes;

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

function TPedido.AdicionarItem(AItem: TPedidoItem): Integer;
begin
  Result := FItens.Add(AItem);
end;

procedure TPedido.AtualizarItem(AIndice: Integer; AItem: TPedidoItem);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
  begin
    AItem.Free;
    raise EValidacao.Create('Item inválido para atualização.');
  end;
  // O setter de Items libera o objeto antigo (OwnsObjects = True).
  FItens[AIndice] := AItem;
end;

procedure TPedido.RemoverItem(AIndice: Integer);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
    raise EValidacao.Create('Item inválido para exclusão.');
  FItens.Delete(AIndice);
end;

function TPedido.GetValorTotal: Currency;
var
  Item: TPedidoItem;
begin
  Result := 0;
  for Item in FItens do
    Result := Result + Item.VlrTotal;
end;

end.
