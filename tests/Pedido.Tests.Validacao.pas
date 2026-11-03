unit Pedido.Tests.Validacao;

{ Validação das entradas de configuração: o que é aceito e o que é recusado,
  incluindo tentativas típicas de injeção. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesValidacao = class
  public
    [Setup]
    procedure Setup;

    [TestCase('Windows', 'C:\dados\PEDIDOS.FDB')]
    [TestCase('Pasta com espaco', 'C:\Meus Dados\Pedidos Venda.fdb')]
    [TestCase('Rede', '\\servidor\banco\PEDIDOS.FDB')]
    [TestCase('Acentos', 'C:\Dados Joao\Pedidos.fdb')]
    [TestCase('gdb antigo', 'D:\banco.gdb')]
    [TestCase('fb', 'D:\banco.fb')]
    procedure CaminhoValidoEAceito(const ACaminho: string);

    [TestCase('Vazio', '')]
    [TestCase('Extensao errada', 'C:\dados\PEDIDOS.txt')]
    [TestCase('Sem extensao', 'C:\dados\PEDIDOS')]
    [TestCase('Aspas simples', 'C:\dados\x''.fdb')]
    [TestCase('Aspas duplas', 'C:\dados\x".fdb')]
    [TestCase('Ponto e virgula', 'C:\dados\x.fdb;DROP TABLE CLIENTE')]
    [TestCase('Injecao classica', 'C:\a.fdb''; DROP TABLE CLIENTE;--')]
    [TestCase('Volta de pasta', 'C:\dados\..\..\x.fdb')]
    [TestCase('Redirecionamento', 'C:\dados\x.fdb|calc')]
    [TestCase('Curinga', 'C:\dados\*.fdb')]
    [TestCase('Variavel de ambiente', '%TEMP%\x.fdb')]
    [TestCase('Crase', 'C:\dados\`x`.fdb')]
    procedure CaminhoPerigosoEhRecusado(const ACaminho: string);

    [Test]
    procedure CaminhoComCaractereDeControleEhRecusado;
    [Test]
    procedure CaminhoMuitoLongoEhRecusado;

    [TestCase('Vazio e permitido', '')]
    [TestCase('localhost', 'localhost')]
    [TestCase('IPv4', '192.168.0.10')]
    [TestCase('Nome com hifen', 'srv-banco.empresa.com.br')]
    [TestCase('IPv6', '[::1]')]
    procedure ServidorValidoEAceito(const AServidor: string);

    [TestCase('Espaco', 'meu servidor')]
    [TestCase('Ponto e virgula', 'srv;DROP')]
    [TestCase('Barra', 'srv/banco')]
    [TestCase('Aspas', 'srv''x')]
    procedure ServidorInvalidoEhRecusado(const AServidor: string);

    [TestCase('Minima', '1,True')]
    [TestCase('Padrao', '3050,True')]
    [TestCase('Maxima', '65535,True')]
    [TestCase('Zero', '0,False')]
    [TestCase('Negativa', '-1,False')]
    [TestCase('Acima', '65536,False')]
    procedure PortaTemFaixaValida(APorta: Integer; AEsperado: Boolean);

    [TestCase('SYSDBA', 'SYSDBA')]
    [TestCase('Com underline', 'app_pedidos')]
    [TestCase('Com ponto', 'joao.silva')]
    procedure UsuarioValidoEAceito(const AUsuario: string);

    [TestCase('Vazio', '')]
    [TestCase('Espaco', 'joao silva')]
    [TestCase('Aspas', 'x''y')]
    [TestCase('Ponto e virgula', 'a;b')]
    [TestCase('Barra', 'a\b')]
    procedure UsuarioInvalidoEhRecusado(const AUsuario: string);

    [Test]
    procedure UsuarioMuitoLongoEhRecusado;
    [Test]
    procedure SenhaComCaracteresEspeciaisEhAceita;
    [Test]
    procedure SenhaComQuebraDeLinhaEhRecusada;
    [Test]
    procedure SenhaMuitoLongaEhRecusada;

    [TestCase('Relativo', 'bin\Win32\fbclient.dll')]
    [TestCase('Absoluto', 'C:\Program Files\Firebird\fbclient.dll')]
    procedure BibliotecaValidaEAceita(const ACaminho: string);

    [TestCase('Executavel', 'C:\x\fbclient.exe')]
    [TestCase('Vazia', '')]
    [TestCase('Aspas', 'C:\x\"fbclient.dll')]
    [TestCase('Comando', 'fbclient.dll;calc')]
    procedure BibliotecaInvalidaEhRecusada(const ACaminho: string);

    [Test]
    procedure MotivoSegueOIdiomaEscolhido;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Idioma,
  Pedido.Infra.Validacao;

procedure TTestesValidacao.Setup;
begin
  DefinirIdioma(idPortugues, False);
end;

procedure TTestesValidacao.CaminhoValidoEAceito(const ACaminho: string);
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.CaminhoBanco(ACaminho, Motivo), Motivo);
end;

