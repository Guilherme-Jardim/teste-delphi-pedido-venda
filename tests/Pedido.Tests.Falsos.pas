unit Pedido.Tests.Falsos;

{ DAOs falsos, em memória, usados nos testes dos controllers. Como os
  controllers dependem só das interfaces, não precisam de banco nenhum. }

interface

uses
  System.Generics.Collections,
  Pedido.DAO.Interfaces,
  Pedido.Model.Cliente,
  Pedido.Model.Pedido,
  Pedido.Model.Produto;

type
  TClienteDAOFalso = class(TInterfacedObject, IClienteDAO)
  private
    FClientes: TObjectDictionary<Integer, TClienteModel>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Adicionar(ACodigo: Integer; const ANome, ACidade, AUF: string);
    function GetCliente(ACodigo: Integer): TClienteModel;
  end;

  TProdutoDAOFalso = class(TInterfacedObject, IProdutoDAO)
  private
    FProdutos: TObjectDictionary<Integer, TProdutoModel>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Adicionar(ACodigo: Integer; const ADescricao: string; APreco: Currency);
    function GetProduto(ACodigo: Integer): TProdutoModel;
  end;

  TPedidoDAOFalso = class(TInterfacedObject, IPedidoDAO)
  private
    FPedidos: TObjectDictionary<Integer, TPedidoModel>;
    FProximoNumero: Integer;
    FGravacoes: Integer;
    FExclusoes: Integer;
    function Copiar(AOrigem: TPedidoModel): TPedidoModel;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Gravar(APedido: TPedidoModel);
    function GetPedido(ANumero: Integer): TPedidoModel;
    procedure Excluir(ANumero: Integer);
    property Gravacoes: Integer read FGravacoes;
    property Exclusoes: Integer read FExclusoes;
  end;

implementation

uses
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem;

{ TClienteDAOFalso }

constructor TClienteDAOFalso.Create;
begin
  inherited Create;
  FClientes := TObjectDictionary<Integer, TClienteModel>.Create([doOwnsValues]);
end;

destructor TClienteDAOFalso.Destroy;
begin
  FClientes.Free;
  inherited;
end;

procedure TClienteDAOFalso.Adicionar(ACodigo: Integer; const ANome, ACidade, AUF: string);
begin
  FClientes.AddOrSetValue(ACodigo, TClienteModel.Create(ACodigo, ANome, ACidade, AUF));
end;

function TClienteDAOFalso.GetCliente(ACodigo: Integer): TClienteModel;
var
  Existente: TClienteModel;
begin
  Result := nil;
  if FClientes.TryGetValue(ACodigo, Existente) then
    Result := TClienteModel.Create(Existente.Codigo, Existente.Nome, Existente.Cidade, Existente.UF);
end;

{ TProdutoDAOFalso }

constructor TProdutoDAOFalso.Create;
begin
  inherited Create;
  FProdutos := TObjectDictionary<Integer, TProdutoModel>.Create([doOwnsValues]);
end;

destructor TProdutoDAOFalso.Destroy;
begin
  FProdutos.Free;
  inherited;
end;

procedure TProdutoDAOFalso.Adicionar(ACodigo: Integer; const ADescricao: string;
  APreco: Currency);
begin
  FProdutos.AddOrSetValue(ACodigo, TProdutoModel.Create(ACodigo, ADescricao, APreco));
end;

function TProdutoDAOFalso.GetProduto(ACodigo: Integer): TProdutoModel;
var
  Existente: TProdutoModel;
begin
  Result := nil;
  if FProdutos.TryGetValue(ACodigo, Existente) then
    Result := TProdutoModel.Create(Existente.Codigo, Existente.Descricao, Existente.PrecoVenda);
end;

{ TPedidoDAOFalso }

constructor TPedidoDAOFalso.Create;
begin
  inherited Create;
  FPedidos := TObjectDictionary<Integer, TPedidoModel>.Create([doOwnsValues]);
  FProximoNumero := 1;
end;

destructor TPedidoDAOFalso.Destroy;
begin
  FPedidos.Free;
  inherited;
end;

function TPedidoDAOFalso.Copiar(AOrigem: TPedidoModel): TPedidoModel;
var
  Item: TPedidoItemModel;
begin
  Result := TPedidoModel.Create;
  Result.Numero := AOrigem.Numero;
  Result.DataEmissao := AOrigem.DataEmissao;
  Result.CodigoCliente := AOrigem.CodigoCliente;
  Result.Observacao := AOrigem.Observacao;
  for Item in AOrigem.Itens do
    Result.AdicionarItem(Item.Clonar);
end;

procedure TPedidoDAOFalso.Gravar(APedido: TPedidoModel);
begin
  if APedido.Numero = 0 then
  begin
    APedido.Numero := FProximoNumero;
    Inc(FProximoNumero);
  end;
  FPedidos.AddOrSetValue(APedido.Numero, Copiar(APedido));
  Inc(FGravacoes);
end;

function TPedidoDAOFalso.GetPedido(ANumero: Integer): TPedidoModel;
var
  Existente: TPedidoModel;
begin
  Result := nil;
  if FPedidos.TryGetValue(ANumero, Existente) then
    Result := Copiar(Existente);
end;

procedure TPedidoDAOFalso.Excluir(ANumero: Integer);
begin
  if not FPedidos.ContainsKey(ANumero) then
    raise EPedidoNaoEncontrado.Create(ANumero);
  FPedidos.Remove(ANumero);
  Inc(FExclusoes);
end;

end.
