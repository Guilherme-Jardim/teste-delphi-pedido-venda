program PedidoVenda.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Pedido.Infra.Idioma in '..\src\Infra\Pedido.Infra.Idioma.pas',
  Pedido.Infra.Log in '..\src\Infra\Pedido.Infra.Log.pas',
  Pedido.Infra.Versao in '..\src\Infra\Pedido.Infra.Versao.pas',
  Pedido.Infra.Validacao in '..\src\Infra\Pedido.Infra.Validacao.pas',
  Pedido.Infra.EsquemaBanco in '..\src\Infra\Pedido.Infra.EsquemaBanco.pas',
  Pedido.Infra.BancoDados.Tipos in '..\src\Infra\Pedido.Infra.BancoDados.Tipos.pas',
  Pedido.Infra.BancoDados.FireDAC in '..\src\Infra\Pedido.Infra.BancoDados.FireDAC.pas',
  Pedido.Infra.RegistroBanco in '..\src\Infra\Pedido.Infra.RegistroBanco.pas',
  Pedido.Infra.Inicializador in '..\src\Infra\Pedido.Infra.Inicializador.pas',
  Pedido.Infra.Config in '..\src\Infra\Pedido.Infra.Config.pas',
  Pedido.Infra.Conexao in '..\src\Infra\Pedido.Infra.Conexao.pas',
  Pedido.Model.Excecoes in '..\src\Model\Pedido.Model.Excecoes.pas',
  Pedido.Model.Cliente in '..\src\Model\Pedido.Model.Cliente.pas',
  Pedido.Model.Produto in '..\src\Model\Pedido.Model.Produto.pas',
  Pedido.Model.PedidoItem in '..\src\Model\Pedido.Model.PedidoItem.pas',
  Pedido.Model.Pedido in '..\src\Model\Pedido.Model.Pedido.pas',
  Pedido.DAO.Base in '..\src\DAO\Pedido.DAO.Base.pas',
  Pedido.DAO.Cliente in '..\src\DAO\Pedido.DAO.Cliente.pas',
  Pedido.DAO.Produto in '..\src\DAO\Pedido.DAO.Produto.pas',
  Pedido.DAO.Pedido in '..\src\DAO\Pedido.DAO.Pedido.pas',
  Pedido.DAO.Interfaces in '..\src\DAO\Pedido.DAO.Interfaces.pas',
  Pedido.Controller.Interfaces in '..\src\Controller\Pedido.Controller.Interfaces.pas',
  Pedido.Controller.Cliente in '..\src\Controller\Pedido.Controller.Cliente.pas',
  Pedido.Controller.Produto in '..\src\Controller\Pedido.Controller.Produto.pas',
  Pedido.Controller.Pedido in '..\src\Controller\Pedido.Controller.Pedido.pas',
  Pedido.Infra.Composicao in '..\src\Infra\Pedido.Infra.Composicao.pas',
  Pedido.Tests.Falsos in 'Pedido.Tests.Falsos.pas',
  Pedido.Tests.Totalizacao in 'Pedido.Tests.Totalizacao.pas',
  Pedido.Tests.ValidacaoItem in 'Pedido.Tests.ValidacaoItem.pas',
  Pedido.Tests.Idioma in 'Pedido.Tests.Idioma.pas',
  Pedido.Tests.Versao in 'Pedido.Tests.Versao.pas',
  Pedido.Tests.Controller in 'Pedido.Tests.Controller.pas',
  Pedido.Tests.Integracao in 'Pedido.Tests.Integracao.pas',
  Pedido.Tests.Validacao in 'Pedido.Tests.Validacao.pas',
  Pedido.Tests.Config in 'Pedido.Tests.Config.pas',
  Pedido.Tests.Inicializador in 'Pedido.Tests.Inicializador.pas',
  Pedido.Tests.EsquemaESeguranca in 'Pedido.Tests.EsquemaESeguranca.pas',
  Pedido.Tests.BancoReal in 'Pedido.Tests.BancoReal.pas';

var
  Runner: ITestRunner;
  Resultado: IRunResults;
begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
    Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile));
    Resultado := Runner.Execute;
    if not Resultado.AllPassed then
      System.ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 2;
    end;
  end;
end.
