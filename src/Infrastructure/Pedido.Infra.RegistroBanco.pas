unit Pedido.Infra.RegistroBanco;

{ Guarda, em %LOCALAPPDATA%\PedidoVenda\bancos.ini, uma "marca" para cada banco
  que este computador já criou ou já conseguiu abrir. É o que permite saber se um
  banco que não está mais lá é um banco novo (nunca criado) ou um banco que
  foi apagado ou movido. Só guarda um código (hash) do endereço do banco:
  nenhuma senha, nenhum dado de pedido. }

interface

uses
  Pedido.Infra.BancoDados.Tipos,
  Pedido.Infra.Config;

type
  TRegistroBancoArquivo = class(TInterfacedObject, IRegistroBanco)
  private
    FCaminho: string;
    function ChaveDoBanco(const AConfig: TConfigBanco): string;
  public
    // ACaminho vazio usa a pasta padrão do usuário.
    constructor Create(const ACaminho: string = '');
    function JaFoiCriado(const AConfig: TConfigBanco): Boolean;
    procedure Registrar(const AConfig: TConfigBanco);
  end;

implementation

uses
  System.Hash,
  System.IniFiles,
  System.IOUtils,
  System.SysUtils;

const
  SECAO = 'Bancos';

constructor TRegistroBancoArquivo.Create(const ACaminho: string);
begin
  inherited Create;
  if ACaminho <> '' then
    FCaminho := ACaminho
  else
    FCaminho := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'PedidoVenda'),
      'bancos.ini');
end;

function TRegistroBancoArquivo.ChaveDoBanco(const AConfig: TConfigBanco): string;
begin
  Result := THashSHA2.GetHashString(AConfig.Chave, THashSHA2.TSHA2Version.SHA256);
end;

function TRegistroBancoArquivo.JaFoiCriado(const AConfig: TConfigBanco): Boolean;
var
  Ini: TMemIniFile;
begin
  Result := False;
  if not TFile.Exists(FCaminho) then
    Exit;
  try
    Ini := TMemIniFile.Create(FCaminho, TEncoding.UTF8);
    try
      Result := Ini.ValueExists(SECAO, ChaveDoBanco(AConfig));
    finally
      Ini.Free;
    end;
  except
    // Registro ilegível: na dúvida, trata como "ainda não criado".
    Result := False;
  end;
end;

procedure TRegistroBancoArquivo.Registrar(const AConfig: TConfigBanco);
var
  Ini: TMemIniFile;
begin
  try
    TDirectory.CreateDirectory(ExtractFilePath(FCaminho));
    Ini := TMemIniFile.Create(FCaminho, TEncoding.UTF8);
    try
      if not Ini.ValueExists(SECAO, ChaveDoBanco(AConfig)) then
      begin
        Ini.WriteString(SECAO, ChaveDoBanco(AConfig), FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
        Ini.UpdateFile;
      end;
    finally
      Ini.Free;
    end;
  except
    // Sem permissão de escrita? O sistema funciona do mesmo jeito; só não lembra do banco.
  end;
end;

end.