procedure TTestesValidacao.CaminhoPerigosoEhRecusado(const ACaminho: string);
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.CaminhoBanco(ACaminho, Motivo));
  Assert.IsNotEmpty(Motivo);
end;

procedure TTestesValidacao.CaminhoComCaractereDeControleEhRecusado;
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.CaminhoBanco('C:\dados\x' + #13#10 + '.fdb', Motivo));
  Assert.IsFalse(TValidadorEntrada.CaminhoBanco('C:\dados\x' + #0 + '.fdb', Motivo));
end;

procedure TTestesValidacao.CaminhoMuitoLongoEhRecusado;
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.CaminhoBanco('C:\' + StringOfChar('a', 300) + '.fdb', Motivo));
end;

procedure TTestesValidacao.ServidorValidoEAceito(const AServidor: string);
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.Servidor(AServidor, Motivo), Motivo);
end;

procedure TTestesValidacao.ServidorInvalidoEhRecusado(const AServidor: string);
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.Servidor(AServidor, Motivo));
end;

procedure TTestesValidacao.PortaTemFaixaValida(APorta: Integer; AEsperado: Boolean);
var
  Motivo: string;
begin
  Assert.AreEqual(AEsperado, TValidadorEntrada.Porta(APorta, Motivo));
end;

procedure TTestesValidacao.UsuarioValidoEAceito(const AUsuario: string);
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.Usuario(AUsuario, Motivo), Motivo);
end;

procedure TTestesValidacao.UsuarioInvalidoEhRecusado(const AUsuario: string);
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.Usuario(AUsuario, Motivo));
end;

procedure TTestesValidacao.UsuarioMuitoLongoEhRecusado;
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.Usuario(StringOfChar('a', 31), Motivo));
  Assert.IsFalse(TValidadorEntrada.Usuario(StringOfChar('a', 32), Motivo));
end;

procedure TTestesValidacao.SenhaComCaracteresEspeciaisEhAceita;
var
  Motivo: string;
begin
  // A senha pode ter aspas, ponto e vírgula e acentos: ela nunca vira SQL.
  Assert.IsTrue(TValidadorEntrada.Senha('S3nh@ ''com'' "aspas"; ç', Motivo), Motivo);
  Assert.IsTrue(TValidadorEntrada.Senha('', Motivo));
end;

procedure TTestesValidacao.SenhaComQuebraDeLinhaEhRecusada;
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.Senha('abc' + #13#10 + '[Outra]', Motivo));
end;

procedure TTestesValidacao.SenhaMuitoLongaEhRecusada;
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.Senha(StringOfChar('x', 64), Motivo));
  Assert.IsFalse(TValidadorEntrada.Senha(StringOfChar('x', 65), Motivo));
end;

procedure TTestesValidacao.BibliotecaValidaEAceita(const ACaminho: string);
var
  Motivo: string;
begin
  Assert.IsTrue(TValidadorEntrada.BibliotecaCliente(ACaminho, Motivo), Motivo);
end;

procedure TTestesValidacao.BibliotecaInvalidaEhRecusada(const ACaminho: string);
var
  Motivo: string;
begin
  Assert.IsFalse(TValidadorEntrada.BibliotecaCliente(ACaminho, Motivo));
end;

procedure TTestesValidacao.MotivoSegueOIdiomaEscolhido;
var
  MotivoPt, MotivoEs: string;
begin
  DefinirIdioma(idPortugues, False);
  TValidadorEntrada.Porta(0, MotivoPt);
  DefinirIdioma(idEspanhol, False);
  TValidadorEntrada.Porta(0, MotivoEs);
  DefinirIdioma(idPortugues, False);
  Assert.AreNotEqual(MotivoPt, MotivoEs);
  Assert.Contains(MotivoPt, 'porta');
  Assert.Contains(MotivoEs, 'puerta');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesValidacao);

end.
