unit Pedido.Infra.Conexao;

{ Monta a conexão FireDAC com Firebird a partir da configuração. Nenhum texto
  digitado entra em SQL: usuário, senha, servidor e caminho do banco vão como
  parâmetros de conexão do próprio FireDAC. }

interface

uses
  System.Classes,
  FireDAC.Comp.Client,
  Pedido.Infra.Config;

type
  TFabricaConexao = class
  public
    // ACriarBanco = True pede ao FireDAC para criar o arquivo do banco ao conectar.
    class function Criar(const AConfig: TConfigBanco; AOwner: TComponent;
      ACriarBanco: Boolean = False): TFDConnection;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param,
  FireDAC.UI.Intf,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI;

{ TFabricaConexao }

class function TFabricaConexao.Criar(const AConfig: TConfigBanco; AOwner: TComponent;
  ACriarBanco: Boolean): TFDConnection;
var
  Driver: TFDPhysFBDriverLink;
begin
  // Cursor de espera do FireDAC (necessário em aplicações VCL).
  TFDGUIxWaitCursor.Create(AOwner);

  // Aponta o driver para a fbclient.dll que acompanha a aplicação.
  Driver := TFDPhysFBDriverLink.Create(AOwner);
  Driver.VendorLib := AConfig.ClientLibrary;

  Result := TFDConnection.Create(AOwner);
  Result.LoginPrompt := False;
  Result.DriverName := 'FB';
  Result.Params.Values['Database'] := AConfig.Database;
  Result.Params.Values['User_Name'] := AConfig.Username;
  Result.Params.Values['Password'] := AConfig.Password;
  Result.Params.Values['CharacterSet'] := 'UTF8';
  if AConfig.Server <> '' then
  begin
    Result.Params.Values['Server'] := AConfig.Server;
    Result.Params.Values['Port'] := IntToStr(AConfig.Port);
  end;
  if ACriarBanco then
  begin
    Result.Params.Values['CreateDatabase'] := 'Yes';
    Result.Params.Values['PageSize'] := '8192';
  end;
end;

end.
