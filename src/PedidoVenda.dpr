program PedidoVenda;

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  FireDAC.Comp.Client,
  Pedido.Model.Excecoes in 'Model\Pedido.Model.Excecoes.pas',
  Pedido.Model.Cliente in 'Model\Pedido.Model.Cliente.pas',
  Pedido.Model.Produto in 'Model\Pedido.Model.Produto.pas',
  Pedido.Model.PedidoItem in 'Model\Pedido.Model.PedidoItem.pas',
  Pedido.Model.Pedido in 'Model\Pedido.Model.Pedido.pas',
  Pedido.Infra.Idioma in 'Infra\Pedido.Infra.Idioma.pas',
  Pedido.Infra.Log in 'Infra\Pedido.Infra.Log.pas',
  Pedido.Infra.Versao in 'Infra\Pedido.Infra.Versao.pas',
  Pedido.Infra.Validacao in 'Infra\Pedido.Infra.Validacao.pas',
  Pedido.Infra.Config in 'Infra\Pedido.Infra.Config.pas',
  Pedido.Infra.EsquemaBanco in 'Infra\Pedido.Infra.EsquemaBanco.pas',
  Pedido.Infra.BancoDados.Tipos in 'Infra\Pedido.Infra.BancoDados.Tipos.pas',
  Pedido.Infra.BancoDados.FireDAC in 'Infra\Pedido.Infra.BancoDados.FireDAC.pas',
  Pedido.Infra.RegistroBanco in 'Infra\Pedido.Infra.RegistroBanco.pas',
  Pedido.Infra.Inicializador in 'Infra\Pedido.Infra.Inicializador.pas',
  Pedido.Infra.Conexao in 'Infra\Pedido.Infra.Conexao.pas',
  Pedido.DAO.Base in 'DAO\Pedido.DAO.Base.pas',
  Pedido.DAO.Cliente in 'DAO\Pedido.DAO.Cliente.pas',
  Pedido.DAO.Produto in 'DAO\Pedido.DAO.Produto.pas',
  Pedido.DAO.Pedido in 'DAO\Pedido.DAO.Pedido.pas',
  Pedido.DAO.Interfaces in 'DAO\Pedido.DAO.Interfaces.pas',
  Pedido.Controller.Interfaces in 'Controller\Pedido.Controller.Interfaces.pas',
  Pedido.Controller.Cliente in 'Controller\Pedido.Controller.Cliente.pas',
  Pedido.Controller.Produto in 'Controller\Pedido.Controller.Produto.pas',
  Pedido.Controller.Pedido in 'Controller\Pedido.Controller.Pedido.pas',
  Pedido.Infra.Composicao in 'Infra\Pedido.Infra.Composicao.pas',
  ComponentAccess in '..\Componentes\Componentes Pedido\Core\ComponentAccess.pas',
  ComponentTheme in '..\Componentes\Componentes Pedido\Core\ComponentTheme.pas',
  ComponentIcons in '..\Componentes\Componentes Pedido\Core\ComponentIcons.pas',
  ComponentUtils in '..\Componentes\Componentes Pedido\Core\ComponentUtils.pas',
  RoundButton in '..\Componentes\Componentes Pedido\Buttons\RoundButton.pas',
  FlagButton in '..\Componentes\Componentes Pedido\Buttons\FlagButton.pas',
  InfoCard in '..\Componentes\Componentes Pedido\Cards\InfoCard.pas',
  ModernEdit in '..\Componentes\Componentes Pedido\Edits\ModernEdit.pas',
  AlertBar in '..\Componentes\Componentes Pedido\Alerts\AlertBar.pas',
  ModernGrid in '..\Componentes\Componentes Pedido\Grids\ModernGrid.pas',
  Pedido.View.DialogoModerno in 'View\Pedido.View.DialogoModerno.pas' {frmDialogoModerno},
  Pedido.View.Dialogos in 'View\Pedido.View.Dialogos.pas',
  Pedido.View.ConfiguracaoBanco in 'View\Pedido.View.ConfiguracaoBanco.pas' {frmConfiguracaoBanco},
  Pedido.View.Inicializacao in 'View\Pedido.View.Inicializacao.pas',
  Pedido.View.NumeroPedido in 'View\Pedido.View.NumeroPedido.pas' {frmNumeroPedido},
  Pedido.View.Principal in 'View\Pedido.View.Principal.pas' {frmPedidoVenda};

{$R *.res}

procedure Avisar(const AMensagem: string);
begin
  MostrarAviso(Tr('app.titulo'), AMensagem, icErro);
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
      frmPedidoVenda.Iniciar(Composicao.Pedidos, Composicao.Clientes, Composicao.Produtos);
      Application.Run;
    finally
      Composicao.Free;
    end;
  finally
    Dono.Free;
  end;
end.
