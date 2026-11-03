program PedidoVenda;

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  FireDAC.Comp.Client,
  Pedido.Domain.Erros in 'Domain\Pedido.Domain.Erros.pas',
  Pedido.Domain.ObjetosValor in 'Domain\Pedido.Domain.ObjetosValor.pas',
  Pedido.Domain.Cliente in 'Domain\Pedido.Domain.Cliente.pas',
  Pedido.Domain.Produto in 'Domain\Pedido.Domain.Produto.pas',
  Pedido.Domain.PedidoItem in 'Domain\Pedido.Domain.PedidoItem.pas',
  Pedido.Domain.Pedido in 'Domain\Pedido.Domain.Pedido.pas',
  Pedido.Domain.Repositorios in 'Domain\Pedido.Domain.Repositorios.pas',
  Pedido.Domain.Eventos in 'Domain\Pedido.Domain.Eventos.pas',
  Pedido.Application.Interfaces in 'Application\Pedido.Application.Interfaces.pas',
  Pedido.Application.CasosDeUso in 'Application\Pedido.Application.CasosDeUso.pas',
  Pedido.Application.Eventos in 'Application\Pedido.Application.Eventos.pas',
  Pedido.Infra.Idioma in 'Infrastructure\Pedido.Infra.Idioma.pas',
  Pedido.Infra.Log in 'Infrastructure\Pedido.Infra.Log.pas',
  Pedido.Infra.Versao in 'Infrastructure\Pedido.Infra.Versao.pas',
  Pedido.Infra.Validacao in 'Infrastructure\Pedido.Infra.Validacao.pas',
  Pedido.Infra.Config in 'Infrastructure\Pedido.Infra.Config.pas',
  Pedido.Infra.EsquemaBanco in 'Infrastructure\Pedido.Infra.EsquemaBanco.pas',
  Pedido.Infra.BancoDados.Tipos in 'Infrastructure\Pedido.Infra.BancoDados.Tipos.pas',
  Pedido.Infra.BancoDados.FireDAC in 'Infrastructure\Pedido.Infra.BancoDados.FireDAC.pas',
  Pedido.Infra.RegistroBanco in 'Infrastructure\Pedido.Infra.RegistroBanco.pas',
  Pedido.Infra.Inicializador in 'Infrastructure\Pedido.Infra.Inicializador.pas',
  Pedido.Infra.Conexao in 'Infrastructure\Pedido.Infra.Conexao.pas',
  Pedido.Infra.Persistencia.Base in 'Infrastructure\Persistence\Pedido.Infra.Persistencia.Base.pas',
  Pedido.Infra.Persistencia.Cliente in 'Infrastructure\Persistence\Pedido.Infra.Persistencia.Cliente.pas',
  Pedido.Infra.Persistencia.Produto in 'Infrastructure\Persistence\Pedido.Infra.Persistencia.Produto.pas',
  Pedido.Infra.Persistencia.Pedido in 'Infrastructure\Persistence\Pedido.Infra.Persistencia.Pedido.pas',
  Pedido.Infra.AssinanteLog in 'Infrastructure\Pedido.Infra.AssinanteLog.pas',
  Pedido.Infra.Composicao in 'Infrastructure\Pedido.Infra.Composicao.pas',
  ComponentTheme in '..\Componentes\Componentes Pedido\Core\ComponentTheme.pas',
  ComponentIcons in '..\Componentes\Componentes Pedido\Core\ComponentIcons.pas',
  ComponentUtils in '..\Componentes\Componentes Pedido\Core\ComponentUtils.pas',
  RoundButton in '..\Componentes\Componentes Pedido\Buttons\RoundButton.pas',
  FlagButton in '..\Componentes\Componentes Pedido\Buttons\FlagButton.pas',
  InfoCard in '..\Componentes\Componentes Pedido\Cards\InfoCard.pas',
  ModernEdit in '..\Componentes\Componentes Pedido\Edits\ModernEdit.pas',
  AlertBar in '..\Componentes\Componentes Pedido\Alerts\AlertBar.pas',
  ModernGrid in '..\Componentes\Componentes Pedido\Grids\ModernGrid.pas',
  Pedido.Presentation.TradutorErros in 'Presentation\Pedido.Presentation.TradutorErros.pas',
  Pedido.Presentation.Dialogos in 'Presentation\Pedido.Presentation.Dialogos.pas',
  Pedido.Presentation.ConfiguracaoBanco in 'Presentation\Pedido.Presentation.ConfiguracaoBanco.pas' {frmConfiguracaoBanco},
  Pedido.Presentation.Inicializacao in 'Presentation\Pedido.Presentation.Inicializacao.pas',
  Pedido.Presentation.NumeroPedido in 'Presentation\Pedido.Presentation.NumeroPedido.pas' {frmNumeroPedido},
  Pedido.Presentation.Principal in 'Presentation\Pedido.Presentation.Principal.pas' {frmPedidoVenda};

{$R *.res}

procedure Avisar(const AMensagem: string);
begin
  Application.MessageBox(PChar(AMensagem), PChar(Tr('app.titulo')), MB_OK or MB_ICONERROR);
end;

var
  Config: TConfigBanco;
  Inicializador: TInicializadorSistema;
  Dono: TComponent;
  Conexao: TFDConnection;
  Composicao: TComposicaoSistema;
begin
  // O relatório de vazamentos só aparece ao rodar pelo depurador.
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  CarregarIdiomaSalvo;
  Application.Title := Tr('app.titulo');
  RegistrarInformacao('Pedido de Venda ' + VersaoDoExecutavel.Completa + ' iniciado');

  // 1) config.ini e banco: cria ou ajusta o que faltar, perguntando quando for preciso.
  Inicializador := TInicializadorSistema.Create(TIniConfigRepositorio.Create,
    TInspetorBancoFireDAC.Create, TCriadorBancoFireDAC.Create, TRegistroBancoArquivo.Create,
    TInteracaoVcl.Create);
  try
    if not Inicializador.Executar(Config) then
      Exit;
  finally
    Inicializador.Free;
  end;

  Dono := TComponent.Create(nil);
  try
    try
      Conexao := TFabricaConexao.Criar(Config, Dono);
      Conexao.Connected := True;
    except
      on E: Exception do
      begin
        RegistrarLog('Falha ao conectar depois da inicialização', E);
        Avisar(Tr('app.falha_iniciar') + sLineBreak + sLineBreak + Tr('msg.falha_consulta'));
        Exit;
      end;
    end;

    Composicao := TComposicaoSistema.Create(Conexao);
    try
      Application.CreateForm(TfrmPedidoVenda, frmPedidoVenda);
      frmPedidoVenda.Iniciar(Composicao.CasosDeUso);
      Application.Run;
    finally
      Composicao.Free;
    end;
  finally
    Dono.Free;
  end;
end.
