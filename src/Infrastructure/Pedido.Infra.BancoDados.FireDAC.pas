unit Pedido.Infra.BancoDados.FireDAC;

{ Implementação FireDAC do inspetor (diagnóstico) e do criador do banco.
  Todos os comandos SQL aqui são constantes ou vêm do esquema (TEsquemaBanco);
  nada digitado pela pessoa é concatenado em SQL. }

interface

uses
  System.SysUtils,
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config;

type
  EBancoNaoCriado = class(Exception);

  TInspetorBancoFireDAC = class(TInterfacedObject, IInspetorBanco)
  private
    function VerificarBiblioteca(const AConfig: TConfigBanco; out ADetalhe: string): Boolean;
  public
    function Diagnosticar(const AConfig: TConfigBanco): TDiagnosticoBanco;
    // Traduz uma exceção de conexão para um estado conhecido.
    class function ClassificarErro(E: Exception): TEstadoBanco; static;
  end;

  TCriadorBancoFireDAC = class(TInterfacedObject, ICriadorBanco)
  public
    procedure CriarBancoNovo(const AConfig: TConfigBanco);
    procedure CriarEstrutura(const AConfig: TConfigBanco);
    procedure AtualizarEstrutura(const AConfig: TConfigBanco);
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Error,
  Pedido.Infra.Conexao,
  Pedido.Infra.EsquemaBanco,
  Pedido.Infra.Validacao;

const
  // Códigos do Firebird (isc_*) reconhecidos no diagnóstico.
  ISC_IO_ERROR = 335544344;
  ISC_FILE_OPEN_ERROR = 335544734;
  ISC_NETWORK_ERROR = 335544721;
  ISC_LOGIN_ERROR = 335544472;
  ISC_LOGIN_ERROR_2 = 335544465;

  SQL_TABELAS_DO_USUARIO =
    'SELECT TRIM(RDB$RELATION_NAME) AS NOME FROM RDB$RELATIONS ' +
    'WHERE COALESCE(RDB$SYSTEM_FLAG, 0) = 0 AND RDB$VIEW_BLR IS NULL';
  SQL_GENERATOR_EXISTE =
    'SELECT COUNT(*) FROM RDB$GENERATORS WHERE RDB$GENERATOR_NAME = :NOME';
  SQL_COLUNA_EXISTE =
    'SELECT COUNT(*) FROM RDB$RELATION_FIELDS ' +
    'WHERE RDB$RELATION_NAME = :TABELA AND RDB$FIELD_NAME = :CAMPO';

type
  // Descobre o tipo de arquivo (32 ou 64 bits) lendo o cabeçalho PE da DLL.
  TBitsDaDll = (bdDesconhecido, bd32, bd64);

function LerBitsDaDll(const ACaminho: string): TBitsDaDll;
var
  Fluxo: TFileStream;
  OffsetPE, Assinatura: Cardinal;
  Maquina: Word;
begin
  Result := bdDesconhecido;
  try
    Fluxo := TFileStream.Create(ACaminho, fmOpenRead or fmShareDenyNone);
    try
      if Fluxo.Size < 128 then
        Exit;
      Fluxo.Position := $3C;
      Fluxo.ReadBuffer(OffsetPE, SizeOf(OffsetPE));
      if Int64(OffsetPE) + 6 > Fluxo.Size then
        Exit;
      Fluxo.Position := OffsetPE;
      Fluxo.ReadBuffer(Assinatura, SizeOf(Assinatura));
      if Assinatura <> $00004550 then // 'PE'#0#0
        Exit;
      Fluxo.ReadBuffer(Maquina, SizeOf(Maquina));
      case Maquina of
        $014C: Result := bd32;
        $8664: Result := bd64;
      end;
    finally
      Fluxo.Free;
    end;
  except
    Result := bdDesconhecido;
  end;
end;

function EhTabelaDoSistema(const ANome: string): Boolean;
var
  Tabela: string;
begin
  for Tabela in TEsquemaBanco.Tabelas do
    if SameText(Tabela, ANome) then
      Exit(True);
  Result := False;
end;

function ContemTexto(const ATexto, ATrecho: string): Boolean;
begin
  Result := Pos(LowerCase(ATrecho), LowerCase(ATexto)) > 0;
end;

{ TInspetorBancoFireDAC }

class function TInspetorBancoFireDAC.ClassificarErro(E: Exception): TEstadoBanco;
var
  Falha: EFDDBEngineException;
  I: Integer;
  Codigo: Integer;
