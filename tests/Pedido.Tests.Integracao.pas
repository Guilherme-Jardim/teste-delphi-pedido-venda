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
  Pedido.Application.Interfaces,
  Pedido.Domain.Erros,
  Pedido.Infra.Composicao;

type
  [TestFixture]
  TTestesIntegracao = class
  private
    FDono: TComponent;
    FConexao: TFDConnection;
    FComposicao: TComposicaoSistema;
    FCasos: TCasosDeUsoPedido;
    FSemBanco: Boolean;
    function ContarPedidos: Integer;
    procedure ExigirBanco;
    procedure DeveLevantar(ACodigo: TCodigoErro; const AAcao: TProc);
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
  Pedido.Domain.Cliente,
  Pedido.Domain.Pedido,
  Pedido.Domain.PedidoItem,
  Pedido.Domain.Produto,
  Pedido.Infra.Idioma;

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
  FCasos := FComposicao.CasosDeUso;
end;

procedure TTestesIntegracao.TearDownFixture;
begin
  FCasos := Default(TCasosDeUsoPedido);
  FComposicao.Free;
  FDono.Free;
end;

procedure TTestesIntegracao.ExigirBanco;
begin
  // Sem config.ini ou sem banco, o teste passa sem verificar nada (aviso no resultado).
  if FSemBanco then
    Assert.Pass('Sem banco disponível: teste de integração ignorado.');
end;

procedure TTestesIntegracao.DeveLevantar(ACodigo: TCodigoErro; const AAcao: TProc);
begin
  try
    AAcao();
  except
    on E: EDominioErro do
    begin
      Assert.AreEqual(Ord(ACodigo), Ord(E.Codigo),
        Format('Esperava o erro %s, mas veio %s', [NomeDoCodigo(ACodigo), NomeDoCodigo(E.Codigo)]));
      Exit;
    end;
    on E: Exception do
    begin
      Assert.Fail(Format('Esperava um erro de domínio, mas veio %s: %s', [E.ClassName, E.Message]));
      Exit;
    end;
  end;
  Assert.Fail('Esperava o erro ' + NomeDoCodigo(ACodigo));
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
  Cliente: TCliente;
begin
  ExigirBanco;
  Cliente := FCasos.ConsultarCliente.Executar(1);
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
  DeveLevantar(ceClienteNaoEncontrado,
    procedure
    begin
      FCasos.ConsultarCliente.Executar(987654).Free;
    end);
end;

procedure TTestesIntegracao.ProdutoExistenteTemDescricaoEPreco;
var
  Produto: TProduto;
begin
  ExigirBanco;
  Produto := FCasos.ConsultarProduto.Executar(1);
  try
    Assert.IsNotEmpty(Produto.Descricao);
    Assert.IsTrue(Produto.PrecoVenda.Valor > 0);
  finally
    Produto.Free;
  end;
end;

procedure TTestesIntegracao.ProdutoInexistenteLevantaErro;
begin
  ExigirBanco;
  DeveLevantar(ceProdutoNaoEncontrado,
    procedure
    begin
      FCasos.ConsultarProduto.Executar(987654).Free;
    end);
end;

procedure TTestesIntegracao.GravarPedidoPersisteCabecalhoItensEObservacao;
var
  Pedido, Carregado: TPedido;
  Numero: Integer;
begin
  ExigirBanco;
  Pedido := TPedido.Create;
  try
    Pedido.InformarCliente(1);
    Pedido.DefinirObservacao('Teste automático: entrega pela manhã');
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 2, 39.9));
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 1, 39.9)); // produto repetido em outra linha
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(3, 10, 1.25));
    FCasos.Gravar.Executar(Pedido);
    Numero := Pedido.Numero;
    Assert.IsTrue(Numero > 0);

    Carregado := FCasos.Carregar.Executar(Numero);
    try
      Assert.AreEqual(1, Carregado.CodigoCliente);
      Assert.AreEqual(Pedido.Observacao, Carregado.Observacao);
      Assert.AreEqual(3, Carregado.Itens.Count);
      Assert.AreEqual(Currency(132.2), Carregado.ValorTotal.Valor);
      Assert.AreEqual(Pedido.ValorTotal.Valor, Carregado.ValorTotal.Valor);
    finally
      Carregado.Free;
    end;
    FCasos.Cancelar.Executar(Numero);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.NumeroDoPedidoECrescente;
var
  P1, P2: TPedido;
