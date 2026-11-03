unit Pedido.Infra.AssinanteLog;

{ Assinante de eventos de domínio que registra cada evento no log técnico.
  Mostra como a infraestrutura reage ao domínio sem que o caso de uso saiba. }

interface

uses
  Pedido.Domain.Eventos;

type
  TAssinanteLogEventos = class(TInterfacedObject, IAssinanteEventos)
  public
    procedure Tratar(const AEvento: IEventoDominio);
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Log;

procedure TAssinanteLogEventos.Tratar(const AEvento: IEventoDominio);
var
  Gravado: TPedidoGravadoEvento;
  Cancelado: TPedidoCanceladoEvento;
begin
  if AEvento is TPedidoGravadoEvento then
  begin
    Gravado := TPedidoGravadoEvento(AEvento);
    RegistrarInformacao(Format('Evento %s: pedido %d, %d item(ns)', [AEvento.Nome, Gravado.Numero,
      Gravado.QuantidadeItens]));
  end
  else if AEvento is TPedidoCanceladoEvento then
  begin
    Cancelado := TPedidoCanceladoEvento(AEvento);
    RegistrarInformacao(Format('Evento %s: pedido %d', [AEvento.Nome, Cancelado.Numero]));
  end
  else
    RegistrarInformacao('Evento ' + AEvento.Nome);
end;

end.
