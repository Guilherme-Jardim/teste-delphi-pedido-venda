unit Pedido.Infra.Config;

{ Configuração da conexão com o Firebird (config.ini).

  Quem lê e grava o arquivo é o TIniConfigRepositorio; as regras de cada campo
  ficam em Pedido.Infra.Validacao. O restante do sistema só conhece
  IConfigRepositorio, então dá para trocar o INI por outro formato sem
  mexer no resto, e os testes usam arquivos temporários. }

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
    // Servidor vazio (conexão embarcada) ou a própria máquina.
    function EhServidorLocal: Boolean;
    // Identifica o banco (servidor + porta + arquivo), em minúsculas.
    function Chave: string;
  end;

  TResultadoConfig = (rcOk, rcAusente, rcInvalida);

  EConfigInvalida = class(Exception);

  IConfigRepositorio = interface
    ['{5B8E2F10-7A43-4C96-B1D5-0E3F9A6C8D24}']
    function Caminho: string;
    // rcAusente: arquivo não existe (primeira execução).
    // rcInvalida: existe, mas não dá para usar; AMotivo explica e AConfig traz o que foi possível ler.
    function Carregar(out AConfig: TConfigBanco; out AMotivo: string): TResultadoConfig;
    // Valida e grava de forma atômica (arquivo temporário + troca).
    procedure Salvar(const AConfig: TConfigBanco);
    // Copia o arquivo atual para config.ini.bak-AAAAMMDD-HHMMSS e devolve o caminho ('' se não havia arquivo).
    function GuardarCopia: string;
  end;

  // Sugestões para a primeira execução e para completar campos que faltam.
  TConfigPadrao = class
  public
    class function Sugerir(const ACaminhoIni: string): TConfigBanco; static;
    // Preenche com a sugestão os campos vazios ou inválidos de AConfig.
    class function Completar(const AConfig: TConfigBanco; const ASugestao: TConfigBanco): TConfigBanco; static;
  end;

  TIniConfigRepositorio = class(TInterfacedObject, IConfigRepositorio)
  private
    FCaminho: string;
    function ResolverBiblioteca(const AValor: string): string;
    function BibliotecaParaGravar(const AValor: string): string;
  public
    // ACaminho vazio: procura o config.ini subindo pastas a partir do executável.
    constructor Create(const ACaminho: string = '');
    class function LocalizarCaminho: string; static;
    function Caminho: string;
    function Carregar(out AConfig: TConfigBanco; out AMotivo: string): TResultadoConfig;
    procedure Salvar(const AConfig: TConfigBanco);
    function GuardarCopia: string;
  end;

implementation

uses
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  Pedido.Infra.Idioma,
  Pedido.Infra.Validacao;

const
  NOME_ARQUIVO = 'config.ini';
  SECAO = 'Database';
  PORTA_PADRAO = 3050;
  NIVEIS_DE_BUSCA = 6;

{ TConfigBanco }

function TConfigBanco.EhServidorLocal: Boolean;
begin
  Result := (Trim(Server) = '') or SameText(Server, 'localhost') or (Server = '127.0.0.1') or
    (Server = '::1') or (Server = '[::1]') or SameText(Server, GetEnvironmentVariable('COMPUTERNAME'));
end;

function TConfigBanco.Chave: string;
begin
  Result := LowerCase(Trim(Server)) + '|' + IntToStr(Port) + '|' + LowerCase(Trim(Database));
end;

{ TConfigPadrao }

class function TConfigPadrao.Sugerir(const ACaminhoIni: string): TConfigBanco;
var
  Pasta, DadosComuns, Subpasta: string;
begin
  Pasta := ExtractFilePath(ACaminhoIni);
  DadosComuns := GetEnvironmentVariable('PROGRAMDATA');
  if DadosComuns = '' then
    DadosComuns := TPath.Combine(Pasta, 'dados')
  else
    DadosComuns := TPath.Combine(DadosComuns, 'PedidoVenda');

  // O serviço do Firebird costuma rodar como SYSTEM: ProgramData é um lugar onde ele consegue gravar.
  Result.Database := TPath.Combine(TPath.Combine(DadosComuns, 'dados'), 'PEDIDOS.FDB');
  Result.Username := 'SYSDBA';
  Result.Password := '';
  Result.Server := 'localhost';
  Result.Port := PORTA_PADRAO;
  {$IFDEF WIN64}
  Subpasta := 'Win64';
  {$ELSE}
  Subpasta := 'Win32';
  {$ENDIF}
  Result.ClientLibrary := TPath.GetFullPath(TPath.Combine(Pasta, TPath.Combine('bin', TPath.Combine(Subpasta, 'fbclient.dll'))));
