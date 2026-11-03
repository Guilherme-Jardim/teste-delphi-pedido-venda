unit Pedido.Tests.Eventos;

{ Testes dos eventos de domínio e do publicador em memória. }

interface

uses
  DUnitX.TestFramework,
  Pedido.Domain.Eventos;

type
  [TestFixture]
  TTestesEventos = class
  private
    FPublicador: IPublicadorEventos;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure EventoPedidoGravadoCarregaOsDados;
    [Test]
    procedure EventoPedidoCanceladoCarregaONumero;
    [Test]
    procedure EventoGuardaQuandoOcorreu;
    [Test]
    procedure AssinanteRecebeOEventoPublicado;
    [Test]
    procedure TodosOsAssinantesRecebemNaOrdem;
    [Test]
    procedure MesmoAssinanteNaoEhRegistradoDuasVezes;
    [Test]
    procedure PublicarSemAssinantesNaoFalha;
    [Test]
    procedure AssinanteComDefeitoNaoImpedeOsDemais;
    [Test]
    procedure AssinanteNuloEhIgnorado;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Application.Eventos,
  Pedido.Tests.Falsos;

procedure TTestesEventos.Setup;
begin
  FPublicador := TPublicadorEventosEmMemoria.Create;
end;

procedure TTestesEventos.EventoPedidoGravadoCarregaOsDados;
var
  Evento: TPedidoGravadoEvento;
  Guarda: IEventoDominio;
begin
  Evento := TPedidoGravadoEvento.Create(12, 3, 132.2);
  Guarda := Evento;
  Assert.AreEqual('PedidoGravado', Guarda.Nome);
  Assert.AreEqual(12, Evento.Numero);
  Assert.AreEqual(3, Evento.QuantidadeItens);
  Assert.AreEqual(Currency(132.2), Evento.ValorTotal);
end;

procedure TTestesEventos.EventoPedidoCanceladoCarregaONumero;
var
  Evento: TPedidoCanceladoEvento;
  Guarda: IEventoDominio;
begin
  Evento := TPedidoCanceladoEvento.Create(8);
  Guarda := Evento;
  Assert.AreEqual('PedidoCancelado', Guarda.Nome);
  Assert.AreEqual(8, Evento.Numero);
end;

procedure TTestesEventos.EventoGuardaQuandoOcorreu;
var
  Antes: TDateTime;
  Evento: IEventoDominio;
begin
  Antes := Now;
  Evento := TPedidoCanceladoEvento.Create(1);
  Assert.IsTrue(Evento.OcorridoEm >= Antes);
  Assert.IsTrue(Evento.OcorridoEm <= Now);
end;

procedure TTestesEventos.AssinanteRecebeOEventoPublicado;
var
  Gravador: TAssinanteGravador;
  Assinante: IAssinanteEventos;
begin
  Gravador := TAssinanteGravador.Create;
  Assinante := Gravador;
  FPublicador.Assinar(Assinante);
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(5));
  Assert.AreEqual(1, Gravador.Nomes.Count);
  Assert.AreEqual('PedidoCancelado', Gravador.Nomes[0]);
end;

procedure TTestesEventos.TodosOsAssinantesRecebemNaOrdem;
var
  A, B: TAssinanteGravador;
  IA, IB: IAssinanteEventos;
begin
  A := TAssinanteGravador.Create;
  B := TAssinanteGravador.Create;
  IA := A;
  IB := B;
  FPublicador.Assinar(IA);
  FPublicador.Assinar(IB);
  FPublicador.Publicar(TPedidoGravadoEvento.Create(1, 1, 10));
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(1));
  Assert.AreEqual(2, A.Nomes.Count);
  Assert.AreEqual(2, B.Nomes.Count);
  Assert.AreEqual('PedidoGravado', A.Nomes[0]);
  Assert.AreEqual('PedidoCancelado', A.Nomes[1]);
end;

procedure TTestesEventos.MesmoAssinanteNaoEhRegistradoDuasVezes;
var
  Gravador: TAssinanteGravador;
  Assinante: IAssinanteEventos;
begin
  Gravador := TAssinanteGravador.Create;
  Assinante := Gravador;
  FPublicador.Assinar(Assinante);
  FPublicador.Assinar(Assinante);
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(2));
  Assert.AreEqual(1, Gravador.Nomes.Count);
end;

procedure TTestesEventos.PublicarSemAssinantesNaoFalha;
begin
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(3));
  Assert.Pass;
end;

procedure TTestesEventos.AssinanteComDefeitoNaoImpedeOsDemais;
var
  Gravador: TAssinanteGravador;
  Bom, Ruim: IAssinanteEventos;
begin
  Gravador := TAssinanteGravador.Create;
  Bom := Gravador;
  Ruim := TAssinanteQuebrado.Create;
  FPublicador.Assinar(Ruim);
  FPublicador.Assinar(Bom);
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(4));
  Assert.AreEqual(1, Gravador.Nomes.Count);
end;

procedure TTestesEventos.AssinanteNuloEhIgnorado;
begin
  FPublicador.Assinar(nil);
  FPublicador.Publicar(TPedidoCanceladoEvento.Create(6));
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesEventos);

end.
