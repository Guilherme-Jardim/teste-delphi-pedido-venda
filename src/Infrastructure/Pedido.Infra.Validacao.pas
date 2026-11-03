unit Pedido.Infra.Validacao;

{ Validação de tudo que vem de fora (INI, tela de configuração): servidor,
  porta, caminhos, usuário e senha. Nada que passe daqui chega a virar SQL:
  o único texto livre que o sistema usa para criar o banco é o caminho do
  arquivo, e ele só vai como parâmetro de conexão do FireDAC. }

interface

type
  TValidadorEntrada = class
  public
    // Cada método devolve True se o valor é aceitável; senão, AMotivo explica.
    class function Servidor(const AValor: string; out AMotivo: string): Boolean; static;
    class function Porta(AValor: Integer; out AMotivo: string): Boolean; static;
    class function CaminhoBanco(const AValor: string; out AMotivo: string): Boolean; static;
    class function Usuario(const AValor: string; out AMotivo: string): Boolean; static;
    class function Senha(const AValor: string; out AMotivo: string): Boolean; static;
    class function BibliotecaCliente(const AValor: string; out AMotivo: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Pedido.Infra.Idioma;

const
  TAMANHO_MAXIMO_CAMINHO = 255;
  TAMANHO_MAXIMO_USUARIO = 31;
  TAMANHO_MAXIMO_SENHA = 64;
  CARACTERES_PROIBIDOS_CAMINHO = ['"', '''', '<', '>', '|', '*', '?', ';', '`', '%'];

function TemCaractereDeControle(const AValor: string): Boolean;
var
  Caractere: Char;
begin
  for Caractere in AValor do
    if Ord(Caractere) < 32 then
      Exit(True);
  Result := False;
end;

function TemCaractereProibido(const AValor: string): Boolean;
var
  Caractere: Char;
begin
  for Caractere in AValor do
    if (Ord(Caractere) < 128) and CharInSet(Caractere, CARACTERES_PROIBIDOS_CAMINHO) then
      Exit(True);
  Result := False;
end;

class function TValidadorEntrada.Servidor(const AValor: string; out AMotivo: string): Boolean;
var
  Caractere: Char;
begin
  Result := False;
  AMotivo := '';
  // Servidor vazio significa conexão local/embarcada: é permitido.
  if AValor = '' then
    Exit(True);
  if Length(AValor) > TAMANHO_MAXIMO_CAMINHO then
  begin
    AMotivo := Tr('val.servidor_longo');
    Exit;
  end;
  for Caractere in AValor do
    if not (CharInSet(Caractere, ['a'..'z', 'A'..'Z', '0'..'9', '.', '-', '_', ':', '[', ']'])) then
    begin
      AMotivo := Tr('val.servidor_invalido');
      Exit;
    end;
  Result := True;
end;

class function TValidadorEntrada.Porta(AValor: Integer; out AMotivo: string): Boolean;
begin
  Result := (AValor >= 1) and (AValor <= 65535);
  if Result then
    AMotivo := ''
  else
    AMotivo := Tr('val.porta_invalida');
end;

class function TValidadorEntrada.CaminhoBanco(const AValor: string; out AMotivo: string): Boolean;
var
  Extensao: string;
begin
  Result := False;
  AMotivo := '';
  if Trim(AValor) = '' then
  begin
    AMotivo := Tr('val.banco_vazio');
    Exit;
  end;
  if Length(AValor) > TAMANHO_MAXIMO_CAMINHO then
  begin
    AMotivo := Tr('val.banco_longo');
    Exit;
  end;
  if TemCaractereDeControle(AValor) or TemCaractereProibido(AValor) then
  begin
    AMotivo := Tr('val.banco_caracteres');
    Exit;
  end;
  if Pos('..', AValor) > 0 then
  begin
    AMotivo := Tr('val.banco_caracteres');
    Exit;
  end;
  Extensao := LowerCase(ExtractFileExt(AValor));
  if (Extensao <> '.fdb') and (Extensao <> '.gdb') and (Extensao <> '.fb') then
  begin
    AMotivo := Tr('val.banco_extensao');
    Exit;
  end;
  Result := True;
end;

class function TValidadorEntrada.Usuario(const AValor: string; out AMotivo: string): Boolean;
var
  Caractere: Char;
begin
  Result := False;
  AMotivo := '';
  if (AValor = '') or (Length(AValor) > TAMANHO_MAXIMO_USUARIO) then
  begin
    AMotivo := Tr('val.usuario_invalido');
    Exit;
  end;
  for Caractere in AValor do
    if not CharInSet(Caractere, ['a'..'z', 'A'..'Z', '0'..'9', '_', '$', '.', '-']) then
    begin
      AMotivo := Tr('val.usuario_invalido');
      Exit;
    end;
  Result := True;
end;

class function TValidadorEntrada.Senha(const AValor: string; out AMotivo: string): Boolean;
begin
  AMotivo := '';
  Result := (Length(AValor) <= TAMANHO_MAXIMO_SENHA) and not TemCaractereDeControle(AValor);
  if not Result then
    AMotivo := Tr('val.senha_invalida');
end;

class function TValidadorEntrada.BibliotecaCliente(const AValor: string;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';
  Result := (Trim(AValor) <> '') and (Length(AValor) <= TAMANHO_MAXIMO_CAMINHO) and
    not TemCaractereDeControle(AValor) and not TemCaractereProibido(AValor) and
    SameText(ExtractFileExt(AValor), '.dll');
  if not Result then
    AMotivo := Tr('val.biblioteca_invalida');
end;

end.
