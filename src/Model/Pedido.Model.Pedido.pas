unit Pedido.Model.Pedido;

interface

uses
  System.Generics.Collections,
  Pedido.Model.PedidoItem;

type
  TPedidoModel = class
  private
    FNumero: Integer;
    FDataEmissao: TDate;
    FCodigoCliente: Integer;
    FObservacao: string;
    FItens: TObjectList<TPedidoItemModel>;
    function GetValorTotal: Currency;
  public
    constructor Create;
    destructor Destroy; override;

    function AdicionarItem(AItem: TPedidoItemModel): Integer;
    procedure AtualizarItem(AIndice: Integer; AItem: TPedidoItemModel);
    procedure RemoverItem(AIndice: Integer);

    property Numero: Integer read FNumero write FNumero;
    property DataEmissao: TDate read FDataEmissao write FDataEmissao;
    property CodigoCliente: Integer read FCodigoCliente write FCodigoCliente;
    property Observacao: string read FObservacao write FObservacao;
    property Itens: TObjectList<TPedidoItemModel> read FItens;
    // Sempre calculado a partir dos itens: não existe total "guardado"
    // que possa ficar desatualizado depois de uma exclusão.
    property ValorTotal: Currency read GetValorTotal;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Idioma,
  Pedido.Model.Excecoes;

constructor TPedidoModel.Create;
begin
  inherited Create;
  FItens := TObjectList<TPedidoItemModel>.Create(True);
  FDataEmissao := Date;
end;

destructor TPedidoModel.Destroy;
begin
  FItens.Free;
  inherited;
end;

function TPedidoModel.AdicionarItem(AItem: TPedidoItemModel): Integer;
begin
  Result := FItens.Add(AItem);
end;

procedure TPedidoModel.AtualizarItem(AIndice: Integer; AItem: TPedidoItemModel);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
  begin
    AItem.Free;
    raise EValidacao.Create(Tr('msg.selecione_item'));
  end;
  // O setter de Items libera o objeto antigo (OwnsObjects = True).
  FItens[AIndice] := AItem;
end;

procedure TPedidoModel.RemoverItem(AIndice: Integer);
begin
  if (AIndice < 0) or (AIndice >= FItens.Count) then
    raise EValidacao.Create(Tr('msg.selecione_item'));
  FItens.Delete(AIndice);
end;

function TPedidoModel.GetValorTotal: Currency;
var
  Item: TPedidoItemModel;
begin
  Result := 0;
  for Item in FItens do
    Result := Result + Item.VlrTotal;
end;

end.
