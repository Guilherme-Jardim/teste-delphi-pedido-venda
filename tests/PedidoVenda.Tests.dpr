program PedidoVenda.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Pedido.Domain.Erros in '..\src\Domain\Pedido.Domain.Erros.pas',
  Pedido.Domain.ObjetosValor in '..\src\Domain\Pedido.Domain.ObjetosValor.pas',
  Pedido.Domain.Cliente in '..\src\Domain\Pedido.Domain.Cliente.pas',
  Pedido.Domain.Produto in '..\src\Domain\Pedido.Domain.Produto.pas',
  Pedido.Domain.PedidoItem in '..\src\Domain\Pedido.Domain.PedidoItem.pas',
  Pedido.Domain.Pedido in '..\src\Domain\Pedido.Domain.Pedido.pas',
  Pedido.Domain.Repositorios in '..\src\Domain\Pedido.Domain.Repositorios.pas',
  Pedido.Domain.Eventos in '..\src\Domain\Pedido.Domain.Eventos.pas',
  Pedido.Application.Interfaces in '..\src\Application\Pedido.Application.Interfaces.pas',
  Pedido.Application.CasosDeUso in '..\src\Application\Pedido.Application.CasosDeUso.pas',
  Pedido.Application.Eventos in '..\src\Application\Pedido.Application.Eventos.pas',
  Pedido.Infra.Idioma in '..\src\Infrastructure\Pedido.Infra.Idioma.pas',
  Pedido.Infra.Log in '..\src\Infrastructure\Pedido.Infra.Log.pas',
  Pedido.Infra.Versao in '..\src\Infrastructure\Pedido.Infra.Versao.pas',
  Pedido.Infra.Validacao in '..\src\Infrastructure\Pedido.Infra.Validacao.pas',
  Pedido.Infra.EsquemaBanco in '..\src\Infrastructure\Pedido.Infra.EsquemaBanco.pas',
  Pedido.Infra.BancoDados.Tipos in '..\src\Infrastructure\Pedido.Infra.BancoDados.Tipos.pas',
  Pedido.Infra.BancoDados.FireDAC in '..\src\Infrastructure\Pedido.Infra.BancoDados.FireDAC.pas',
  Pedido.Infra.RegistroBanco in '..\src\Infrastructure\Pedido.Infra.RegistroBanco.pas',
  Pedido.Infra.Inicializador in '..\src\Infrastructure\Pedido.Infra.Inicializador.pas',
  Pedido.Infra.Config in '..\src\Infrastructure\Pedido.Infra.Config.pas',
  Pedido.Infra.Conexao in '..\src\Infrastructure\Pedido.Infra.Conexao.pas',
  Pedido.Infra.Persistencia.Base in '..\src\Infrastructure\Persistence\Pedido.Infra.Persistencia.Base.pas',
  Pedido.Infra.Persistencia.Cliente in '..\src\Infrastructure\Persistence\Pedido.Infra.Persistencia.Cliente.pas',
  Pedido.Infra.Persistencia.Produto in '..\src\Infrastructure\Persistence\Pedido.Infra.Persistencia.Produto.pas',
  Pedido.Infra.Persistencia.Pedido in '..\src\Infrastructure\Persistence\Pedido.Infra.Persistencia.Pedido.pas',
  Pedido.Infra.AssinanteLog in '..\src\Infrastructure\Pedido.Infra.AssinanteLog.pas',
  Pedido.Infra.Composicao in '..\src\Infrastructure\Pedido.Infra.Composicao.pas',
  Pedido.Presentation.TradutorErros in '..\src\Presentation\Pedido.Presentation.TradutorErros.pas',
  Pedido.Tests.Falsos in 'Pedido.Tests.Falsos.pas',
  Pedido.Tests.Totalizacao in 'Pedido.Tests.Totalizacao.pas',
  Pedido.Tests.ValidacaoItem in 'Pedido.Tests.ValidacaoItem.pas',
  Pedido.Tests.Idioma in 'Pedido.Tests.Idioma.pas',
  Pedido.Tests.Versao in 'Pedido.Tests.Versao.pas',
  Pedido.Tests.Dominio in 'Pedido.Tests.Dominio.pas',
  Pedido.Tests.Eventos in 'Pedido.Tests.Eventos.pas',
  Pedido.Tests.CasosDeUso in 'Pedido.Tests.CasosDeUso.pas',
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
