program PedidoVenda.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Pedido.Model.Excecoes in '..\src\Model\Pedido.Model.Excecoes.pas',
  Pedido.Model.PedidoItem in '..\src\Model\Pedido.Model.PedidoItem.pas',
  Pedido.Model.Pedido in '..\src\Model\Pedido.Model.Pedido.pas',
  Pedido.Tests.Totalizacao in 'Pedido.Tests.Totalizacao.pas';

var
  Runner: ITestRunner;
  Resultado: IRunResults;
begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
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