end;

class function TConfigPadrao.Completar(const AConfig: TConfigBanco;
  const ASugestao: TConfigBanco): TConfigBanco;
var
  Motivo: string;
begin
  Result := AConfig;
  if not TValidadorEntrada.CaminhoBanco(Result.Database, Motivo) then
    Result.Database := ASugestao.Database;
  if not TValidadorEntrada.Usuario(Result.Username, Motivo) then
    Result.Username := ASugestao.Username;
  if not TValidadorEntrada.Servidor(Result.Server, Motivo) then
    Result.Server := ASugestao.Server;
  if not TValidadorEntrada.Porta(Result.Port, Motivo) then
    Result.Port := ASugestao.Port;
  if not TValidadorEntrada.Senha(Result.Password, Motivo) then
    Result.Password := '';
  if not TValidadorEntrada.BibliotecaCliente(Result.ClientLibrary, Motivo) then
    Result.ClientLibrary := ASugestao.ClientLibrary;
end;

{ TIniConfigRepositorio }

constructor TIniConfigRepositorio.Create(const ACaminho: string);
begin
  inherited Create;
  if ACaminho <> '' then
    FCaminho := ACaminho
  else
    FCaminho := LocalizarCaminho;
end;

class function TIniConfigRepositorio.LocalizarCaminho: string;
var
  Pasta: string;
  Nivel: Integer;
begin
  // 1) config.ini já existente em alguma pasta acima do executável
  Pasta := ExtractFilePath(ParamStr(0));
  for Nivel := 0 to NIVEIS_DE_BUSCA do
  begin
    Result := TPath.Combine(Pasta, NOME_ARQUIVO);
    if TFile.Exists(Result) then
      Exit;
    Pasta := ExtractFilePath(ExcludeTrailingPathDelimiter(Pasta));
    if Pasta = '' then
      Break;
  end;

  // 2) raiz do projeto: a pasta que tem o config.ini.example
  Pasta := ExtractFilePath(ParamStr(0));
  for Nivel := 0 to NIVEIS_DE_BUSCA do
  begin
    if TFile.Exists(TPath.Combine(Pasta, NOME_ARQUIVO + '.example')) then
      Exit(TPath.Combine(Pasta, NOME_ARQUIVO));
    Pasta := ExtractFilePath(ExcludeTrailingPathDelimiter(Pasta));
    if Pasta = '' then
      Break;
  end;

  // 3) ao lado do executável
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), NOME_ARQUIVO);
end;

function TIniConfigRepositorio.Caminho: string;
begin
  Result := FCaminho;
end;

function TIniConfigRepositorio.ResolverBiblioteca(const AValor: string): string;
begin
  if (AValor = '') or TPath.IsPathRooted(AValor) then
    Result := AValor
  else
    Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(FCaminho), AValor));
end;

function TIniConfigRepositorio.BibliotecaParaGravar(const AValor: string): string;
var
  Base: string;
begin
  // Dentro da pasta do projeto, grava o caminho relativo (o projeto continua funcionando se for movido).
  Base := IncludeTrailingPathDelimiter(ExtractFilePath(FCaminho));
  if SameText(Copy(AValor, 1, Length(Base)), Base) then
    Result := Copy(AValor, Length(Base) + 1, MaxInt)
  else
    Result := AValor;
end;

function TIniConfigRepositorio.Carregar(out AConfig: TConfigBanco;
  out AMotivo: string): TResultadoConfig;
var
  Ini: TMemIniFile;
  TextoPorta, Detalhe: string;

  function Falha(const ACampo, ADetalhe: string): TResultadoConfig;
  begin
    AMotivo := Tr('cfg.motivo_campo', [ACampo, ADetalhe]);
    Result := rcInvalida;
  end;

