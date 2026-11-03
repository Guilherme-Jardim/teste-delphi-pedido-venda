unit Pedido.Presentation.NumeroPedido;

{ Pergunta o número de um pedido (usada por "Cargar pedido" e "Cancelar pedido"). }

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  ComponentIcons,
  ModernEdit,
  RoundButton;

type
  TfrmNumeroPedido = class(TForm)
    lblTitulo: TLabel;
    lblAjuda: TLabel;
    edtNumero: TModernEdit;
    btnConfirmar: TRoundButton;
    btnCancelar: TRoundButton;
    procedure FormShow(Sender: TObject);
    procedure edtNumeroConfirmar(Sender: TObject);
    procedure btnConfirmarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FNumero: Integer;
  public
    // Devolve False se a pessoa cancelou ou digitou um número inválido.
    class function Perguntar(const ATitulo: string; out ANumero: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.UITypes,
  Pedido.Infra.Idioma;

class function TfrmNumeroPedido.Perguntar(const ATitulo: string; out ANumero: Integer): Boolean;
var
  Tela: TfrmNumeroPedido;
begin
  ANumero := 0;
  Tela := TfrmNumeroPedido.Create(Application);
  try
    Tela.lblTitulo.Caption := ATitulo;
    Tela.Caption := ATitulo;
    Result := (Tela.ShowModal = mrOk) and (Tela.FNumero > 0);
    if Result then
      ANumero := Tela.FNumero;
  finally
    Tela.Free;
  end;
end;

procedure TfrmNumeroPedido.FormShow(Sender: TObject);
begin
  lblAjuda.Caption := Tr('dlg.numero_ajuda');
  edtNumero.Rotulo := Tr('dlg.numero_pergunta');
  edtNumero.Dica := Tr('dlg.numero_ajuda');
  btnConfirmar.Caption := Tr('dlg.ok');
  btnCancelar.Caption := Tr('dlg.cancelar');
  ActiveControl := edtNumero.Edit;
end;

procedure TfrmNumeroPedido.edtNumeroConfirmar(Sender: TObject);
begin
  btnConfirmarClick(Sender);
end;

procedure TfrmNumeroPedido.btnConfirmarClick(Sender: TObject);
begin
  if TryStrToInt(Trim(edtNumero.Texto), FNumero) and (FNumero > 0) then
    ModalResult := mrOk
  else
  begin
    edtNumero.Edit.SelectAll;
    edtNumero.SetFocus;
  end;
end;

procedure TfrmNumeroPedido.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
