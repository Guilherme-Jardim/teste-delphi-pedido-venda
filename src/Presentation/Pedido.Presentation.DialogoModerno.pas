unit Pedido.Presentation.DialogoModerno;

{ Janela de aviso, confirmação e escolha no visual do sistema. Substitui as
  caixas padrão do Windows: o desenho está no .dfm e aqui só ficam o cálculo da
  altura do texto e a posição dos botões, que dependem de quantas opções existem. }

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  ComponentIcons,
  InfoCard,
  RoundButton;

type
  TfrmDialogoModerno = class(TForm)
    cardDialogo: TInfoCard;
    txtMensagem: TStaticText;
    btnOpcao1: TRoundButton;
    btnOpcao2: TRoundButton;
    btnOpcao3: TRoundButton;
    btnOpcao4: TRoundButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BotaoClick(Sender: TObject);
  private
    FEscolha: Integer;
    procedure Montar(const ATitulo, ATexto: string; AIcone: TIcone;
      const ALegendas: array of string; APerigosa: Boolean);
    function AlturaDoTexto(const ATexto: string): Integer;
  public
    // Devolve o índice da opção escolhida (0 = primeira) ou -1 se a pessoa
    // fechou com Esc ou no X. Aceita de 1 a 4 opções; a primeira é a principal.
    class function Mostrar(const ATitulo, ATexto: string; AIcone: TIcone;
      const ALegendas: array of string; APerigosa: Boolean = False): Integer;
  end;

implementation

{$R *.dfm}

uses
  Winapi.Windows,
  System.Types,
  System.UITypes,
  Vcl.Graphics;

const
  LARGURA_CONTEUDO = 388;
  MARGEM_CARTAO = 20;
  ALTURA_BOTAO = 46;
  ESPACO_BOTOES = 10;

class function TfrmDialogoModerno.Mostrar(const ATitulo, ATexto: string; AIcone: TIcone;
  const ALegendas: array of string; APerigosa: Boolean): Integer;
var
  Tela: TfrmDialogoModerno;
  Anterior: TWinControl;
begin
  // Quem estava com o foco antes (ex.: a grade) volta a ter depois que a janela fecha.
  Anterior := Screen.ActiveControl;
  Tela := TfrmDialogoModerno.Create(Application);
  try
    Tela.Montar(ATitulo, ATexto, AIcone, ALegendas, APerigosa);
    Tela.ShowModal;
    Result := Tela.FEscolha;
  finally
    Tela.Free;
  end;
  if (Anterior <> nil) and Anterior.CanFocus then
    Anterior.SetFocus;
end;

function TfrmDialogoModerno.AlturaDoTexto(const ATexto: string): Integer;
var
  Area: TRect;
begin
  Canvas.Font.Assign(txtMensagem.Font);
  Area := Rect(0, 0, LARGURA_CONTEUDO, 0);
  DrawText(Canvas.Handle, PChar(ATexto), Length(ATexto), Area,
    DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  Result := Area.Bottom + 4;
end;

procedure TfrmDialogoModerno.Montar(const ATitulo, ATexto: string; AIcone: TIcone;
  const ALegendas: array of string; APerigosa: Boolean);
var
  Botoes: array[0..3] of TRoundButton;
  Quantidade, I, Y, Metade: Integer;
begin
  FEscolha := -1;
  Botoes[0] := btnOpcao1;
  Botoes[1] := btnOpcao2;
  Botoes[2] := btnOpcao3;
  Botoes[3] := btnOpcao4;

  Caption := Application.Title;
  cardDialogo.Titulo := ATitulo;
  cardDialogo.Icone := AIcone;
  txtMensagem.Caption := ATexto;
  txtMensagem.Height := AlturaDoTexto(ATexto);

  Quantidade := Length(ALegendas);
  if Quantidade < 1 then
    Quantidade := 1;
  if Quantidade > Length(Botoes) then
    Quantidade := Length(Botoes);

  for I := 0 to High(Botoes) do
  begin
    Botoes[I].Tag := I;
    Botoes[I].Visible := I < Quantidade;
    if I < Quantidade then
    begin
      Botoes[I].Caption := ALegendas[I];
      Botoes[I].Hint := ALegendas[I];
    end;
  end;

  Y := txtMensagem.Top + txtMensagem.Height + 24;
  Botoes[0].Estilo := ebPrimario;
  if APerigosa then
    Botoes[0].Estilo := ebPerigo;

  if Quantidade <= 2 then
  begin
    // Principal à direita, secundária à esquerda (mesmo padrão das outras janelas).
    Metade := (LARGURA_CONTEUDO - ESPACO_BOTOES) div 2;
    if Quantidade = 1 then
      Botoes[0].SetBounds(MARGEM_CARTAO + LARGURA_CONTEUDO - 200, Y, 200, ALTURA_BOTAO)
    else
    begin
      Botoes[0].SetBounds(MARGEM_CARTAO + Metade + ESPACO_BOTOES, Y, Metade, ALTURA_BOTAO);
      Botoes[1].SetBounds(MARGEM_CARTAO, Y, Metade, ALTURA_BOTAO);
    end;
    Inc(Y, ALTURA_BOTAO);
  end
  else
  begin
    // Três ou quatro ações: uma embaixo da outra, cada uma com a largura toda.
    for I := 0 to Quantidade - 1 do
    begin
      Botoes[I].Icone := icNenhum;
      Botoes[I].SetBounds(MARGEM_CARTAO, Y, LARGURA_CONTEUDO, ALTURA_BOTAO);
      Inc(Y, ALTURA_BOTAO + ESPACO_BOTOES);
    end;
    Dec(Y, ESPACO_BOTOES);
  end;

  cardDialogo.Height := Y + MARGEM_CARTAO;
  ClientHeight := cardDialogo.Height + 32;
  ActiveControl := btnOpcao1;
end;

procedure TfrmDialogoModerno.BotaoClick(Sender: TObject);
begin
  FEscolha := (Sender as TRoundButton).Tag;
  ModalResult := mrOk;
end;

procedure TfrmDialogoModerno.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    FEscolha := -1;
    ModalResult := mrCancel;
  end;
end;

end.
