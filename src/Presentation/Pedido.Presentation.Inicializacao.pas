unit Pedido.Presentation.Inicializacao;

{ Janelas da inicialização: avisos com botões de ação (diálogo moderno) e a tela
  de configuração. É a implementação com VCL do contrato IInteracaoInicializacao;
  a lógica de decisão fica no TInicializadorSistema, que não sabe que existem janelas. }

interface

uses
  Pedido.Infra.Config,
  Pedido.Infra.Inicializador;

type
  TInteracaoVcl = class(TInterfacedObject, IInteracaoInicializacao)
  public
    function ConfigurarBanco(const ASugestao: TConfigBanco; APrimeiraVez: Boolean;
      out AConfig: TConfigBanco): Boolean;
    function PerguntarAcao(AProblema: TProblemaInicializacao; const AConfig: TConfigBanco;
      const ADetalhe: string; const APermitidas: TAcoesUsuario): TAcaoUsuario;
    procedure Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
  end;

implementation

uses
  System.SysUtils,
  ComponentIcons,
  Pedido.Infra.Idioma,
  Pedido.Presentation.ConfiguracaoBanco,
  Pedido.Presentation.Dialogos;

function ChaveDoProblema(AProblema: TProblemaInicializacao): string;
begin
  case AProblema of
    pbConfigInvalida: Result := 'pb.config_invalida';
    pbBancoSumiu: Result := 'pb.banco_sumiu';
    pbSemEstrutura: Result := 'pb.sem_estrutura';
    pbBancoDeOutroSistema: Result := 'pb.outro_sistema';
    pbServidorIndisponivel: Result := 'pb.servidor';
    pbCredenciaisInvalidas: Result := 'pb.credenciais';
    pbBibliotecaIndisponivel: Result := 'pb.biblioteca';
  else
    Result := 'pb.erro';
  end;
end;

function TextoDoProblema(AProblema: TProblemaInicializacao; const AConfig: TConfigBanco;
  const ADetalhe: string): string;
var
  Servidor: string;
begin
  Servidor := AConfig.Server;
  if Servidor = '' then
    Servidor := 'localhost';
  case AProblema of
    pbConfigInvalida: Result := Tr('pb.config_invalida.msg', [ADetalhe]);
    pbBancoSumiu: Result := Tr('pb.banco_sumiu.msg', [AConfig.Database]);
    pbSemEstrutura: Result := Tr('pb.sem_estrutura.msg', [AConfig.Database]);
    pbBancoDeOutroSistema: Result := Tr('pb.outro_sistema.msg', [AConfig.Database]);
    pbServidorIndisponivel: Result := Tr('pb.servidor.msg', [Servidor, AConfig.Port]);
    pbCredenciaisInvalidas: Result := Tr('pb.credenciais.msg', [AConfig.Username]);
    pbBibliotecaIndisponivel: Result := Tr('pb.biblioteca.msg', [AConfig.ClientLibrary]);
  else
    Result := Tr('pb.erro.msg', [AConfig.Database]);
  end;
end;

function LegendaDaAcao(AAcao: TAcaoUsuario): string;
begin
  case AAcao of
    auReconfigurar: Result := Tr('acao.reconfigurar');
    auTentarNovamente: Result := Tr('acao.tentar');
    auCriarBancoNovo: Result := Tr('acao.criar_novo');
    auCriarEstrutura: Result := Tr('acao.criar_estrutura');
  else
    Result := Tr('acao.sair');
  end;
end;

{ TInteracaoVcl }

function TInteracaoVcl.ConfigurarBanco(const ASugestao: TConfigBanco; APrimeiraVez: Boolean;
  out AConfig: TConfigBanco): Boolean;
var
  Padrao: TConfigBanco;
begin
  // O botão "Usar sugestões" sempre devolve os valores padrão do sistema.
  Padrao := TConfigPadrao.Sugerir(TIniConfigRepositorio.LocalizarCaminho);
  Result := TfrmConfiguracaoBanco.Executar(ASugestao, Padrao, APrimeiraVez, AConfig);
end;

function TInteracaoVcl.PerguntarAcao(AProblema: TProblemaInicializacao;
  const AConfig: TConfigBanco; const ADetalhe: string;
  const APermitidas: TAcoesUsuario): TAcaoUsuario;
var
  Legendas: TArray<string>;
  Acoes: TArray<TAcaoUsuario>;
  Acao: TAcaoUsuario;
  Icone: TIcone;
  Escolha: Integer;
begin
  for Acao := Low(TAcaoUsuario) to High(TAcaoUsuario) do
  begin
    if not (Acao in APermitidas) then
      Continue;
    SetLength(Acoes, Length(Acoes) + 1);
    Acoes[High(Acoes)] := Acao;
    SetLength(Legendas, Length(Legendas) + 1);
    Legendas[High(Legendas)] := LegendaDaAcao(Acao);
  end;

  // Problemas que se resolvem criando algo são aviso; falhas técnicas são erro.
  if AProblema in [pbConfigInvalida, pbBancoSumiu, pbSemEstrutura] then
    Icone := icInfo
  else
    Icone := icErro;

  Escolha := EscolherAcao(Tr(ChaveDoProblema(AProblema) + '.titulo'),
    TextoDoProblema(AProblema, AConfig, ADetalhe), Icone, Legendas);

  // Janela fechada no X ou com Esc: equivale a sair.
  if (Escolha >= 0) and (Escolha < Length(Acoes)) then
    Result := Acoes[Escolha]
  else
    Result := auSair;
end;

procedure TInteracaoVcl.Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
var
  Chave: string;
begin
  case AAviso of
    avBancoCriado: Chave := 'aviso.banco_criado';
    avEstruturaCriada: Chave := 'aviso.estrutura_criada';
  else
    Chave := 'aviso.estrutura_atualizada';
  end;
  MostrarAviso(Tr(Chave + '.titulo'), Tr(Chave + '.msg', [AConfig.Database]), icSucesso);
end;

end.
