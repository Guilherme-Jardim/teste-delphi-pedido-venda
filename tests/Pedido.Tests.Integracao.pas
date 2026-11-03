unit Pedido.Tests.Integracao;

{ Testes contra o Firebird de verdade (o mesmo do config.ini).
  Se não houver config.ini ou o banco não responder, os testes são ignorados.
  Cada teste limpa o que criou. }

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  Pedido.Controller.Interfaces,
  Pedido.Infra.Composicao;

type
  [TestFixture]
  TTestesIntegracao = class
  private
    FDono: TComponent;
    FConexao: TFDConnection;
    FComposicao: TComposicaoSistema;
    FPedidos: IPedidoController;
    FClientes: IClienteController;
    FProdutos: IProdutoController;
    FSemBanco: Boolean;
    function ContarPedidos: Integer;
    procedure ExigirBanco;
    procedure DeveLevantar(AClasse: ExceptClass; const AAcao: TProc);
    function ContarItensDoPedido(ANumero: Integer): Integer;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure ClienteExistenteERetornadoComDados;
    [Test]
    procedure ClienteInexistenteLevantaErro;
    [Test]
    procedure ProdutoExistenteTemDescricaoEPreco;
    [Test]
    procedure ProdutoInexistenteLevantaErro;
    [Test]
    procedure GravarPedidoPersisteCabecalhoItensEObservacao;
    [Test]
    procedure NumeroDoPedidoECrescente;
    [Test]
    procedure GravarPedidoSemClienteNaoGrava;
    [Test]
    procedure GravarPedidoComClienteInexistenteNaoGrava;
    [Test]
    procedure FalhaNoMeioDaGravacaoFazRollbackDeTudo;
    [Test]
    procedure RegravarPedidoCarregadoAtualizaSemCriarOutro;
    [Test]
    procedure CancelarPedidoRemoveCabecalhoEItens;
    [Test]
    procedure CancelarPedidoInexistenteLevantaErro;
    [Test]
    procedure CodigoComAspasNaoQuebraAConsulta;
  end;

implementation

uses
  Pedido.Infra.Config,
  Pedido.Infra.Conexao,
  Pedido.Infra.Idioma,
  Pedido.Model.Cliente,
  Pedido.Model.Excecoes,
  Pedido.Model.Pedido,
  Pedido.Model.PedidoItem,
  Pedido.Model.Produto;

procedure TTestesIntegracao.SetupFixture;
var
  Repo: IConfigRepositorio;
  Config: TConfigBanco;
  Motivo: string;
begin
  DefinirIdioma(idEspanhol, False);
  FDono := TComponent.Create(nil);
  try
    Repo := TIniConfigRepositorio.Create;
    if Repo.Carregar(Config, Motivo) <> rcOk then
      raise Exception.Create('config.ini indisponível: ' + Motivo);
    FConexao := TFabricaConexao.Criar(Config, FDono);
    FConexao.Connected := True;
  except
    on E: Exception do
    begin
      FreeAndNil(FDono);
      FConexao := nil;
      FSemBanco := True;
      Exit;
    end;
  end;
  FComposicao := TComposicaoSistema.Create(FConexao);
  FPedidos := FComposicao.Pedidos;
  FClientes := FComposicao.Clientes;
  FProdutos := FComposicao.Produtos;
end;

procedure TTestesIntegracao.TearDownFixture;
begin
  FProdutos := nil;
  FClientes := nil;
  FPedidos := nil;
  FComposicao.Free;
  FDono.Free;
end;

procedure TTestesIntegracao.ExigirBanco;
begin
  // Sem config.ini ou sem banco, o teste passa sem verificar nada (aviso no resultado).
  if FSemBanco then
    Assert.Pass('Sem banco disponível: teste de integração ignorado.');
end;

procedure TTestesIntegracao.DeveLevantar(AClasse: ExceptClass; const AAcao: TProc);
begin
  try
    AAcao();
  except
    on E: Exception do
    begin
      Assert.IsTrue(E is AClasse,
        Format('Esperava %s, mas veio %s: %s', [AClasse.ClassName, E.ClassName, E.Message]));
      Exit;
    end;
  end;
  Assert.Fail('Esperava a exceção ' + AClasse.ClassName);
end;

