unit Pedido.View.Principal;

{ Tela do Pedido de Venda. Só cuida de ler campos, mostrar dados e
  capturar teclado; as decisões ficam no controller e no service. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Grids,
  Pedido.Controller.Pedido;

type
  TfrmPedidoVenda = class(TForm)
    pnlTopo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblNumeroPedido: TLabel;
    lblMensagem: TLabel;
    gbCliente: TGroupBox;
    lblCodCliente: TLabel;
    lblNomeCliente: TLabel;
    lblCidadeCliente: TLabel;
    lblUFCliente: TLabel;
    edtCodCliente: TEdit;
    edtNomeCliente: TEdit;
    edtCidadeCliente: TEdit;
    edtUFCliente: TEdit;
    gbItem: TGroupBox;
    lblCodProduto: TLabel;
    lblDescricaoProduto: TLabel;
    lblQuantidade: TLabel;
    lblVlrUnitario: TLabel;
    edtCodProduto: TEdit;
    edtDescricaoProduto: TEdit;
    edtQuantidade: TEdit;
    edtVlrUnitario: TEdit;
    btnInserirItem: TButton;
    sgItens: TStringGrid;
    lblAtalhos: TLabel;
    pnlRodape: TPanel;
    lblTotalRotulo: TLabel;
    lblTotal: TLabel;
    btnNovo: TButton;
    btnCarregar: TButton;
    btnCancelarPedido: TButton;
    btnGravar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CampoCodigoKeyPress(Sender: TObject; var Key: Char);
    procedure edtCodClienteExit(Sender: TObject);
    procedure edtCodProdutoExit(Sender: TObject);
    procedure btnInserirItemClick(Sender: TObject);
    procedure sgItensKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgItensDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCarregarClick(Sender: TObject);
    procedure btnCancelarPedidoClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
  private
    FController: TPedidoController;
    procedure ConfigurarGrid;
    procedure MostrarErro(const AMensagem: string);
    procedure LimparMensagem;
    procedure LimparCliente;
    procedure LimparCamposItem;
    procedure PreencherCliente(ACodigo: Integer);
    procedure AtualizarTela;
    procedure AtualizarGrid;
    procedure AtualizarTotal;
    procedure AtualizarBotaoItem;
    procedure CarregarItemSelecionado;
    procedure ExcluirItemSelecionado;
    function LerCodigo(AEdit: TEdit; out ACodigo: Integer): Boolean;
    function PedirNumeroPedido(const ATitulo: string; out ANumero: Integer): Boolean;
  public
    procedure Iniciar(AController: TPedidoController);
  end;

var
  frmPedidoVenda: TfrmPedidoVenda;

implementation

{$R *.dfm}

uses
  Pedido.Model.Cliente,
  Pedido.Model.Produto,
  Pedido.Model.PedidoItem,
  Pedido.Model.Excecoes;

const
  COL_CODIGO = 0;
  COL_DESCRICAO = 1;
  COL_QUANTIDADE = 2;
  COL_VLR_UNITARIO = 3;
  COL_VLR_TOTAL = 4;

function FormatarMoeda(AValor: Currency): string;
begin
  Result := FormatFloat('#,##0.00', AValor);
end;

{ TfrmPedidoVenda }

procedure TfrmPedidoVenda.FormCreate(Sender: TObject);
begin
  ConfigurarGrid;
end;

procedure TfrmPedidoVenda.Iniciar(AController: TPedidoController);
begin
  FController := AController;
  AtualizarTela;
  edtCodCliente.SetFocus;
end;

procedure TfrmPedidoVenda.ConfigurarGrid;
begin
  sgItens.Cells[COL_CODIGO, 0] := 'Cód. Produto';
  sgItens.Cells[COL_DESCRICAO, 0] := 'Descrição';
  sgItens.Cells[COL_QUANTIDADE, 0] := 'Quantidade';
  sgItens.Cells[COL_VLR_UNITARIO, 0] := 'Vlr. Unitário';
  sgItens.Cells[COL_VLR_TOTAL, 0] := 'Vlr. Total';
  sgItens.ColWidths[COL_CODIGO] := 100;
  sgItens.ColWidths[COL_DESCRICAO] := 400;
  sgItens.ColWidths[COL_QUANTIDADE] := 110;
  sgItens.ColWidths[COL_VLR_UNITARIO] := 120;
  sgItens.ColWidths[COL_VLR_TOTAL] := 120;
end;

procedure TfrmPedidoVenda.MostrarErro(const AMensagem: string);
begin
  lblMensagem.Caption := AMensagem;
end;

procedure TfrmPedidoVenda.LimparMensagem;
begin
  lblMensagem.Caption := '';
end;

procedure TfrmPedidoVenda.LimparCliente;
begin
  edtNomeCliente.Clear;
  edtCidadeCliente.Clear;
  edtUFCliente.Clear;
end;

procedure TfrmPedidoVenda.LimparCamposItem;
begin
  edtCodProduto.Clear;
  edtDescricaoProduto.Clear;
  edtQuantidade.Clear;
  edtVlrUnitario.Clear;
end;

function TfrmPedidoVenda.LerCodigo(AEdit: TEdit; out ACodigo: Integer): Boolean;
begin
  Result := TryStrToInt(Trim(AEdit.Text), ACodigo) and (ACodigo > 0);
end;

procedure TfrmPedidoVenda.PreencherCliente(ACodigo: Integer);
var
  Cliente: TCliente;
begin
  Cliente := FController.InformarCliente(ACodigo);
  try
    edtCodCliente.Text := IntToStr(Cliente.Codigo);
    edtNomeCliente.Text := Cliente.Nome;
    edtCidadeCliente.Text := Cliente.Cidade;
    edtUFCliente.Text := Cliente.UF;
  finally
    Cliente.Free;
  end;
end;

procedure TfrmPedidoVenda.AtualizarTela;
begin
  LimparMensagem;
  if FController.Pedido.Numero > 0 then
    lblNumeroPedido.Caption := Format('Pedido nº %d', [FController.Pedido.Numero])
  else
    lblNumeroPedido.Caption := 'Novo pedido';

  if FController.Pedido.CodigoCliente > 0 then
    PreencherCliente(FController.Pedido.CodigoCliente)
  else
  begin
    edtCodCliente.Clear;
    LimparCliente;
  end;

  LimparCamposItem;
  AtualizarGrid;
  AtualizarTotal;
  AtualizarBotaoItem;
end;

procedure TfrmPedidoVenda.AtualizarGrid;
var
  I: Integer;
  Item: TPedidoItem;
begin
  if FController.Pedido.Itens.Count = 0 then
  begin
    sgItens.RowCount := 2;
    sgItens.Rows[1].Clear;
    Exit;
  end;

  sgItens.RowCount := FController.Pedido.Itens.Count + 1;
  for I := 0 to FController.Pedido.Itens.Count - 1 do
  begin
    Item := FController.Pedido.Itens[I];
    sgItens.Cells[COL_CODIGO, I + 1] := IntToStr(Item.CodigoProduto);
    sgItens.Cells[COL_DESCRICAO, I + 1] := Item.Descricao;
    sgItens.Cells[COL_QUANTIDADE, I + 1] := FormatFloat('#,##0.###', Item.Quantidade);
    sgItens.Cells[COL_VLR_UNITARIO, I + 1] := FormatarMoeda(Item.VlrUnitario);
    sgItens.Cells[COL_VLR_TOTAL, I + 1] := FormatarMoeda(Item.VlrTotal);
  end;
end;

procedure TfrmPedidoVenda.AtualizarTotal;
begin
  lblTotal.Caption := 'R$ ' + FormatarMoeda(FController.Pedido.ValorTotal);
end;

procedure TfrmPedidoVenda.AtualizarBotaoItem;
begin
  if FController.EmEdicao then
    btnInserirItem.Caption := 'Atualizar Item'
  else
    btnInserirItem.Caption := 'Inserir Item';
end;

procedure TfrmPedidoVenda.CampoCodigoKeyPress(Sender: TObject; var Key: Char);
begin
  // ENTER avança para o próximo campo (e dispara o OnExit do atual).
  if Key = #13 then
  begin
    Key := #0;
    SelectNext(Sender as TWinControl, True, True);
  end;
end;

procedure TfrmPedidoVenda.edtCodClienteExit(Sender: TObject);
var
  Codigo: Integer;
begin
  LimparMensagem;
  if Trim(edtCodCliente.Text) = '' then
  begin
    LimparCliente;
    Exit;
  end;
  if not LerCodigo(edtCodCliente, Codigo) then
  begin
    LimparCliente;
    MostrarErro('Código de cliente inválido.');
    Exit;
  end;
  try
    PreencherCliente(Codigo);
  except
    on E: EClienteNaoEncontrado do
    begin
      LimparCliente;
      FController.Pedido.CodigoCliente := 0;
      MostrarErro(E.Message);
    end;
  end;
end;

procedure TfrmPedidoVenda.edtCodProdutoExit(Sender: TObject);
var
  Codigo: Integer;
  Produto: TProduto;
begin
  LimparMensagem;
  if Trim(edtCodProduto.Text) = '' then
  begin
    edtDescricaoProduto.Clear;
    Exit;
  end;
  if not LerCodigo(edtCodProduto, Codigo) then
  begin
    edtDescricaoProduto.Clear;
    MostrarErro('Código de produto inválido.');
    Exit;
  end;
  try
    Produto := FController.ConsultarProduto(Codigo);
    try
      edtDescricaoProduto.Text := Produto.Descricao;
      // Sugere o preço de venda; o operador pode alterar.
      if not FController.EmEdicao then
        edtVlrUnitario.Text := FormatFloat('0.00', Produto.PrecoVenda);
    finally
      Produto.Free;
    end;
  except
    on E: EProdutoNaoEncontrado do
    begin
      edtDescricaoProduto.Clear;
      MostrarErro(E.Message);
    end;
  end;
end;

procedure TfrmPedidoVenda.btnInserirItemClick(Sender: TObject);
var
  Codigo: Integer;
  Quantidade: Double;
  Valor: Currency;
  Indice: Integer;
begin
  LimparMensagem;
  if not LerCodigo(edtCodProduto, Codigo) then
  begin
    MostrarErro('Informe o código do produto.');
    edtCodProduto.SetFocus;
    Exit;
  end;
  if not TryStrToFloat(Trim(edtQuantidade.Text), Quantidade) or (Quantidade <= 0) then
  begin
    MostrarErro('Informe uma quantidade maior que zero.');
    edtQuantidade.SetFocus;
    Exit;
  end;
  if not TryStrToCurr(Trim(edtVlrUnitario.Text), Valor) or (Valor < 0) then
  begin
    MostrarErro('Informe um valor unitário válido.');
    edtVlrUnitario.SetFocus;
    Exit;
  end;

  try
    Indice := FController.SalvarItem(Codigo, Quantidade, Valor);
  except
    on E: EPedidoErro do
    begin
      MostrarErro(E.Message);
      Exit;
    end;
  end;

  LimparCamposItem;
  AtualizarGrid;
  sgItens.Row := Indice + 1;
  AtualizarTotal;
  AtualizarBotaoItem;
  edtCodProduto.SetFocus;
end;

procedure TfrmPedidoVenda.sgItensKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        CarregarItemSelecionado;
      end;
    VK_DELETE:
      begin
        Key := 0;
        ExcluirItemSelecionado;
      end;
  end;
end;

procedure TfrmPedidoVenda.CarregarItemSelecionado;
var
  Item: TPedidoItem;
begin
  LimparMensagem;
  if FController.Pedido.Itens.Count = 0 then
    Exit;
  try
    Item := FController.IniciarEdicaoItem(sgItens.Row - 1);
  except
    on E: EPedidoErro do
    begin
      MostrarErro(E.Message);
      Exit;
    end;
  end;

  edtCodProduto.Text := IntToStr(Item.CodigoProduto);
  edtDescricaoProduto.Text := Item.Descricao;
  edtQuantidade.Text := FloatToStr(Item.Quantidade);
  edtVlrUnitario.Text := FormatFloat('0.00', Item.VlrUnitario);
  AtualizarBotaoItem;
  edtQuantidade.SetFocus;
end;

procedure TfrmPedidoVenda.ExcluirItemSelecionado;
var
  Indice: Integer;
begin
  LimparMensagem;
  if FController.Pedido.Itens.Count = 0 then
    Exit;

  Indice := sgItens.Row - 1;
  if MessageDlg(Format('Excluir o item "%s" do pedido?',
    [FController.Pedido.Itens[Indice].Descricao]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  FController.ExcluirItem(Indice);
  // Regrava grid e total na hora, para a tela refletir a exclusão.
  AtualizarGrid;
  AtualizarTotal;
  AtualizarBotaoItem;
  if FController.Pedido.Itens.Count = 0 then
    LimparCamposItem;
end;

procedure TfrmPedidoVenda.sgItensDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Texto: string;
  Flags: Integer;
begin
  Texto := sgItens.Cells[ACol, ARow];
  if ARow = 0 then
  begin
    sgItens.Canvas.Brush.Color := RGB($1F, $29, $37);
    sgItens.Canvas.Font.Color := clWhite;
    sgItens.Canvas.Font.Style := [fsBold];
  end
  else if gdSelected in State then
  begin
    sgItens.Canvas.Brush.Color := RGB($25, $63, $EB);
    sgItens.Canvas.Font.Color := clWhite;
  end
  else
  begin
    if Odd(ARow) then
      sgItens.Canvas.Brush.Color := clWhite
    else
      sgItens.Canvas.Brush.Color := RGB($F9, $FA, $FB);
    sgItens.Canvas.Font.Color := RGB($11, $18, $27);
  end;
  sgItens.Canvas.FillRect(Rect);

  Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  if ACol >= COL_QUANTIDADE then
    Flags := Flags or DT_RIGHT
  else
    Flags := Flags or DT_LEFT;
  InflateRect(Rect, -8, 0);
  DrawText(sgItens.Canvas.Handle, PChar(Texto), Length(Texto), Rect, Flags);
end;

function TfrmPedidoVenda.PedirNumeroPedido(const ATitulo: string;
  out ANumero: Integer): Boolean;
var
  Valor: string;
begin
  Result := False;
  Valor := '';
  if not InputQuery(ATitulo, 'Número do pedido', Valor) then
    Exit;
  if not TryStrToInt(Trim(Valor), ANumero) or (ANumero <= 0) then
  begin
    MostrarErro('Número de pedido inválido.');
    Exit;
  end;
  Result := True;
end;

procedure TfrmPedidoVenda.btnNovoClick(Sender: TObject);
begin
  FController.NovoPedido;
  AtualizarTela;
  edtCodCliente.SetFocus;
end;

procedure TfrmPedidoVenda.btnCarregarClick(Sender: TObject);
var
  Numero: Integer;
begin
  LimparMensagem;
  if not PedirNumeroPedido('Carregar pedido', Numero) then
    Exit;
  try
    FController.CarregarPedido(Numero);
  except
    on E: EPedidoErro do
    begin
      MostrarErro(E.Message);
      Exit;
    end;
  end;
  AtualizarTela;
end;

procedure TfrmPedidoVenda.btnCancelarPedidoClick(Sender: TObject);
var
  Numero: Integer;
begin
  LimparMensagem;
  Numero := FController.Pedido.Numero;
  if Numero <= 0 then
    if not PedirNumeroPedido('Cancelar pedido', Numero) then
      Exit;

  if MessageDlg(Format('Cancelar o pedido %d? Os itens também serão excluídos.',
    [Numero]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    FController.CancelarPedido(Numero);
  except
    on E: EPedidoErro do
    begin
      MostrarErro(E.Message);
      Exit;
    end;
  end;
  AtualizarTela;
  ShowMessage(Format('Pedido %d cancelado.', [Numero]));
end;

procedure TfrmPedidoVenda.btnGravarClick(Sender: TObject);
begin
  LimparMensagem;
  try
    FController.GravarPedido;
  except
    on E: EPedidoErro do
    begin
      MostrarErro(E.Message);
      Exit;
    end;
  end;
  ShowMessage(Format('Pedido %d gravado com sucesso.', [FController.Pedido.Numero]));
  FController.NovoPedido;
  AtualizarTela;
  edtCodCliente.SetFocus;
end;

end.
