unit Pedido.Infra.Config;

{ Leitura do config.ini com os dados de conexão do Firebird. }

interface

uses
  System.SysUtils;

type
  TConfigBanco = record
    Database: string;
    Username: string;
    Password: string;
    Server: string;
    Port: Integer;
    ClientLibrary: string;
  end;

  EConfigInvalida = class(Exception);

  TConfigLoader = class
  private
    class function LocalizarArquivo: string;
    class function ResolverCaminho(const ABase, ACaminho: string): string;
  public
    class function Carregar(const ACaminho: string = ''): TConfigBanco;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils;

const
  NOME_ARQUIVO = 'config.ini';
  SECAO = 'Database';
  PORTA_PADRAO = 3050;

{ TConfigLoader }

class function TConfigLoader.LocalizarArquivo: string;
var
  Pasta: string;
  Nivel: Integer;
begin
  // O config.ini fica na raiz do projeto; o executável costuma estar em
  // subpastas (Win32\Debug, bin\...), então sobe alguns níveis procurando.
  Pasta := ExtractFilePath(ParamStr(0));
  for Nivel := 0 to 5 do
  begin
    Result := TPath.Combine(Pasta, NOME_ARQUIVO);
    if TFile.Exists(Result) then
      Exit;
    Pasta := ExtractFilePath(ExcludeTrailingPathDelimiter(Pasta));
    if Pasta = '' then
      Break;
  end;
  Result := TPath.Combine(GetCurrentDir, NOME_ARQUIVO);
end;

class function TConfigLoader.ResolverCaminho(const ABase, ACaminho: string): string;
begin
  if (ACaminho = '') or TPath.IsPathRooted(ACaminho) then
    Result := ACaminho
  else
    Result := TPath.GetFullPath(TPath.Combine(ABase, ACaminho));
end;

class function TConfigLoader.Carregar(const ACaminho: string): TConfigBanco;
var
  Arquivo: string;
  Ini: TIniFile;
begin
  if ACaminho <> '' then
    Arquivo := ACaminho
  else
    Arquivo := LocalizarArquivo;

  if not TFile.Exists(Arquivo) then
    raise EConfigInvalida.CreateFmt(
      'Arquivo %s não encontrado. Copie o config.ini.example para config.ini ' +
      'na raiz do projeto e ajuste os dados.', [NOME_ARQUIVO]);

  Ini := TIniFile.Create(Arquivo);
  try
    Result.Database := Trim(Ini.ReadString(SECAO, 'Database', ''));
    Result.Username := Trim(Ini.ReadString(SECAO, 'Username', ''));
    Result.Password := Ini.ReadString(SECAO, 'Password', '');
    Result.Server := Trim(Ini.ReadString(SECAO, 'Server', ''));
    Result.Port := Ini.ReadInteger(SECAO, 'Port', PORTA_PADRAO);
    Result.ClientLibrary := Trim(Ini.ReadString(SECAO, 'ClientLibrary', ''));
  finally
    Ini.Free;
  end;

  if Result.Database = '' then
    raise EConfigInvalida.Create('Informe o campo Database no config.ini.');
  if Result.Username = '' then
    raise EConfigInvalida.Create('Informe o campo Username no config.ini.');
  if Result.ClientLibrary = '' then
    raise EConfigInvalida.Create('Informe o campo ClientLibrary (fbclient.dll) no config.ini.');

  // Caminhos relativos valem a partir da pasta do config.ini.
  Result.ClientLibrary := ResolverCaminho(ExtractFilePath(Arquivo), Result.ClientLibrary);
  if not TFile.Exists(Result.ClientLibrary) then
    raise EConfigInvalida.CreateFmt('fbclient.dll não encontrada em: %s', [Result.ClientLibrary]);
end;

end.
