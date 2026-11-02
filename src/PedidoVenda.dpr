program PedidoVenda;

uses
  Vcl.Forms,
  Vcl.Controls,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  FireDAC.Comp.Client,
  Pedido.Model.Excecoes in 'Model\Pedido.Model.Excecoes.pas',
  Pedido.Model.Cliente in 'Model\Pedido.Model.Cliente.pas',
  Pedido.Model.Produto in 'Model\Pedido.Model.Produto.pas',
  Pedido.Model.PedidoItem in 'Model\Pedido.Model.PedidoItem.pas',
  Pedido.Model.Pedido in 'Model\Pedido.Model.Pedido.pas',
  Pedido.Infra.Config in 'Infra\Pedido.Infra.Config.pas',
  Pedido.Infra.Conexao in 'Infra\Pedido.Infra.Conexao.pas',
  Pedido.Repository.Interfaces in 'Repository\Pedido.Repository.Interfaces.pas',
  Pedido.Repository.Base in 'Repository\Pedido.Repository.Base.pas',
  Pedido.Repository.Cliente in 'Repository\Pedido.Repository.Cliente.pas',
  Pedido.Repository.Produto in 'Repository\Pedido.Repository.Produto.pas',
  Pedido.Repository.Pedido in 'Repository\Pedido.Repository.Pedido.pas',
  Pedido.Service.Pedido in 'Service\Pedido.Service.Pedido.pas',
  Pedido.Controller.Pedido in 'Controller\Pedido.Controller.Pedido.pas',
  Pedido.View.Principal in 'View\Pedido.View.Principal.pas' {frmPedidoVenda};

{$R *.res}

procedure Avisar(const AMensagem: string);
begin
  Application.MessageBox(PChar(AMensagem), 'Pedido de Venda', MB_OK or MB_ICONERROR);
end;

var
  Config: TConfigBanco;
  Dono: TComponent;
  Conexao: TFDConnection;
  Servico: TPedidoService;
  Controller: TPedidoController;
begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  Dono := TComponent.Create(nil);
  try
    try
      Config := TConfigLoader.Carregar;
      Conexao := TFabricaConexao.Criar(Config, Dono);
      Conexao.Connected := True;
    except
      on E: Exception do
      begin
        Avisar('Não foi possível iniciar a aplicação:' + sLineBreak + E.Message);
        Exit;
      end;
    end;

    Servico := TPedidoService.Create(
      TClienteRepository.Create(Conexao),
      TProdutoRepository.Create(Conexao),
      TPedidoRepository.Create(Conexao));
    try
      Controller := TPedidoController.Create(Servico);
      try
        Application.CreateForm(TfrmPedidoVenda, frmPedidoVenda);
        frmPedidoVenda.Iniciar(Controller);
        Application.Run;
      finally
        Controller.Free;
      end;
    finally
      Servico.Free;
    end;
  finally
    Dono.Free;
  end;
end.
