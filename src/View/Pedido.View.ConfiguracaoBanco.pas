unit Pedido.View.ConfiguracaoBanco;

{ Tela de configuração da conexão com o Firebird. Usada na primeira execução
  e sempre que o config.ini precisa ser ajustado. Todo o visual está no .dfm. }

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  AlertBar,
  ComponentIcons,
  ModernEdit,
  RoundButton,
  Pedido.Infra.Config;

type
  TfrmConfiguracaoBanco = class(TForm)
    lblTitulo: TLabel;
    lblAjuda: TLabel;
    avisoMensagem: TAlertBar;
    edtServidor: TModernEdit;
    edtPorta: TModernEdit;
    edtBanco: TModernEdit;
    edtUsuario: TModernEdit;
    edtSenha: TModernEdit;
    edtBiblioteca: TModernEdit;
    btnSugestoes: TRoundButton;
    btnCancelar: TRoundButton;
    btnSalvar: TRoundButton;
    btnEscolherPasta: TRoundButton;
    btnPastaPrograma: TRoundButton;
    btnPastaPadrao: TRoundButton;
    procedure FormShow(Sender: TObject);
    procedure btnSugestoesClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnEscolherPastaClick(Sender: TObject);
    procedure btnPastaProgramaClick(Sender: TObject);
    procedure btnPastaPadraoClick(Sender: TObject);
  private
    FSugestao: TConfigBanco;
    FPrimeiraVez: Boolean;
    FConfig: TConfigBanco;
    procedure PreencherCampos(const AConfig: TConfigBanco; AMantemSenha: Boolean);
    function LerCampos(out AConfig: TConfigBanco): Boolean;
    procedure Reprovar(const AMensagem: string; ACampo: TModernEdit);
    function NomeDoArquivoAtual: string;
    procedure DefinirPasta(const APasta: string);
  public
    // Mostra a tela; AConfig só vale quando devolve True (a pessoa confirmou).
    class function Executar(const AInicial, ASugestao: TConfigBanco; APrimeiraVez: Boolean;
      out AConfig: TConfigBanco): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Pedido.Infra.Idioma,
  Pedido.Infra.Validacao;

class function TfrmConfiguracaoBanco.Executar(const AInicial, ASugestao: TConfigBanco;
  APrimeiraVez: Boolean; out AConfig: TConfigBanco): Boolean;
var
  Tela: TfrmConfiguracaoBanco;
begin
  AConfig := Default(TConfigBanco);
  Tela := TfrmConfiguracaoBanco.Create(nil);
  try
    Tela.FSugestao := ASugestao;
    Tela.FPrimeiraVez := APrimeiraVez;
    Tela.PreencherCampos(AInicial, False);
    Result := Tela.ShowModal = mrOk;
    if Result then
      AConfig := Tela.FConfig;
  finally
    Tela.Free;
  end;
end;

procedure TfrmConfiguracaoBanco.FormShow(Sender: TObject);
begin
  if FPrimeiraVez then
  begin
    lblTitulo.Caption := Tr('cfgdlg.titulo_primeira');
    lblAjuda.Caption := Tr('cfgdlg.ajuda_primeira');
  end
  else
  begin
    lblTitulo.Caption := Tr('cfgdlg.titulo_reconfig');
    lblAjuda.Caption := Tr('cfgdlg.ajuda_reconfig');
  end;
  Caption := lblTitulo.Caption;
  edtServidor.Rotulo := Tr('cfgdlg.servidor');
  edtPorta.Rotulo := Tr('cfgdlg.porta');
  edtBanco.Rotulo := Tr('cfgdlg.banco');
  edtUsuario.Rotulo := Tr('cfgdlg.usuario');
  edtSenha.Rotulo := Tr('cfgdlg.senha');
  edtBiblioteca.Rotulo := Tr('cfgdlg.biblioteca');
  edtServidor.Dica := Tr('cfgdlg.hint_servidor');
  edtBanco.Dica := Tr('cfgdlg.hint_banco');
  edtSenha.Dica := Tr('cfgdlg.hint_senha');
  btnEscolherPasta.Caption := Tr('cfgdlg.escolher_pasta');
  btnEscolherPasta.Hint := Tr('cfgdlg.escolher_pasta');
  btnPastaPrograma.Caption := Tr('cfgdlg.pasta_programa');
  btnPastaPrograma.Hint := Tr('cfgdlg.pasta_programa');
  btnPastaPadrao.Caption := Tr('cfgdlg.pasta_padrao');
  btnPastaPadrao.Hint := Tr('cfgdlg.pasta_padrao');
  btnSugestoes.Caption := Tr('cfgdlg.sugestoes');
  btnCancelar.Caption := Tr('dlg.cancelar');
  btnSalvar.Caption := Tr('cfgdlg.salvar');
  // A senha nunca é adivinhada: o cursor já começa nela quando o resto está preenchido.
  ActiveControl := edtSenha.Edit;
