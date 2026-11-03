unit Pedido.Tests.Falsos;

{ Repositórios falsos, em memória, usados nos testes dos casos de uso. Como os
  casos de uso dependem só das interfaces do domínio, não precisam de banco. }

interface

uses
  System.Generics.Collections,
  Pedido.Domain.Cliente,
  Pedido.Domain.Eventos,
  Pedido.Domain.Pedido,
  Pedido.Domain.Produto,
  Pedido.Domain.Repositorios;

type
  TClienteRepositorioFalso = class(TInterfacedObject, IClienteRepository)
  private
    FClientes: TObjectDictionary<Integer, TCliente>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Adicionar(ACodigo: Integer; const ANome, ACidade, AUF: string);
    function ObterPorCodigo(ACodigo: Integer): TCliente;
  end;

  TProdutoRepositorioFalso = class(TInterfacedObject, IProdutoRepository)
  private
    FProdutos: TObjectDictionary<Integer, TProduto>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Adicionar(ACodigo: Integer; const ADescricao: string; APreco: Currency);
    function ObterPorCodigo(ACodigo: Integer): TProduto;
  end;

  TPedidoRepositorioFalso = class(TInterfacedObject, IPedidoRepository)
  private
    FPedidos: TObjectDictionary<Integer, TPedido>;
    FProximoNumero: Integer;
    FGravacoes: Integer;
    FExclusoes: Integer;
    function Copiar(AOrigem: TPedido): TPedido;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Salvar(APedido: TPedido);
    function ObterPorNumero(ANumero: Integer): TPedido;
    procedure Excluir(ANumero: Integer);
    property Gravacoes: Integer read FGravacoes;
    property Exclusoes: Integer read FExclusoes;
  end;

  // Assinante que só guarda o que recebeu, para os testes conferirem os eventos.
  TAssinanteGravador = class(TInterfacedObject, IAssinanteEventos)
  private
    FNomes: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Tratar(const AEvento: IEventoDominio);
    property Nomes: TList<string> read FNomes;
  end;

  // Assinante que sempre falha: o publicador não pode se abalar com isso.
  TAssinanteQuebrado = class(TInterfacedObject, IAssinanteEventos)
  public
    procedure Tratar(const AEvento: IEventoDominio);
  end;

implementation

uses
  System.SysUtils,
  Pedido.Domain.Erros,
  Pedido.Domain.ObjetosValor,
  Pedido.Domain.PedidoItem;

{ TClienteRepositorioFalso }

constructor TClienteRepositorioFalso.Create;
begin
  inherited Create;
  FClientes := TObjectDictionary<Integer, TCliente>.Create([doOwnsValues]);
end;

destructor TClienteRepositorioFalso.Destroy;
begin
  FClientes.Free;
  inherited;
end;

procedure TClienteRepositorioFalso.Adicionar(ACodigo: Integer; const ANome, ACidade, AUF: string);
begin
  FClientes.AddOrSetValue(ACodigo, TCliente.Create(ACodigo, ANome, ACidade, AUF));
end;

function TClienteRepositorioFalso.ObterPorCodigo(ACodigo: Integer): TCliente;
var
  Existente: TCliente;
begin
  Result := nil;
  if FClientes.TryGetValue(ACodigo, Existente) then
    Result := TCliente.Create(Existente.Codigo, Existente.Nome, Existente.Cidade, Existente.UF);
end;

{ TProdutoRepositorioFalso }

constructor TProdutoRepositorioFalso.Create;
begin
  inherited Create;
  FProdutos := TObjectDictionary<Integer, TProduto>.Create([doOwnsValues]);
end;

destructor TProdutoRepositorioFalso.Destroy;
begin
  FProdutos.Free;
  inherited;
end;

procedure TProdutoRepositorioFalso.Adicionar(ACodigo: Integer; const ADescricao: string;
  APreco: Currency);
begin
  FProdutos.AddOrSetValue(ACodigo, TProduto.Create(ACodigo, ADescricao, TDinheiro.Criar(APreco)));
end;

function TProdutoRepositorioFalso.ObterPorCodigo(ACodigo: Integer): TProduto;
var
  Existente: TProduto;
begin
  Result := nil;
  if FProdutos.TryGetValue(ACodigo, Existente) then
    Result := TProduto.Create(Existente.Codigo, Existente.Descricao, Existente.PrecoVenda);
end;

{ TPedidoRepositorioFalso }

constructor TPedidoRepositorioFalso.Create;
begin
  inherited Create;
  FPedidos := TObjectDictionary<Integer, TPedido>.Create([doOwnsValues]);
  FProximoNumero := 1;
end;

destructor TPedidoRepositorioFalso.Destroy;
begin
  FPedidos.Free;
  inherited;
end;

function TPedidoRepositorioFalso.Copiar(AOrigem: TPedido): TPedido;
var
  Item: TPedidoItem;
begin
  Result := TPedido.Create;
  Result.Numero := AOrigem.Numero;
  Result.DataEmissao := AOrigem.DataEmissao;
  if AOrigem.CodigoCliente > 0 then
    Result.InformarCliente(AOrigem.CodigoCliente);
  Result.DefinirObservacao(AOrigem.Observacao);
  for Item in AOrigem.Itens do
    Result.AdicionarItem(Item.Clonar);
end;

procedure TPedidoRepositorioFalso.Salvar(APedido: TPedido);
begin
  if APedido.Numero = 0 then
  begin
    APedido.Numero := FProximoNumero;
    Inc(FProximoNumero);
  end;
  FPedidos.AddOrSetValue(APedido.Numero, Copiar(APedido));
  Inc(FGravacoes);
end;

function TPedidoRepositorioFalso.ObterPorNumero(ANumero: Integer): TPedido;
var
  Existente: TPedido;
begin
  Result := nil;
  if FPedidos.TryGetValue(ANumero, Existente) then
    Result := Copiar(Existente);
end;

procedure TPedidoRepositorioFalso.Excluir(ANumero: Integer);
begin
  if not FPedidos.ContainsKey(ANumero) then
    raise EDominioErro.Create(cePedidoNaoEncontrado, ANumero);
  FPedidos.Remove(ANumero);
  Inc(FExclusoes);
end;

{ TAssinanteGravador }

constructor TAssinanteGravador.Create;
begin
  inherited Create;
  FNomes := TList<string>.Create;
end;

destructor TAssinanteGravador.Destroy;
begin
  FNomes.Free;
  inherited;
end;

procedure TAssinanteGravador.Tratar(const AEvento: IEventoDominio);
begin
  FNomes.Add(AEvento.Nome);
end;

{ TAssinanteQuebrado }

procedure TAssinanteQuebrado.Tratar(const AEvento: IEventoDominio);
begin
  raise Exception.Create('assinante com defeito');
end;

end.