begin
  AConfig := Default(TConfigBanco);
  AMotivo := '';
  if not TFile.Exists(FCaminho) then
    Exit(rcAusente);

  try
    Ini := TMemIniFile.Create(FCaminho, TEncoding.UTF8);
  except
    AMotivo := Tr('cfg.motivo_ilegivel');
    Exit(rcInvalida);
  end;
  try
    if not Ini.SectionExists(SECAO) then
    begin
      AMotivo := Tr('cfg.motivo_sem_secao');
      Exit(rcInvalida);
    end;

    AConfig.Database := Trim(Ini.ReadString(SECAO, 'Database', ''));
    AConfig.Username := Trim(Ini.ReadString(SECAO, 'Username', ''));
    AConfig.Password := Ini.ReadString(SECAO, 'Password', '');
    AConfig.Server := Trim(Ini.ReadString(SECAO, 'Server', ''));
    AConfig.ClientLibrary := ResolverBiblioteca(Trim(Ini.ReadString(SECAO, 'ClientLibrary', '')));
    TextoPorta := Trim(Ini.ReadString(SECAO, 'Port', ''));
    if TextoPorta = '' then
      AConfig.Port := 0
    else if not TryStrToInt(TextoPorta, AConfig.Port) then
    begin
      AConfig.Port := 0;
      Exit(Falha('Port', Tr('cfg.motivo_porta_texto')));
    end;

    if not Ini.ValueExists(SECAO, 'Database') then
      Exit(Falha('Database', Tr('cfg.motivo_campo_ausente')));
    if not Ini.ValueExists(SECAO, 'Username') then
      Exit(Falha('Username', Tr('cfg.motivo_campo_ausente')));
    if not Ini.ValueExists(SECAO, 'Port') then
      Exit(Falha('Port', Tr('cfg.motivo_campo_ausente')));
    if not Ini.ValueExists(SECAO, 'ClientLibrary') then
      Exit(Falha('ClientLibrary', Tr('cfg.motivo_campo_ausente')));

    if not TValidadorEntrada.CaminhoBanco(AConfig.Database, Detalhe) then
      Exit(Falha('Database', Detalhe));
    if not TValidadorEntrada.Usuario(AConfig.Username, Detalhe) then
      Exit(Falha('Username', Detalhe));
    if not TValidadorEntrada.Senha(AConfig.Password, Detalhe) then
      Exit(Falha('Password', Detalhe));
    if not TValidadorEntrada.Servidor(AConfig.Server, Detalhe) then
      Exit(Falha('Server', Detalhe));
    if not TValidadorEntrada.Porta(AConfig.Port, Detalhe) then
      Exit(Falha('Port', Detalhe));
    if not TValidadorEntrada.BibliotecaCliente(AConfig.ClientLibrary, Detalhe) then
      Exit(Falha('ClientLibrary', Detalhe));
    Result := rcOk;
  finally
    Ini.Free;
  end;
end;

procedure TIniConfigRepositorio.Salvar(const AConfig: TConfigBanco);
var
  Ini: TMemIniFile;
  Temporario, Detalhe: string;

  procedure Exigir(AOk: Boolean; const ACampo: string);
  begin
    if not AOk then
      raise EConfigInvalida.Create(Tr('cfg.motivo_campo', [ACampo, Detalhe]));
  end;

begin
  Exigir(TValidadorEntrada.CaminhoBanco(AConfig.Database, Detalhe), 'Database');
  Exigir(TValidadorEntrada.Usuario(AConfig.Username, Detalhe), 'Username');
  Exigir(TValidadorEntrada.Senha(AConfig.Password, Detalhe), 'Password');
  Exigir(TValidadorEntrada.Servidor(AConfig.Server, Detalhe), 'Server');
  Exigir(TValidadorEntrada.Porta(AConfig.Port, Detalhe), 'Port');
  Exigir(TValidadorEntrada.BibliotecaCliente(AConfig.ClientLibrary, Detalhe), 'ClientLibrary');

  TDirectory.CreateDirectory(ExtractFilePath(FCaminho));
  Temporario := FCaminho + '.tmp';
  if TFile.Exists(Temporario) then
    TFile.Delete(Temporario);

  Ini := TMemIniFile.Create(Temporario, TEncoding.UTF8);
  try
    Ini.WriteString(SECAO, 'Database', AConfig.Database);
    Ini.WriteString(SECAO, 'Username', AConfig.Username);
    Ini.WriteString(SECAO, 'Password', AConfig.Password);
    Ini.WriteString(SECAO, 'Server', AConfig.Server);
    Ini.WriteString(SECAO, 'Port', IntToStr(AConfig.Port));
    Ini.WriteString(SECAO, 'ClientLibrary', BibliotecaParaGravar(AConfig.ClientLibrary));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;

  // Troca atômica: se algo falhar antes daqui, o config.ini antigo continua intacto.
  if TFile.Exists(FCaminho) then
    TFile.Delete(FCaminho);
  TFile.Move(Temporario, FCaminho);
end;

function TIniConfigRepositorio.GuardarCopia: string;
begin
  Result := '';
  if not TFile.Exists(FCaminho) then
    Exit;
  Result := FCaminho + '.bak-' + FormatDateTime('yyyymmdd-hhnnss', Now);
  TFile.Copy(FCaminho, Result, True);
end;

end.
