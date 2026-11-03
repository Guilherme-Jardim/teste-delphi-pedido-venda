unit Pedido.Tests.Controller;

{ Regras do controller que se resolvem antes de tocar no banco.
  Aqui o controller é criado sem conexão: se alguma regra deixasse de
  validar e tentasse acessar o banco, o teste quebraria. }

interface

uses
  DUnitX.TestFramework,
  Pedido.Controller.Pedido,
  Pedido.Model.Pedido;

type
  [TestFixture]
  TTestesController = class
  private
    FController: TPedidoController;
    FPedido: TPedidoModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure GravarSemClienteEInvalido;
    [Test]
    procedure GravarSemItensEInvalido;
    [Test]
    procedure CancelarComNumeroZeroEInvalido;
    [Test]
    procedure CancelarComNumeroNegativoEInvalido;
  end;

implementation

uses
  Pedido.Infra.Idioma,
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem;

procedure TTestesController.Setup;
begin
  DefinirIdioma(idEspanhol, False);
  FController := TPedidoController.Create(nil);
  FPedido := TPedidoModel.Create;
end;

procedure TTestesController.TearDown;
begin
  FPedido.Free;
  FController.Free;
end;

procedure TTestesController.GravarSemClienteEInvalido;
begin
  FPedido.AdicionarItem(TPedidoItemModel.Create(1, 'Cemento', 1, 10));
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EValidacao);
end;

procedure TTestesController.GravarSemItensEInvalido;
begin
  FPedido.CodigoCliente := 1;
  Assert.WillRaise(
    procedure
    begin
      FController.Gravar(FPedido);
    end, EValidacao);
end;

procedure TTestesController.CancelarComNumeroZeroEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.Cancelar(0);
    end, EValidacao);
end;

procedure TTestesController.CancelarComNumeroNegativoEInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      FController.Cancelar(-5);
    end, EValidacao);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesController);

end.