end;

procedure TfrmConfiguracaoBanco.PreencherCampos(const AConfig: TConfigBanco; AMantemSenha: Boolean);
begin
  edtServidor.Texto := AConfig.Server;
  edtPorta.Texto := IntToStr(AConfig.Port);
  edtBanco.Texto := AConfig.Database;
  edtUsuario.Texto := AConfig.Username;
  if not AMantemSenha then
    edtSenha.Texto := AConfig.Password;
  edtBiblioteca.Texto := AConfig.ClientLibrary;
end;

procedure TfrmConfiguracaoBanco.Reprovar(const AMensagem: string; ACampo: TModernEdit);
begin
  avisoMensagem.Mostrar(AMensagem, taErro);
  ACampo.SetFocus;
end;

function TfrmConfiguracaoBanco.LerCampos(out AConfig: TConfigBanco): Boolean;
var
  Motivo: string;
begin
  Result := False;
  AConfig := Default(TConfigBanco);
  AConfig.Server := Trim(edtServidor.Texto);
  AConfig.Database := Trim(edtBanco.Texto);
  AConfig.Username := Trim(edtUsuario.Texto);
  AConfig.Password := edtSenha.Texto;
  AConfig.ClientLibrary := Trim(edtBiblioteca.Texto);

  if not TryStrToInt(Trim(edtPorta.Texto), AConfig.Port) then
    AConfig.Port := 0;

  if not TValidadorEntrada.Servidor(AConfig.Server, Motivo) then
    Reprovar(Motivo, edtServidor)
  else if not TValidadorEntrada.Porta(AConfig.Port, Motivo) then
    Reprovar(Motivo, edtPorta)
  else if not TValidadorEntrada.CaminhoBanco(AConfig.Database, Motivo) then
    Reprovar(Motivo, edtBanco)
  else if not TValidadorEntrada.Usuario(AConfig.Username, Motivo) then
    Reprovar(Motivo, edtUsuario)
  else if not TValidadorEntrada.Senha(AConfig.Password, Motivo) then
    Reprovar(Motivo, edtSenha)
  else if not TValidadorEntrada.BibliotecaCliente(AConfig.ClientLibrary, Motivo) then
    Reprovar(Motivo, edtBiblioteca)
  else
    Result := True;
end;

procedure TfrmConfiguracaoBanco.btnSugestoesClick(Sender: TObject);
begin
  avisoMensagem.Limpar;
  PreencherCampos(FSugestao, True);
end;

procedure TfrmConfiguracaoBanco.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmConfiguracaoBanco.btnSalvarClick(Sender: TObject);
begin
  avisoMensagem.Limpar;
  if LerCampos(FConfig) then
    ModalResult := mrOk;
end;

function TfrmConfiguracaoBanco.NomeDoArquivoAtual: string;
begin
  // Mantém o nome do arquivo que a pessoa já escolheu; sem nome válido, usa PEDIDOS.FDB.
  Result := ExtractFileName(Trim(edtBanco.Texto));
  if (Result = '') or (ExtractFileExt(Result) = '') then
    Result := 'PEDIDOS.FDB';
end;

procedure TfrmConfiguracaoBanco.DefinirPasta(const APasta: string);
begin
  edtBanco.Texto := TPath.Combine(ExcludeTrailingPathDelimiter(APasta), NomeDoArquivoAtual);
  avisoMensagem.Limpar;
end;

procedure TfrmConfiguracaoBanco.btnEscolherPastaClick(Sender: TObject);
var
  Dialogo: TFileOpenDialog;
  PastaAtual: string;
begin
  Dialogo := TFileOpenDialog.Create(Self);
  try
    Dialogo.Title := Tr('cfgdlg.titulo_pasta');
    Dialogo.Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
    PastaAtual := ExtractFilePath(Trim(edtBanco.Texto));
    if TDirectory.Exists(PastaAtual) then
      Dialogo.DefaultFolder := PastaAtual;
    if Dialogo.Execute then
      DefinirPasta(Dialogo.FileName);
  finally
    Dialogo.Free;
  end;
end;

procedure TfrmConfiguracaoBanco.btnPastaProgramaClick(Sender: TObject);
begin
  // A pasta onde está o executável (útil para instalações portáteis).
  DefinirPasta(ExtractFilePath(ParamStr(0)));
end;

procedure TfrmConfiguracaoBanco.btnPastaPadraoClick(Sender: TObject);
begin
  DefinirPasta(ExtractFilePath(FSugestao.Database));
end;

end.
