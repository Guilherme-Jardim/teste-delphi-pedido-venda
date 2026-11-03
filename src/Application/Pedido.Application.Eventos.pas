unit Pedido.Application.Eventos;

{ Publicador de eventos de domínio em memória: entrega cada evento a todos os
  assinantes, na ordem em que assinaram. Um assinante com defeito não pode
  derrubar o caso de uso que publicou (o pedido já foi gravado). }

interface

uses
  System.Generics.Collections,
  Pedido.Domain.Eventos;

type
  TPublicadorEventosEmMemoria = class(TInterfacedObject, IPublicadorEventos)
  private
    FAssinantes: TList<IAssinanteEventos>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assinar(const AAssinante: IAssinanteEventos);
    procedure Publicar(const AEvento: IEventoDominio);
  end;

implementation

uses
  System.SysUtils;

constructor TPublicadorEventosEmMemoria.Create;
begin
  inherited Create;
  FAssinantes := TList<IAssinanteEventos>.Create;
end;

destructor TPublicadorEventosEmMemoria.Destroy;
begin
  FAssinantes.Free;
  inherited;
end;

procedure TPublicadorEventosEmMemoria.Assinar(const AAssinante: IAssinanteEventos);
begin
  if (AAssinante <> nil) and not FAssinantes.Contains(AAssinante) then
    FAssinantes.Add(AAssinante);
end;

procedure TPublicadorEventosEmMemoria.Publicar(const AEvento: IEventoDominio);
var
  Assinante: IAssinanteEventos;
begin
  for Assinante in FAssinantes.ToArray do
  begin
    try
      Assinante.Tratar(AEvento);
    except
      // O fato já aconteceu; falha de quem escuta não desfaz nada.
    end;
  end;
end;

end.