begin
  Result := ebErroInesperado;

  if E is EFDDBEngineException then
  begin
    Falha := EFDDBEngineException(E);
    case Falha.Kind of
      ekUserPwdInvalid:
        Exit(ebCredenciaisInvalidas);
      ekServerGone:
        Exit(ebServidorIndisponivel);
    end;
    for I := 0 to Falha.ErrorCount - 1 do
    begin
      Codigo := Falha.Errors[I].ErrorCode;
      if (Codigo = ISC_LOGIN_ERROR) or (Codigo = ISC_LOGIN_ERROR_2) then
        Exit(ebCredenciaisInvalidas);
      if Codigo = ISC_NETWORK_ERROR then
        Exit(ebServidorIndisponivel);
      if (Codigo = ISC_IO_ERROR) or (Codigo = ISC_FILE_OPEN_ERROR) then
        Exit(ebBancoInexistente);
    end;
  end;

  // Plano B: as mensagens do Firebird são sempre em inglês.
  if ContemTexto(E.Message, 'Your user name and password are not defined') or
     ContemTexto(E.Message, 'Incorrect user') or ContemTexto(E.Message, 'invalid user') then
    Exit(ebCredenciaisInvalidas);
  if ContemTexto(E.Message, 'Unable to complete network request') or
     ContemTexto(E.Message, 'connection rejected') or ContemTexto(E.Message, 'Failed to establish a connection') then
    Exit(ebServidorIndisponivel);
  if ContemTexto(E.Message, 'I/O error') or ContemTexto(E.Message, 'Error while trying to open file') or
     ContemTexto(E.Message, 'cannot open file') then
    Exit(ebBancoInexistente);
  if ContemTexto(E.Message, 'vendor library') or ContemTexto(E.Message, 'Cannot load vendor') then
    Exit(ebBibliotecaIndisponivel);
end;

function TInspetorBancoFireDAC.VerificarBiblioteca(const AConfig: TConfigBanco;
  out ADetalhe: string): Boolean;
var
  Bits: TBitsDaDll;
begin
  Result := False;
  ADetalhe := '';
  if not TFile.Exists(AConfig.ClientLibrary) then
  begin
    ADetalhe := 'fbclient.dll não encontrada: ' + AConfig.ClientLibrary;
    Exit;
  end;
  Bits := LerBitsDaDll(AConfig.ClientLibrary);
  {$IFDEF WIN64}
  if Bits = bd32 then
  {$ELSE}
  if Bits = bd64 then
  {$ENDIF}
  begin
    ADetalhe := 'fbclient.dll com bits diferentes do aplicativo: ' + AConfig.ClientLibrary;
    Exit;
  end;
  Result := True;
end;

function TInspetorBancoFireDAC.Diagnosticar(const AConfig: TConfigBanco): TDiagnosticoBanco;
var
  Dono: TComponent;
  Conexao: TFDConnection;
  Consulta: TFDQuery;
  Tabelas, Outras: TStringList;
  Nome, Detalhe: string;
  Existentes, Faltando: Integer;
begin
  if not VerificarBiblioteca(AConfig, Detalhe) then
    Exit(TDiagnosticoBanco.Criar(ebBibliotecaIndisponivel, Detalhe));

  Dono := TComponent.Create(nil);
  Tabelas := TStringList.Create;
  Outras := TStringList.Create;
  try
    Tabelas.CaseSensitive := False;
    Conexao := TFabricaConexao.Criar(AConfig, Dono);
    try
      Conexao.Connected := True;
    except
      on E: Exception do
        Exit(TDiagnosticoBanco.Criar(ClassificarErro(E), E.ClassName + ': ' + E.Message));
    end;

    try
      Consulta := TFDQuery.Create(Dono);
      Consulta.Connection := Conexao;
      Consulta.SQL.Text := SQL_TABELAS_DO_USUARIO;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Tabelas.Add(Consulta.FieldByName('NOME').AsString);
        Consulta.Next;
      end;
      Consulta.Close;

      Existentes := 0;
      Faltando := 0;
      for Nome in TEsquemaBanco.Tabelas do
        if Tabelas.IndexOf(Nome) >= 0 then
          Inc(Existentes)
        else
          Inc(Faltando);
      for Nome in Tabelas do
        if not EhTabelaDoSistema(Nome) then
          Outras.Add(Nome);

      // Tem tabelas de outro sistema e nenhuma nossa: não mexemos nesse banco.
      if (Existentes = 0) and (Outras.Count > 0) then
        Exit(TDiagnosticoBanco.Criar(ebBancoDeOutroSistema, 'Tabelas encontradas: ' + Outras.CommaText));

      Consulta.SQL.Text := SQL_GENERATOR_EXISTE;
      Consulta.ParamByName('NOME').AsString := TEsquemaBanco.NomeDoGenerator;
      Consulta.Open;
      if (Faltando > 0) or (Consulta.Fields[0].AsInteger = 0) then
        Exit(TDiagnosticoBanco.Criar(ebSemEstrutura, Format('%d tabela(s) faltando', [Faltando])));
      Consulta.Close;

      Consulta.SQL.Text := SQL_COLUNA_EXISTE;
      Consulta.ParamByName('TABELA').AsString := 'PEDIDO';
      Consulta.ParamByName('CAMPO').AsString := 'OBSERVACAO';
      Consulta.Open;
      if Consulta.Fields[0].AsInteger = 0 then
        Exit(TDiagnosticoBanco.Criar(ebEstruturaDesatualizada, 'Falta a coluna PEDIDO.OBSERVACAO'));

      Result := TDiagnosticoBanco.Criar(ebOk);
    except
      on E: Exception do
        Result := TDiagnosticoBanco.Criar(ClassificarErro(E), E.ClassName + ': ' + E.Message);
    end;
  finally
    Outras.Free;
    Tabelas.Free;
    Dono.Free;
  end;