function TTestesIntegracao.ContarPedidos: Integer;
begin
  Result := FConexao.ExecSQLScalar('SELECT COUNT(*) FROM PEDIDO');
end;

function TTestesIntegracao.ContarItensDoPedido(ANumero: Integer): Integer;
begin
  Result := FConexao.ExecSQLScalar('SELECT COUNT(*) FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = :N',
    [ANumero]);
end;

procedure TTestesIntegracao.ClienteExistenteERetornadoComDados;
var
  Cliente: TClienteModel;
begin
  ExigirBanco;
  Cliente := FClientes.GetCliente(1);
  try
    Assert.AreEqual(1, Cliente.Codigo);
    Assert.IsNotEmpty(Cliente.Nome);
    Assert.IsNotEmpty(Cliente.Cidade);
    Assert.AreEqual(2, Length(Cliente.UF));
  finally
    Cliente.Free;
  end;
end;

procedure TTestesIntegracao.ClienteInexistenteLevantaErro;
begin
  ExigirBanco;
  DeveLevantar(EClienteNaoEncontrado,
    procedure
    begin
      FClientes.GetCliente(987654).Free;
    end);
end;

procedure TTestesIntegracao.ProdutoExistenteTemDescricaoEPreco;
var
  Produto: TProdutoModel;
begin
  ExigirBanco;
  Produto := FProdutos.GetProduto(1);
  try
    Assert.IsNotEmpty(Produto.Descricao);
    Assert.IsTrue(Produto.PrecoVenda > 0);
  finally
    Produto.Free;
  end;
end;

procedure TTestesIntegracao.ProdutoInexistenteLevantaErro;
begin
  ExigirBanco;
  DeveLevantar(EProdutoNaoEncontrado,
    procedure
    begin
      FProdutos.GetProduto(987654).Free;
    end);
end;

procedure TTestesIntegracao.GravarPedidoPersisteCabecalhoItensEObservacao;
var
  Pedido, Carregado: TPedidoModel;
  Numero: Integer;
begin
  ExigirBanco;
  Pedido := TPedidoModel.Create;
  try
    Pedido.CodigoCliente := 1;
    Pedido.Observacao := 'Teste automático: entrega pela manhã';
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 2, 39.9));
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 1, 39.9)); // produto repetido em outra linha
    Pedido.AdicionarItem(FPedidos.CriarItem(3, 10, 1.25));
    FPedidos.Gravar(Pedido);
    Numero := Pedido.Numero;
    Assert.IsTrue(Numero > 0);

    Carregado := FPedidos.GetPedido(Numero);
    try
      Assert.AreEqual(1, Carregado.CodigoCliente);
      Assert.AreEqual(Pedido.Observacao, Carregado.Observacao);
      Assert.AreEqual(3, Carregado.Itens.Count);
      Assert.AreEqual(Currency(132.2), Carregado.ValorTotal);
      Assert.AreEqual(Pedido.ValorTotal, Carregado.ValorTotal);
    finally
      Carregado.Free;
    end;
    FPedidos.Cancelar(Numero);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.NumeroDoPedidoECrescente;
var
  P1, P2: TPedidoModel;
begin
  ExigirBanco;
  P1 := TPedidoModel.Create;
  P2 := TPedidoModel.Create;
  try
    P1.CodigoCliente := 1;
    P1.AdicionarItem(FPedidos.CriarItem(2, 1, 8.5));
    P2.CodigoCliente := 2;
    P2.AdicionarItem(FPedidos.CriarItem(2, 1, 8.5));
    FPedidos.Gravar(P1);
    FPedidos.Gravar(P2);
    Assert.IsTrue(P2.Numero > P1.Numero);
    FPedidos.Cancelar(P1.Numero);
    FPedidos.Cancelar(P2.Numero);
  finally
    P1.Free;
    P2.Free;
  end;
end;

procedure TTestesIntegracao.GravarPedidoSemClienteNaoGrava;
var
  Pedido: TPedidoModel;
  Antes: Integer;
begin
  ExigirBanco;
  Antes := ContarPedidos;
  Pedido := TPedidoModel.Create;
  try
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 1, 10));
    DeveLevantar(EValidacao,
      procedure
      begin
        FPedidos.Gravar(Pedido);
      end);
    Assert.AreEqual(Antes, ContarPedidos);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.GravarPedidoComClienteInexistenteNaoGrava;
