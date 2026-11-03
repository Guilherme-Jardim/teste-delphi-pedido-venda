unit Pedido.Domain.ObjetosValor;

{ Objetos de valor do domínio. São imutáveis, comparados pelo valor (não por
  identidade) e só existem se forem válidos: é impossível ter uma quantidade
  negativa ou um valor acima do limite do banco circulando pelo sistema. }

interface

type
  // Quantidade de um item: maior que zero e até 99.999,999 (limite da coluna NUMERIC(15,3)).
  TQuantidade = record
  private
    FValor: Double;
  public
    class function Criar(AValor: Double): TQuantidade; static;
    property Valor: Double read FValor;
    function IgualA(const AOutra: TQuantidade): Boolean;
  end;

  // Valor em reais com duas casas. Valores de item ficam entre 0 e 9.999.999,99.
  TDinheiro = record
  private
    FValor: Currency;
  public
    // Valor de um item (unitário): valida o intervalo permitido.
    class function Criar(AValor: Currency): TDinheiro; static;
    // Resultado de uma conta (total de item ou do pedido): sem o limite de um item.
    class function DeResultado(AValor: Currency): TDinheiro; static;
    class function Zero: TDinheiro; static;
    property Valor: Currency read FValor;
    function Somar(const AOutro: TDinheiro): TDinheiro;
    // Valor x quantidade, arredondado em centavos (meio para cima).
    function Multiplicar(const AQuantidade: TQuantidade): TDinheiro;
    function IgualA(const AOutro: TDinheiro): Boolean;
  end;

const
  QUANTIDADE_MAXIMA = 99999.999;
  VALOR_UNITARIO_MAXIMO = 9999999.99;

implementation

uses
  System.Math,
  Pedido.Domain.Erros;

{ TQuantidade }

class function TQuantidade.Criar(AValor: Double): TQuantidade;
begin
  if AValor <= 0 then
    raise EDominioErro.Create(ceQuantidadeInvalida);
  if AValor > QUANTIDADE_MAXIMA then
    raise EDominioErro.Create(ceQuantidadeAcimaDoLimite);
  Result.FValor := AValor;
end;

function TQuantidade.IgualA(const AOutra: TQuantidade): Boolean;
begin
  Result := SameValue(FValor, AOutra.FValor, 0.0000001);
end;

{ TDinheiro }

class function TDinheiro.Criar(AValor: Currency): TDinheiro;
begin
  if AValor < 0 then
    raise EDominioErro.Create(ceValorNegativo);
  if AValor > VALOR_UNITARIO_MAXIMO then
    raise EDominioErro.Create(ceValorAcimaDoLimite);
  Result.FValor := AValor;
end;

class function TDinheiro.DeResultado(AValor: Currency): TDinheiro;
begin
  Result.FValor := AValor;
end;

class function TDinheiro.Zero: TDinheiro;
begin
  Result.FValor := 0;
end;

function TDinheiro.Somar(const AOutro: TDinheiro): TDinheiro;
begin
  Result.FValor := FValor + AOutro.FValor;
end;

function TDinheiro.Multiplicar(const AQuantidade: TQuantidade): TDinheiro;
begin
  Result.FValor := SimpleRoundTo(AQuantidade.Valor * FValor, -2);
end;

function TDinheiro.IgualA(const AOutro: TDinheiro): Boolean;
begin
  Result := FValor = AOutro.FValor;
end;

end.
