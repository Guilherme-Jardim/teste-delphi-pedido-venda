unit Pedido.Presentation.Inicializacao;

{ Janelas da inicialização: avisos com botões de ação (TTaskDialog) e a tela
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
  System.UITypes,
  Vcl.Dialogs,
  Pedido.Infra.Idioma,
  Pedido.Presentation.ConfiguracaoBanco;

const
  // ModalResult de cada botão = BASE + ordem da ação.
  BASE_RESULTADO = 100;

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
  Dialogo: TTaskDialog;
  Botao: TTaskDialogButtonItem;
  Acao: TAcaoUsuario;
  Primeiro: Boolean;
begin
  Result := auSair;
  Dialogo := TTaskDialog.Create(nil);
  try
    Dialogo.Caption := Tr('app.titulo');
    Dialogo.Title := Tr(ChaveDoProblema(AProblema) + '.titulo');
    Dialogo.Text := TextoDoProblema(AProblema, AConfig, ADetalhe);
    Dialogo.CommonButtons := [];
    Dialogo.Flags := [tfAllowDialogCancellation, tfUseCommandLinks];
    if AProblema in [pbConfigInvalida, pbBancoSumiu, pbSemEstrutura] then
      Dialogo.MainIcon := tdiWarning
    else
      Dialogo.MainIcon := tdiError;

    Primeiro := True;
    for Acao := Low(TAcaoUsuario) to High(TAcaoUsuario) do
    begin
      if not (Acao in APermitidas) then
        Continue;
      Botao := TTaskDialogButtonItem(Dialogo.Buttons.Add);
      Botao.Caption := LegendaDaAcao(Acao);
      Botao.ModalResult := BASE_RESULTADO + Ord(Acao);
      Botao.Default := Primeiro;
      Primeiro := False;
    end;

    if Dialogo.Execute then
    begin
      for Acao := Low(TAcaoUsuario) to High(TAcaoUsuario) do
        if (Acao in APermitidas) and (Dialogo.ModalResult = BASE_RESULTADO + Ord(Acao)) then
          Exit(Acao);
    end;
    // Janela fechada no X ou com Esc: equivale a sair.
    Result := auSair;
  finally
    Dialogo.Free;
  end;
end;

procedure TInteracaoVcl.Informar(AAviso: TAvisoInicializacao; const AConfig: TConfigBanco);
var
  Dialogo: TTaskDialog;
  Chave: string;
begin
  case AAviso of
    avBancoCriado: Chave := 'aviso.banco_criado';
    avEstruturaCriada: Chave := 'aviso.estrutura_criada';
  else
    Chave := 'aviso.estrutura_atualizada';
  end;
  Dialogo := TTaskDialog.Create(nil);
  try
    Dialogo.Caption := Tr('app.titulo');
    Dialogo.Title := Tr(Chave + '.titulo');
    Dialogo.Text := Tr(Chave + '.msg', [AConfig.Database]);
    Dialogo.MainIcon := tdiInformation;
    Dialogo.CommonButtons := [tcbOk];
    Dialogo.Execute;
  finally
    Dialogo.Free;
  end;
end;

end.