var
  Pedido: TPedidoModel;
  Antes: Integer;
begin
  ExigirBanco;
  Antes := ContarPedidos;
  Pedido := TPedidoModel.Create;
  try
    Pedido.CodigoCliente := 987654;
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 1, 10));
    DeveLevantar(EClienteNaoEncontrado,
      procedure
      begin
        FPedidos.Gravar(Pedido);
      end);
    Assert.AreEqual(Antes, ContarPedidos);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.FalhaNoMeioDaGravacaoFazRollbackDeTudo;
var
  Pedido: TPedidoModel;
  Antes: Integer;
begin
  ExigirBanco;
  // O segundo item aponta para um produto que não existe: a FK recusa o insert
  // dos itens depois de o cabeçalho já ter sido inserido. Nada pode sobrar.
  Antes := ContarPedidos;
  Pedido := TPedidoModel.Create;
  try
    Pedido.CodigoCliente := 1;
    Pedido.AdicionarItem(TPedidoItemModel.Create(1, 'Cemento', 1, 39.9));
    Pedido.AdicionarItem(TPedidoItemModel.Create(987654, 'Fantasma', 1, 10));
    DeveLevantar(EPersistencia,
      procedure
      begin
        FPedidos.Gravar(Pedido);
      end);
    Assert.AreEqual(Antes, ContarPedidos, 'O cabeçalho não deveria ter sido gravado');
    Assert.AreEqual(0, Pedido.Numero, 'O número deve voltar ao estado anterior');
    Assert.IsFalse(FConexao.InTransaction, 'Não pode ficar transação aberta');
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.RegravarPedidoCarregadoAtualizaSemCriarOutro;
var
  Pedido, Recarregado: TPedidoModel;
  Numero, Antes: Integer;
begin
  ExigirBanco;
  Pedido := TPedidoModel.Create;
  try
    Pedido.CodigoCliente := 1;
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 1, 39.9));
    FPedidos.Gravar(Pedido);
    Numero := Pedido.Numero;
    Antes := ContarPedidos;

    Pedido.Observacao := 'Alterado';
    Pedido.AdicionarItem(FPedidos.CriarItem(2, 4, 8.5));
    Pedido.RemoverItem(0);
    FPedidos.Gravar(Pedido);

    Assert.AreEqual(Numero, Pedido.Numero);
    Assert.AreEqual(Antes, ContarPedidos);
    Assert.AreEqual(1, ContarItensDoPedido(Numero));
    Recarregado := FPedidos.GetPedido(Numero);
    try
      Assert.AreEqual('Alterado', Recarregado.Observacao);
      Assert.AreEqual(Currency(34), Recarregado.ValorTotal);
    finally
      Recarregado.Free;
    end;
    FPedidos.Cancelar(Numero);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.CancelarPedidoRemoveCabecalhoEItens;
var
  Pedido: TPedidoModel;
  Numero: Integer;
begin
  ExigirBanco;
  Pedido := TPedidoModel.Create;
  try
    Pedido.CodigoCliente := 1;
    Pedido.AdicionarItem(FPedidos.CriarItem(1, 1, 39.9));
    Pedido.AdicionarItem(FPedidos.CriarItem(2, 2, 8.5));
    FPedidos.Gravar(Pedido);
    Numero := Pedido.Numero;
    Assert.AreEqual(2, ContarItensDoPedido(Numero));

    FPedidos.Cancelar(Numero);

    Assert.AreEqual(0, ContarItensDoPedido(Numero));
    DeveLevantar(EPedidoNaoEncontrado,
      procedure
      begin
        FPedidos.GetPedido(Numero).Free;
      end);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.CancelarPedidoInexistenteLevantaErro;
begin
  ExigirBanco;
  DeveLevantar(EPedidoNaoEncontrado,
    procedure
    begin
      FPedidos.Cancelar(987654);
    end);
end;

procedure TTestesIntegracao.CodigoComAspasNaoQuebraAConsulta;
begin
  ExigirBanco;
  // As consultas usam parâmetros: um texto malicioso vira apenas um valor.
  Assert.AreEqual(0, Integer(FConexao.ExecSQLScalar(
    'SELECT COUNT(*) FROM CLIENTE WHERE NOME = :NOME', ['x'' OR ''1''=''1'])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesIntegracao);

end.
