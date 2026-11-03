unit Pedido.Domain.Eventos;

{ Eventos de domínio: fatos importantes que já aconteceram ("o pedido foi
  gravado"). Quem quiser reagir (registrar em log, avisar outro sistema...)
  assina o publicador, sem que o caso de uso precise conhecer quem escuta. }

interface

type
  IEventoDominio = interface
    ['{6E2A9C41-8B05-4D73-A1F6-3C7D0B9E5A28}']
    function Nome: string;
    function OcorridoEm: TDateTime;
  end;

  IAssinanteEventos = interface
    ['{0B7D3E95-4A18-4C62-9F5E-8D1A6C2B7F03}']
    procedure Tratar(const AEvento: IEventoDominio);
  end;

  IPublicadorEventos = interface
    ['{D4F81A27-6C39-4E50-B2A8-1E5B9D0C7A64}']
    procedure Assinar(const AAssinante: IAssinanteEventos);
    procedure Publicar(const AEvento: IEventoDominio);
  end;

  TEventoDominio = class(TInterfacedObject, IEventoDominio)
  private
    FOcorridoEm: TDateTime;
  public
    constructor Create;
    function Nome: string; virtual; abstract;
    function OcorridoEm: TDateTime;
  end;

  TPedidoGravadoEvento = class(TEventoDominio)
  private
    FNumero: Integer;
    FQuantidadeItens: Integer;
    FValorTotal: Currency;
  public
    constructor Create(ANumero, AQuantidadeItens: Integer; AValorTotal: Currency);
    function Nome: string; override;
    property Numero: Integer read FNumero;
    property QuantidadeItens: Integer read FQuantidadeItens;
    property ValorTotal: Currency read FValorTotal;
  end;

  TPedidoCanceladoEvento = class(TEventoDominio)
  private
    FNumero: Integer;
  public
    constructor Create(ANumero: Integer);
    function Nome: string; override;
    property Numero: Integer read FNumero;
  end;

implementation

uses
  System.SysUtils;

constructor TEventoDominio.Create;
begin
  inherited Create;
  FOcorridoEm := Now;
end;

function TEventoDominio.OcorridoEm: TDateTime;
begin
  Result := FOcorridoEm;
end;

constructor TPedidoGravadoEvento.Create(ANumero, AQuantidadeItens: Integer; AValorTotal: Currency);
begin
  inherited Create;
  FNumero := ANumero;
  FQuantidadeItens := AQuantidadeItens;
  FValorTotal := AValorTotal;
end;

function TPedidoGravadoEvento.Nome: string;
begin
  Result := 'PedidoGravado';
end;

constructor TPedidoCanceladoEvento.Create(ANumero: Integer);
begin
  inherited Create;
  FNumero := ANumero;
end;

function TPedidoCanceladoEvento.Nome: string;
begin
  Result := 'PedidoCancelado';
end;

end.
