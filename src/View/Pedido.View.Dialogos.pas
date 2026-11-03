unit Pedido.View.Dialogos;

{ Diálogos padronizados do sistema (confirmação sim/não) com os botões no
  idioma escolhido, em vez dos textos do Windows. }

interface

// Mostra a pergunta e devolve True se a pessoa escolheu "Sim".
function ConfirmarAcao(const APergunta: string): Boolean;

implementation

uses
  System.UITypes,
  Vcl.Dialogs,
  Pedido.Infra.Idioma;

function ConfirmarAcao(const APergunta: string): Boolean;
var
  Dialogo: TTaskDialog;
  BotaoSim, BotaoNao: TTaskDialogButtonItem;
begin
  Dialogo := TTaskDialog.Create(nil);
  try
    Dialogo.Caption := Tr('app.titulo');
    Dialogo.Title := APergunta;
    Dialogo.MainIcon := tdiInformation;
    Dialogo.CommonButtons := [];
    Dialogo.Flags := [tfAllowDialogCancellation];

    BotaoSim := TTaskDialogButtonItem(Dialogo.Buttons.Add);
    BotaoSim.Caption := Tr('dlg.sim');
    BotaoSim.ModalResult := mrYes;
    BotaoSim.Default := True;

    BotaoNao := TTaskDialogButtonItem(Dialogo.Buttons.Add);
    BotaoNao.Caption := Tr('dlg.nao');
    BotaoNao.ModalResult := mrNo;

    Result := Dialogo.Execute and (Dialogo.ModalResult = mrYes);
  finally
    Dialogo.Free;
  end;
end;

end.