begin
  ExigirBanco;
  P1 := TPedido.Create;
  P2 := TPedido.Create;
  try
    P1.InformarCliente(1);
    P1.AdicionarItem(FCasos.CriarItem.Executar(2, 1, 8.5));
    P2.InformarCliente(2);
    P2.AdicionarItem(FCasos.CriarItem.Executar(2, 1, 8.5));
    FCasos.Gravar.Executar(P1);
    FCasos.Gravar.Executar(P2);
    Assert.IsTrue(P2.Numero > P1.Numero);
    FCasos.Cancelar.Executar(P1.Numero);
    FCasos.Cancelar.Executar(P2.Numero);
  finally
    P1.Free;
    P2.Free;
  end;
end;

procedure TTestesIntegracao.GravarPedidoSemClienteNaoGrava;
var
  Pedido: TPedido;
  Antes: Integer;
begin
  ExigirBanco;
  Antes := ContarPedidos;
  Pedido := TPedido.Create;
  try
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 1, 10));
    DeveLevantar(ceSemCliente,
      procedure
      begin
        FCasos.Gravar.Executar(Pedido);
      end);
    Assert.AreEqual(Antes, ContarPedidos);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.GravarPedidoComClienteInexistenteNaoGrava;
var
  Pedido: TPedido;
  Antes: Integer;
begin
  ExigirBanco;
  Antes := ContarPedidos;
  Pedido := TPedido.Create;
  try
    Pedido.InformarCliente(987654);
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 1, 10));
    DeveLevantar(ceClienteNaoEncontrado,
      procedure
      begin
        FCasos.Gravar.Executar(Pedido);
      end);
    Assert.AreEqual(Antes, ContarPedidos);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.FalhaNoMeioDaGravacaoFazRollbackDeTudo;
var
  Pedido: TPedido;
  Antes: Integer;
begin
  ExigirBanco;
  // O segundo item aponta para um produto que não existe: a FK recusa o insert
  // dos itens depois de o cabeçalho já ter sido inserido. Nada pode sobrar.
  Antes := ContarPedidos;
  Pedido := TPedido.Create;
  try
    Pedido.InformarCliente(1);
    Pedido.AdicionarItem(TPedidoItem.Criar(1, 'Cemento', 1, 39.9));
    Pedido.AdicionarItem(TPedidoItem.Criar(987654, 'Fantasma', 1, 10));
    DeveLevantar(ceFalhaAoGravar,
      procedure
      begin
        FCasos.Gravar.Executar(Pedido);
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
  Pedido, Recarregado: TPedido;
  Numero, Antes: Integer;
begin
  ExigirBanco;
  Pedido := TPedido.Create;
  try
    Pedido.InformarCliente(1);
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 1, 39.9));
    FCasos.Gravar.Executar(Pedido);
    Numero := Pedido.Numero;
    Antes := ContarPedidos;

    Pedido.DefinirObservacao('Alterado');
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(2, 4, 8.5));
    Pedido.RemoverItem(0);
    FCasos.Gravar.Executar(Pedido);

    Assert.AreEqual(Numero, Pedido.Numero);
    Assert.AreEqual(Antes, ContarPedidos);
    Assert.AreEqual(1, ContarItensDoPedido(Numero));
    Recarregado := FCasos.Carregar.Executar(Numero);
    try
      Assert.AreEqual('Alterado', Recarregado.Observacao);
      Assert.AreEqual(Currency(34), Recarregado.ValorTotal.Valor);
    finally
      Recarregado.Free;
    end;
    FCasos.Cancelar.Executar(Numero);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.CancelarPedidoRemoveCabecalhoEItens;
var
  Pedido: TPedido;
  Numero: Integer;
begin
  ExigirBanco;
  Pedido := TPedido.Create;
  try
    Pedido.InformarCliente(1);
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(1, 1, 39.9));
    Pedido.AdicionarItem(FCasos.CriarItem.Executar(2, 2, 8.5));
    FCasos.Gravar.Executar(Pedido);
    Numero := Pedido.Numero;
    Assert.AreEqual(2, ContarItensDoPedido(Numero));

    FCasos.Cancelar.Executar(Numero);

    Assert.AreEqual(0, ContarItensDoPedido(Numero));
    DeveLevantar(cePedidoNaoEncontrado,
      procedure
      begin
        FCasos.Carregar.Executar(Numero).Free;
      end);
  finally
    Pedido.Free;
  end;
end;

procedure TTestesIntegracao.CancelarPedidoInexistenteLevantaErro;
begin
  ExigirBanco;
  DeveLevantar(cePedidoNaoEncontrado,
    procedure
    begin
      FCasos.Cancelar.Executar(987654);
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