end;

{ TCriadorBancoFireDAC }

procedure ExigirConfigValida(const AConfig: TConfigBanco);
var
  Motivo: string;
begin
  if not (TValidadorEntrada.CaminhoBanco(AConfig.Database, Motivo) and
          TValidadorEntrada.Usuario(AConfig.Username, Motivo) and
          TValidadorEntrada.Servidor(AConfig.Server, Motivo) and
          TValidadorEntrada.Porta(AConfig.Port, Motivo) and
          TValidadorEntrada.Senha(AConfig.Password, Motivo)) then
    raise EBancoNaoCriado.Create(Motivo);
end;

function ExisteTabela(AConexao: TFDConnection; const ATabela: string): Boolean;
begin
  Result := AConexao.ExecSQLScalar(
    'SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = :NOME AND COALESCE(RDB$SYSTEM_FLAG, 0) = 0',
    [UpperCase(ATabela)]) > 0;
end;

function ExisteGenerator(AConexao: TFDConnection; const ANome: string): Boolean;
begin
  Result := AConexao.ExecSQLScalar(SQL_GENERATOR_EXISTE, [UpperCase(ANome)]) > 0;
end;

procedure InserirCarga(AConexao: TFDConnection; const ATabela: string);
var
  Comando: string;
begin
  AConexao.StartTransaction;
  try
    for Comando in TEsquemaBanco.CargaInicial(ATabela) do
      AConexao.ExecSQL(Comando);
    AConexao.Commit;
  except
    if AConexao.InTransaction then
      AConexao.Rollback;
    raise;
  end;
end;

// Cria só o que falta (nunca apaga nem altera dados existentes).
procedure ComplementarEstrutura(AConexao: TFDConnection);
var
  Tabela: string;
  Criou: Boolean;
begin
  for Tabela in TEsquemaBanco.Tabelas do
  begin
    if ExisteTabela(AConexao, Tabela) then
      Continue;
    AConexao.ExecSQL(TEsquemaBanco.ComandoDaTabela(Tabela));
    Criou := True;
    if SameText(Tabela, 'PRODUTO') and not ExisteGenerator(AConexao, TEsquemaBanco.NomeDoGenerator) then
      AConexao.ExecSQL(TEsquemaBanco.ComandoDoGenerator);
    // Tabela nova de cadastro recebe os dados de exemplo; as demais ficam vazias.
    if Criou and (SameText(Tabela, 'CLIENTE') or SameText(Tabela, 'PRODUTO')) then
      InserirCarga(AConexao, Tabela);
  end;
  if not ExisteGenerator(AConexao, TEsquemaBanco.NomeDoGenerator) then
    AConexao.ExecSQL(TEsquemaBanco.ComandoDoGenerator);
end;

procedure MigrarObservacao(AConexao: TFDConnection);
var
  Existe: Boolean;
begin
  Existe := AConexao.ExecSQLScalar(SQL_COLUNA_EXISTE, ['PEDIDO', 'OBSERVACAO']) > 0;
  if not Existe then
    AConexao.ExecSQL(TEsquemaBanco.ComandoMigracaoObservacao);
end;

procedure TCriadorBancoFireDAC.CriarBancoNovo(const AConfig: TConfigBanco);
var
  Dono: TComponent;
  Conexao: TFDConnection;
  Pasta: string;
begin
  ExigirConfigValida(AConfig);
  if AConfig.EhServidorLocal then
  begin
    // Banco local: confirma que não vamos sobrescrever nada e prepara a pasta.
    if TFile.Exists(AConfig.Database) then
      raise EBancoNaoCriado.Create('O arquivo do banco já existe: ' + AConfig.Database);
    Pasta := ExtractFilePath(AConfig.Database);
    if Pasta <> '' then
      TDirectory.CreateDirectory(Pasta);
  end;

  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(AConfig, Dono, True);
    Conexao.Connected := True; // com CreateDatabase=Yes, conectar cria o arquivo
    ComplementarEstrutura(Conexao);
    MigrarObservacao(Conexao);
  finally
    Dono.Free;
  end;
end;

procedure TCriadorBancoFireDAC.CriarEstrutura(const AConfig: TConfigBanco);
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirConfigValida(AConfig);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(AConfig, Dono);
    Conexao.Connected := True;
    ComplementarEstrutura(Conexao);
    MigrarObservacao(Conexao);
  finally
    Dono.Free;
  end;
end;

procedure TCriadorBancoFireDAC.AtualizarEstrutura(const AConfig: TConfigBanco);
var
  Dono: TComponent;
  Conexao: TFDConnection;
begin
  ExigirConfigValida(AConfig);
  Dono := TComponent.Create(nil);
  try
    Conexao := TFabricaConexao.Criar(AConfig, Dono);
    Conexao.Connected := True;
    MigrarObservacao(Conexao);
  finally
    Dono.Free;
  end;
end;

end.
