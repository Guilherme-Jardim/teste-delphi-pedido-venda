unit Pedido.Tests.Dominio;

{ Testes da camada de domínio: objetos de valor e regras do agregado Pedido.
  Não usam banco, tela nem idioma: só as regras de negócio. }

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Pedido.Domain.Erros,
  Pedido.Domain.Pedido;

type
  [TestFixture]
  TTestesObjetosValor = class
  private
    procedure DeveFalharCom(ACodigo: TCodigoErro; const AAcao: TProc);
  public
    [Test]
    procedure QuantidadePositivaEAceita;
    [Test]
    procedure QuantidadeZeroEhRecusada;
    [Test]
    procedure QuantidadeNegativaEhRecusada;
    [Test]
    procedure QuantidadeAcimaDoLimiteEhRecusada;
    [Test]
    procedure QuantidadesComOMesmoValorSaoIguais;
    [Test]
    procedure DinheiroZeroEhAceito;
    [Test]
    procedure DinheiroNegativoEhRecusado;
    [Test]
    procedure DinheiroAcimaDoLimiteEhRecusado;
    [Test]
    procedure SomarNaoAlteraOsOperandos;
    [Test]
    procedure MultiplicarArredondaEmCentavos;
    [Test]
    procedure DinheirosComOMesmoValorSaoIguais;
    [Test]
    procedure ResultadoDeContaPodePassarDoLimiteDeItem;
  end;

  [TestFixture]
  TTestesAgregadoPedido = class
  private
    FPedido: TPedido;
    procedure DeveFalharCom(ACodigo: TCodigoErro; const AAcao: TProc);
    procedure AdicionarItemSimples(ACodigo: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure PedidoNovoNaoTemNumeroNemCliente;
    [Test]
    procedure PedidoNovoNasceComADataDeHoje;
    [Test]
    procedure ClienteInvalidoEhRecusado;
    [Test]
    procedure InformarERemoverClienteAtualizaOCodigo;
    [Test]
    procedure ObservacaoComEspacosEhAparada;
    [Test]
    procedure ObservacaoNoLimiteEhAceita;
    [Test]
    procedure ObservacaoAcimaDoLimiteEhRecusada;
    [Test]
    procedure ObservacaoRecusadaNaoSobrescreveAAnterior;
    [Test]
    procedure ValidarSemClienteFalha;
    [Test]
    procedure ValidarSemItensFalha;
    [Test]
    procedure ValidarCompletoNaoFalha;
    [Test]
    procedure AtualizarItemComIndiceInvalidoFalhaELiberaOItem;
    [Test]
    procedure RemoverItemComIndiceNegativoFalha;
    [Test]
    procedure TotalNuncaFicaDesatualizado;
  end;

implementation

uses
  Pedido.Domain.ObjetosValor,
  Pedido.Domain.PedidoItem;

{ TTestesObjetosValor }

procedure TTestesObjetosValor.DeveFalharCom(ACodigo: TCodigoErro; const AAcao: TProc);
begin
  try
    AAcao();
  except
    on E: EDominioErro do
    begin
      Assert.AreEqual(Ord(ACodigo), Ord(E.Codigo),
        'Esperava ' + NomeDoCodigo(ACodigo) + ' mas veio ' + NomeDoCodigo(E.Codigo));
      Exit;
    end;
  end;
  Assert.Fail('Esperava o erro ' + NomeDoCodigo(ACodigo));
end;

procedure TTestesObjetosValor.QuantidadePositivaEAceita;
begin
  Assert.AreEqual(2.5, TQuantidade.Criar(2.5).Valor, 0.0000001);
end;

procedure TTestesObjetosValor.QuantidadeZeroEhRecusada;
begin
  DeveFalharCom(ceQuantidadeInvalida,
    procedure
    begin
      TQuantidade.Criar(0);
    end);
end;

procedure TTestesObjetosValor.QuantidadeNegativaEhRecusada;
begin
  DeveFalharCom(ceQuantidadeInvalida,
    procedure
    begin
      TQuantidade.Criar(-3);
    end);
end;

procedure TTestesObjetosValor.QuantidadeAcimaDoLimiteEhRecusada;
begin
  DeveFalharCom(ceQuantidadeAcimaDoLimite,
    procedure
    begin
      TQuantidade.Criar(100000);
    end);
end;

procedure TTestesObjetosValor.QuantidadesComOMesmoValorSaoIguais;
begin
  Assert.IsTrue(TQuantidade.Criar(3).IgualA(TQuantidade.Criar(3)));
  Assert.IsFalse(TQuantidade.Criar(3).IgualA(TQuantidade.Criar(4)));
end;

procedure TTestesObjetosValor.DinheiroZeroEhAceito;
begin
  Assert.AreEqual(Currency(0), TDinheiro.Criar(0).Valor);
end;

procedure TTestesObjetosValor.DinheiroNegativoEhRecusado;
begin
  DeveFalharCom(ceValorNegativo,
    procedure
    begin
      TDinheiro.Criar(-0.01);
    end);
end;

procedure TTestesObjetosValor.DinheiroAcimaDoLimiteEhRecusado;
begin
  DeveFalharCom(ceValorAcimaDoLimite,
    procedure
    begin
      TDinheiro.Criar(10000000);
    end);
end;

procedure TTestesObjetosValor.SomarNaoAlteraOsOperandos;
var
  A, B, Soma: TDinheiro;
begin
  A := TDinheiro.Criar(10.5);
  B := TDinheiro.Criar(4.25);
  Soma := A.Somar(B);
  Assert.AreEqual(Currency(14.75), Soma.Valor);
  Assert.AreEqual(Currency(10.5), A.Valor);
  Assert.AreEqual(Currency(4.25), B.Valor);
end;

procedure TTestesObjetosValor.MultiplicarArredondaEmCentavos;
begin
  // 3 x 0,333 = 0,999 -> 1,00
  Assert.AreEqual(Currency(1), TDinheiro.Criar(0.333).Multiplicar(TQuantidade.Criar(3)).Valor);
  // 2,5 x 1,01 = 2,525 -> 2,53 (meio para cima)
  Assert.AreEqual(Currency(2.53), TDinheiro.Criar(1.01).Multiplicar(TQuantidade.Criar(2.5)).Valor);
end;

procedure TTestesObjetosValor.DinheirosComOMesmoValorSaoIguais;
begin
  Assert.IsTrue(TDinheiro.Criar(9.9).IgualA(TDinheiro.Criar(9.9)));
  Assert.IsFalse(TDinheiro.Criar(9.9).IgualA(TDinheiro.Criar(9.91)));
end;

procedure TTestesObjetosValor.ResultadoDeContaPodePassarDoLimiteDeItem;
begin
  // O total de um pedido pode ser maior que o valor máximo de um item.
  Assert.AreEqual(Currency(50000000), TDinheiro.DeResultado(50000000).Valor);
end;

{ TTestesAgregadoPedido }

procedure TTestesAgregadoPedido.Setup;
begin
  FPedido := TPedido.Create;
end;

procedure TTestesAgregadoPedido.TearDown;
begin
  FPedido.Free;
end;

procedure TTestesAgregadoPedido.DeveFalharCom(ACodigo: TCodigoErro; const AAcao: TProc);
begin
  try
    AAcao();
  except
    on E: EDominioErro do
    begin
      Assert.AreEqual(Ord(ACodigo), Ord(E.Codigo),
        'Esperava ' + NomeDoCodigo(ACodigo) + ' mas veio ' + NomeDoCodigo(E.Codigo));
      Exit;
    end;
  end;
  Assert.Fail('Esperava o erro ' + NomeDoCodigo(ACodigo));
end;

procedure TTestesAgregadoPedido.AdicionarItemSimples(ACodigo: Integer);
begin
  FPedido.AdicionarItem(TPedidoItem.Criar(ACodigo, 'Produto ' + IntToStr(ACodigo), 1, 10));
end;

procedure TTestesAgregadoPedido.PedidoNovoNaoTemNumeroNemCliente;
begin
  Assert.AreEqual(0, FPedido.Numero);
  Assert.AreEqual(0, FPedido.CodigoCliente);
  Assert.AreEqual(0, FPedido.Itens.Count);
end;

procedure TTestesAgregadoPedido.PedidoNovoNasceComADataDeHoje;
begin
  Assert.AreEqual(Trunc(Date), Trunc(FPedido.DataEmissao));
end;

procedure TTestesAgregadoPedido.ClienteInvalidoEhRecusado;
begin
  DeveFalharCom(ceSemCliente,
    procedure
    begin
      FPedido.InformarCliente(0);
    end);
  DeveFalharCom(ceSemCliente,
    procedure
    begin
      FPedido.InformarCliente(-4);
    end);
end;

procedure TTestesAgregadoPedido.InformarERemoverClienteAtualizaOCodigo;
begin
  FPedido.InformarCliente(7);
  Assert.AreEqual(7, FPedido.CodigoCliente);
  FPedido.RemoverCliente;
  Assert.AreEqual(0, FPedido.CodigoCliente);
end;

procedure TTestesAgregadoPedido.ObservacaoComEspacosEhAparada;
begin
  FPedido.DefinirObservacao('   entrega pela manhã   ');
  Assert.AreEqual('entrega pela manhã', FPedido.Observacao);
end;

procedure TTestesAgregadoPedido.ObservacaoNoLimiteEhAceita;
begin
  FPedido.DefinirObservacao(StringOfChar('a', TAMANHO_MAXIMO_OBSERVACAO));
  Assert.AreEqual(TAMANHO_MAXIMO_OBSERVACAO, Length(FPedido.Observacao));
end;

procedure TTestesAgregadoPedido.ObservacaoAcimaDoLimiteEhRecusada;
begin
  DeveFalharCom(ceObservacaoLonga,
    procedure
    begin
      FPedido.DefinirObservacao(StringOfChar('a', TAMANHO_MAXIMO_OBSERVACAO + 1));
    end);
end;

procedure TTestesAgregadoPedido.ObservacaoRecusadaNaoSobrescreveAAnterior;
begin
  FPedido.DefinirObservacao('original');
  try
    FPedido.DefinirObservacao(StringOfChar('a', TAMANHO_MAXIMO_OBSERVACAO + 1));
  except
    on EDominioErro do
      ;
  end;
  Assert.AreEqual('original', FPedido.Observacao);
end;

procedure TTestesAgregadoPedido.ValidarSemClienteFalha;
begin
  AdicionarItemSimples(1);
  DeveFalharCom(ceSemCliente,
    procedure
    begin
      FPedido.ValidarParaGravacao;
    end);
end;

procedure TTestesAgregadoPedido.ValidarSemItensFalha;
begin
  FPedido.InformarCliente(1);
  DeveFalharCom(ceSemItens,
    procedure
    begin
      FPedido.ValidarParaGravacao;
    end);
end;

procedure TTestesAgregadoPedido.ValidarCompletoNaoFalha;
begin
  FPedido.InformarCliente(1);
  AdicionarItemSimples(1);
  FPedido.ValidarParaGravacao;
  Assert.Pass;
end;

procedure TTestesAgregadoPedido.AtualizarItemComIndiceInvalidoFalhaELiberaOItem;
begin
  // O item recebido passa a ser do agregado; se o índice é inválido, ele é liberado
  // (o teste de vazamento do DUnitX acusaria se não fosse).
  DeveFalharCom(ceItemInvalido,
    procedure
    begin
      FPedido.AtualizarItem(5, TPedidoItem.Criar(1, 'X', 1, 1));
    end);
end;

procedure TTestesAgregadoPedido.RemoverItemComIndiceNegativoFalha;
begin
  AdicionarItemSimples(1);
  DeveFalharCom(ceItemInvalido,
    procedure
    begin
      FPedido.RemoverItem(-1);
    end);
  Assert.AreEqual(1, FPedido.Itens.Count);
end;

procedure TTestesAgregadoPedido.TotalNuncaFicaDesatualizado;
begin
  AdicionarItemSimples(1);
  Assert.AreEqual(Currency(10), FPedido.ValorTotal.Valor);
  FPedido.AtualizarItem(0, TPedidoItem.Criar(1, 'Produto 1', 3, 10));
  Assert.AreEqual(Currency(30), FPedido.ValorTotal.Valor);
  AdicionarItemSimples(2);
  Assert.AreEqual(Currency(40), FPedido.ValorTotal.Valor);
  FPedido.RemoverItem(0);
  Assert.AreEqual(Currency(10), FPedido.ValorTotal.Valor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesObjetosValor);
  TDUnitX.RegisterTestFixture(TTestesAgregadoPedido);

end.
