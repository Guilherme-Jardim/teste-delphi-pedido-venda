unit Pedido.Presentation.Principal;

{ Tela do Pedido de Venda. Todo o visual está no .dfm, montado com os
  componentes do pacote Componentes.Pedido. Aqui ficam só os eventos:
  ler campos, mostrar dados e capturar o teclado. Regras de negócio ficam
  nos controllers e o SQL nos DAOs. }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Pedido.Application.Interfaces,
  Pedido.Domain.Pedido,
  Pedido.Infra.Idioma,
  ComponentIcons,
  FlagButton,
  RoundButton,
  InfoCard,
  ModernEdit,
  AlertBar,
  ModernGrid;

type
  TfrmPedidoVenda = class(TForm)
    cardItem: TInfoCard;
    edtCodProduto: TModernEdit;
    edtDescricao: TModernEdit;
    edtQuantidade: TModernEdit;
    edtVlrUnitario: TModernEdit;
    btnInserirItem: TRoundButton;
    cardCliente: TInfoCard;
    edtCodCliente: TModernEdit;
    edtNomeCliente: TModernEdit;
    edtCidadeCliente: TModernEdit;
    edtUFCliente: TModernEdit;
    edtObservacao: TModernEdit;
    avisoMensagem: TAlertBar;
    pnlTopo: TPanel;
    btnLogo: TRoundButton;
    btnBandeiraEs: TFlagButton;
    btnBandeiraPt: TFlagButton;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblVersao: TLabel;
    lblNumeroPedido: TLabel;
    btnSair: TRoundButton;
    pnlRodape: TPanel;
    pnlRodapeLinha: TPanel;
    lblTotalRotulo: TLabel;
    lblTotal: TLabel;
    btnNovo: TRoundButton;
    btnCarregar: TRoundButton;
    btnCancelar: TRoundButton;
    btnGravar: TRoundButton;
    cardGrade: TInfoCard;
    gridItens: TModernGrid;
    btnEditarItem: TRoundButton;
    btnExcluirItem: TRoundButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnBandeiraEsClick(Sender: TObject);
    procedure btnBandeiraPtClick(Sender: TObject);
    procedure edtCodClienteSaida(Sender: TObject);
    procedure edtCodProdutoSaida(Sender: TObject);
    procedure btnInserirItemClick(Sender: TObject);
    procedure btnEditarItemClick(Sender: TObject);
    procedure btnExcluirItemClick(Sender: TObject);
    procedure gridItensKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCarregarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
  private
    FCasosDeUso: TCasosDeUsoPedido;
    FPedido: TPedido;
    FIndiceEmEdicao: Integer;

    procedure NovoPedido;
    procedure AplicarIdioma;
    procedure TrocarIdioma(AIdioma: TIdioma);
    procedure TratarExcecao(Sender: TObject; E: Exception);
    procedure AtualizarTela;
    procedure AtualizarGrade;
    procedure AtualizarTotal;
    procedure AtualizarBotaoItem;
    procedure LimparCliente;
    procedure LimparCamposItem;
    procedure PreencherCliente(ACodigo: Integer);
    procedure CarregarItemSelecionado;
    procedure ExcluirItemSelecionado;
    procedure MostrarErro(const AMensagem: string);
    function LerCodigo(ACampo: TModernEdit; out ACodigo: Integer): Boolean;
    function PedirNumeroPedido(const ATitulo: string; out ANumero: Integer): Boolean;
  public
    // Recebe os casos de uso (montados na raiz de composição).
    procedure Iniciar(const ACasosDeUso: TCasosDeUsoPedido);
  end;

var
  frmPedidoVenda: TfrmPedidoVenda;

implementation

{$R *.dfm}

uses
  Pedido.Infra.Log,
  Pedido.Infra.Versao,
  Pedido.Domain.Cliente,
  Pedido.Domain.Erros,
  Pedido.Domain.PedidoItem,
  Pedido.Domain.Produto,
  Pedido.Presentation.TradutorErros,
  Pedido.Presentation.Dialogos,
  Pedido.Presentation.NumeroPedido;

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
  FIndiceEmEdicao := -1;
  FPedido := TPedido.Create;
  CarregarIdiomaSalvo;
  AplicarIdioma;
end;

procedure TfrmPedidoVenda.FormDestroy(Sender: TObject);
begin
  FPedido.Free;
end;

procedure TfrmPedidoVenda.Iniciar(const ACasosDeUso: TCasosDeUsoPedido);
begin
  FCasosDeUso := ACasosDeUso;
  Application.OnException := TratarExcecao;
  AtualizarTela;
  ActiveControl := edtCodCliente.Edit;
end;

procedure TfrmPedidoVenda.AplicarIdioma;
begin
  Caption := Tr('app.titulo') + ' ' + VersaoDoExecutavel.Resumida;
  lblTitulo.Caption := Tr('app.titulo');
  lblVersao.Caption := 'v' + VersaoDoExecutavel.Resumida;
  lblSubtitulo.Caption := Tr('app.subtitulo');
  lblTotalRotulo.Caption := Tr('total.rotulo');

  cardCliente.Titulo := Tr('cliente.titulo');
  edtCodCliente.Rotulo := Tr('campo.codigo');
  edtNomeCliente.Rotulo := Tr('campo.nome');
  edtCidadeCliente.Rotulo := Tr('campo.cidade');
  edtUFCliente.Rotulo := Tr('campo.uf');
  edtObservacao.Rotulo := Tr('campo.obs');
  edtCodCliente.Dica := Tr('hint.cod_cliente');
  edtNomeCliente.Dica := Tr('hint.nome');
  edtObservacao.Dica := Tr('hint.obs');

  cardItem.Titulo := Tr('item.titulo');
  edtCodProduto.Rotulo := Tr('campo.codigo');
  edtDescricao.Rotulo := Tr('campo.descricao');
  edtQuantidade.Rotulo := Tr('campo.quantidade');
  edtVlrUnitario.Rotulo := Tr('campo.vlrunit');
  edtCodProduto.Dica := Tr('hint.cod_produto');
  edtDescricao.Dica := Tr('hint.descricao');
  edtQuantidade.Dica := Tr('hint.quantidade');
  edtVlrUnitario.Dica := Tr('hint.vlrunit');

  cardGrade.Titulo := Tr('grade.titulo');
  gridItens.DefinirColunas(
    [Tr('grade.codigo'), Tr('grade.descricao'), Tr('grade.quantidade'), Tr('grade.unitario'),
     Tr('grade.total')],
    [120, 400, 120, 140, 140]);
  gridItens.Hint := Tr('hint.grade');
  gridItens.NomeAcessivel := Tr('grade.titulo');
  gridItens.TextoLinha := Tr('a11y.linha');
  gridItens.ShowHint := True;

  btnNovo.Caption := Tr('btn.novo');
  btnCarregar.Caption := Tr('btn.carregar');
  btnCancelar.Caption := Tr('btn.cancelar');
  btnGravar.Caption := Tr('btn.gravar');

  // Dicas e nomes para leitores de tela
  btnNovo.Hint := Tr('hint.novo');
  btnCarregar.Hint := Tr('hint.carregar');
  btnCancelar.Hint := Tr('hint.cancelar');
  btnGravar.Hint := Tr('hint.gravar');
  btnInserirItem.Hint := Tr('hint.inserir');
  btnEditarItem.Hint := Tr('hint.editar');
  btnExcluirItem.Hint := Tr('hint.excluir');
  btnSair.Hint := Tr('hint.sair');
  for var Botao in [btnNovo, btnCarregar, btnCancelar, btnGravar, btnInserirItem] do
    Botao.ShowHint := True;
  btnEditarItem.Caption := Tr('hint.editar');
  btnExcluirItem.Caption := Tr('hint.excluir');
  btnSair.Caption := Tr('hint.sair');
  btnLogo.Caption := Tr('app.titulo');

  btnBandeiraEs.Hint := Tr('idioma.trocar_es');
  btnBandeiraEs.Caption := Tr('idioma.es');
  btnBandeiraEs.Ativo := IdiomaAtual = idEspanhol;
  btnBandeiraPt.Hint := Tr('idioma.trocar_pt');
  btnBandeiraPt.Caption := Tr('idioma.pt');
  btnBandeiraPt.Ativo := IdiomaAtual = idPortugues;

  if FPedido <> nil then
  begin
    if FPedido.Numero > 0 then
      lblNumeroPedido.Caption := Tr('pedido.numero', [FPedido.Numero])
    else
      lblNumeroPedido.Caption := Tr('pedido.novo');
    if FCasosDeUso.Gravar <> nil then
    begin
      AtualizarGrade;
      AtualizarBotaoItem;
    end;
  end;
end;

procedure TfrmPedidoVenda.TrocarIdioma(AIdioma: TIdioma);
begin
  if AIdioma = IdiomaAtual then
    Exit;
  DefinirIdioma(AIdioma);
  AplicarIdioma;
  avisoMensagem.Limpar;
end;

procedure TfrmPedidoVenda.btnBandeiraEsClick(Sender: TObject);
begin
  TrocarIdioma(idEspanhol);
end;

procedure TfrmPedidoVenda.btnBandeiraPtClick(Sender: TObject);
begin
  TrocarIdioma(idPortugues);
end;

procedure TfrmPedidoVenda.TratarExcecao(Sender: TObject; E: Exception);
begin
  // Falha inesperada: o detalhe técnico vai para o log e a tela mostra um aviso simples.
  RegistrarLog('Falha inesperada', E);
  MostrarErro(Tr('msg.erro_inesperado'));
end;

procedure TfrmPedidoVenda.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if not (ssCtrl in Shift) then
    Exit;
  case Key of
    Ord('G'): btnGravarClick(Sender);
    Ord('N'): btnNovoClick(Sender);
    Ord('L'): btnCarregarClick(Sender);
    Ord('D'): btnCancelarClick(Sender);
    VK_RETURN: btnInserirItemClick(Sender);
  else
    Exit;
  end;
  Key := 0;
end;

procedure TfrmPedidoVenda.MostrarErro(const AMensagem: string);
begin
  avisoMensagem.Mostrar(AMensagem, taErro);
end;

function TfrmPedidoVenda.LerCodigo(ACampo: TModernEdit; out ACodigo: Integer): Boolean;
begin
  Result := TryStrToInt(Trim(ACampo.Texto), ACodigo) and (ACodigo > 0);
end;

procedure TfrmPedidoVenda.LimparCliente;
begin
  edtNomeCliente.Limpar;
  edtCidadeCliente.Limpar;
  edtUFCliente.Limpar;
end;

procedure TfrmPedidoVenda.LimparCamposItem;
begin
  edtCodProduto.Limpar;
  edtDescricao.Limpar;
  edtQuantidade.Limpar;
  edtVlrUnitario.Limpar;
end;

procedure TfrmPedidoVenda.PreencherCliente(ACodigo: Integer);
var
  Cliente: TCliente;
begin
  Cliente := FCasosDeUso.ConsultarCliente.Executar(ACodigo);
  try
    FPedido.InformarCliente(Cliente.Codigo);
    edtCodCliente.Texto := IntToStr(Cliente.Codigo);
    edtNomeCliente.Texto := Cliente.Nome;
    edtCidadeCliente.Texto := Cliente.Cidade;
    edtUFCliente.Texto := Cliente.UF;
  finally
    Cliente.Free;
  end;
end;

procedure TfrmPedidoVenda.NovoPedido;
begin
  FPedido.Free;
  FPedido := TPedido.Create;
  FIndiceEmEdicao := -1;
  AtualizarTela;
end;

procedure TfrmPedidoVenda.AtualizarTela;
begin
  avisoMensagem.Limpar;
  if FPedido.Numero > 0 then
    lblNumeroPedido.Caption := Tr('pedido.numero', [FPedido.Numero])
  else
    lblNumeroPedido.Caption := Tr('pedido.novo');

  if FPedido.CodigoCliente > 0 then
    PreencherCliente(FPedido.CodigoCliente)
  else
  begin
    edtCodCliente.Limpar;
    LimparCliente;
  end;
  edtObservacao.Texto := FPedido.Observacao;

  LimparCamposItem;
  AtualizarGrade;
  AtualizarTotal;
  AtualizarBotaoItem;
end;

procedure TfrmPedidoVenda.AtualizarGrade;
var
  I: Integer;
  Item: TPedidoItem;
begin
  if FPedido.Itens.Count = 0 then
  begin
    gridItens.LimparLinhas;
    Exit;
  end;

  gridItens.RowCount := FPedido.Itens.Count + 1;
  for I := 0 to FPedido.Itens.Count - 1 do
  begin
    Item := FPedido.Itens[I];
    gridItens.Cells[COL_CODIGO, I + 1] := IntToStr(Item.CodigoProduto);
    gridItens.Cells[COL_DESCRICAO, I + 1] := Item.Descricao;
    gridItens.Cells[COL_QUANTIDADE, I + 1] := FormatFloat('#,##0.###', Item.Quantidade.Valor);
    gridItens.Cells[COL_VLR_UNITARIO, I + 1] := FormatarMoeda(Item.VlrUnitario.Valor);
    gridItens.Cells[COL_VLR_TOTAL, I + 1] := FormatarMoeda(Item.VlrTotal.Valor);
  end;
end;

procedure TfrmPedidoVenda.AtualizarTotal;
begin
  // Sempre calculado a partir dos itens.
  lblTotal.Caption := 'R$ ' + FormatarMoeda(FPedido.ValorTotal.Valor);
end;

procedure TfrmPedidoVenda.AtualizarBotaoItem;
begin
  if FIndiceEmEdicao >= 0 then
  begin
    btnInserirItem.Caption := Tr('item.atualizar');
    btnInserirItem.Icone := icCheck;
  end
  else
  begin
    btnInserirItem.Caption := Tr('item.inserir');
    btnInserirItem.Icone := icMais;
  end;
end;

procedure TfrmPedidoVenda.edtCodClienteSaida(Sender: TObject);
var
  Codigo: Integer;
begin
  avisoMensagem.Limpar;
  if Trim(edtCodCliente.Texto) = '' then
  begin
    FPedido.RemoverCliente;
    LimparCliente;
    Exit;
  end;
  if not LerCodigo(edtCodCliente, Codigo) then
  begin
    FPedido.RemoverCliente;
    LimparCliente;
    MostrarErro(Tr('msg.cliente_invalido'));
    Exit;
  end;
  try
    PreencherCliente(Codigo);
  except
    on E: EDominioErro do
    begin
      FPedido.RemoverCliente;
      LimparCliente;
      MostrarErro(MensagemDoErro(E));
    end;
  end;
end;

procedure TfrmPedidoVenda.edtCodProdutoSaida(Sender: TObject);
var
  Codigo: Integer;
  Produto: TProduto;
begin
  avisoMensagem.Limpar;
  if Trim(edtCodProduto.Texto) = '' then
  begin
    edtDescricao.Limpar;
    Exit;
  end;
  if not LerCodigo(edtCodProduto, Codigo) then
  begin
    edtDescricao.Limpar;
    MostrarErro(Tr('msg.produto_invalido'));
    Exit;
  end;
  try
    Produto := FCasosDeUso.ConsultarProduto.Executar(Codigo);
    try
      edtDescricao.Texto := Produto.Descricao;
      // Sugere o preço de venda; o operador pode alterar.
      if FIndiceEmEdicao < 0 then
        edtVlrUnitario.Texto := FormatFloat('0.00', Produto.PrecoVenda.Valor);
    finally
      Produto.Free;
    end;
  except
    on E: EDominioErro do
    begin
      edtDescricao.Limpar;
      MostrarErro(MensagemDoErro(E));
    end;
  end;
end;

procedure TfrmPedidoVenda.btnInserirItemClick(Sender: TObject);
var
  Codigo, Indice: Integer;
  Quantidade: Double;
  Valor: Currency;
  Item: TPedidoItem;
begin
  avisoMensagem.Limpar;
  if not LerCodigo(edtCodProduto, Codigo) then
  begin
    MostrarErro(Tr('msg.informe_produto'));
    edtCodProduto.SetFocus;
    Exit;
  end;
  if not TryStrToFloat(Trim(edtQuantidade.Texto), Quantidade) or (Quantidade <= 0) then
  begin
    MostrarErro(Tr('msg.informe_quantidade'));
    edtQuantidade.SetFocus;
    Exit;
  end;
  if not TryStrToCurr(Trim(edtVlrUnitario.Texto), Valor) or (Valor < 0) then
  begin
    MostrarErro(Tr('msg.informe_valor'));
    edtVlrUnitario.SetFocus;
    Exit;
  end;

  try
    Item := FCasosDeUso.CriarItem.Executar(Codigo, Quantidade, Valor);
    if FIndiceEmEdicao >= 0 then
    begin
      Indice := FIndiceEmEdicao;
      FPedido.AtualizarItem(Indice, Item);
      FIndiceEmEdicao := -1;
    end
    else
      Indice := FPedido.AdicionarItem(Item);
  except
    on E: EDominioErro do
    begin
      MostrarErro(MensagemDoErro(E));
      Exit;
    end;
  end;

  LimparCamposItem;
  AtualizarGrade;
  gridItens.Row := Indice + 1;
  AtualizarTotal;
  AtualizarBotaoItem;
  edtCodProduto.SetFocus;
end;

procedure TfrmPedidoVenda.gridItensKeyDown(Sender: TObject; var Key: Word;
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

procedure TfrmPedidoVenda.btnEditarItemClick(Sender: TObject);
begin
  CarregarItemSelecionado;
end;

procedure TfrmPedidoVenda.btnExcluirItemClick(Sender: TObject);
begin
  ExcluirItemSelecionado;
end;

procedure TfrmPedidoVenda.CarregarItemSelecionado;
var
  Indice: Integer;
  Item: TPedidoItem;
begin
  avisoMensagem.Limpar;
  Indice := gridItens.Row - 1;
  if (FPedido.Itens.Count = 0) or (Indice < 0) or (Indice >= FPedido.Itens.Count) then
  begin
    MostrarErro(Tr('msg.selecione_item'));
    Exit;
  end;

  FIndiceEmEdicao := Indice;
  Item := FPedido.Itens[Indice];
  edtCodProduto.Texto := IntToStr(Item.CodigoProduto);
  edtDescricao.Texto := Item.Descricao;
  edtQuantidade.Texto := FloatToStr(Item.Quantidade.Valor);
  edtVlrUnitario.Texto := FormatFloat('0.00', Item.VlrUnitario.Valor);
  AtualizarBotaoItem;
  edtQuantidade.SetFocus;
end;

procedure TfrmPedidoVenda.ExcluirItemSelecionado;
var
  Indice: Integer;
begin
  avisoMensagem.Limpar;
  Indice := gridItens.Row - 1;
  if (FPedido.Itens.Count = 0) or (Indice < 0) or (Indice >= FPedido.Itens.Count) then
    Exit;

  if not ConfirmarAcao(Tr('msg.confirmar_excluir_item', [FPedido.Itens[Indice].Descricao]), True) then
    Exit;

  FPedido.RemoverItem(Indice);
  // Ajusta o índice do item em edição, se houver.
  if FIndiceEmEdicao = Indice then
  begin
    FIndiceEmEdicao := -1;
    LimparCamposItem;
  end
  else if FIndiceEmEdicao > Indice then
    Dec(FIndiceEmEdicao);

  // Grade e total são refeitos na hora, para a tela refletir a exclusão.
  AtualizarGrade;
  AtualizarTotal;
  AtualizarBotaoItem;
end;

function TfrmPedidoVenda.PedirNumeroPedido(const ATitulo: string;
  out ANumero: Integer): Boolean;
begin
  Result := TfrmNumeroPedido.Perguntar(ATitulo, ANumero);
end;

procedure TfrmPedidoVenda.btnNovoClick(Sender: TObject);
begin
  NovoPedido;
  edtCodCliente.SetFocus;
end;

procedure TfrmPedidoVenda.btnCarregarClick(Sender: TObject);
var
  Numero: Integer;
  Carregado: TPedido;
begin
  avisoMensagem.Limpar;
  if not PedirNumeroPedido(Tr('dlg.numero_carregar'), Numero) then
    Exit;
  try
    Carregado := FCasosDeUso.Carregar.Executar(Numero);
  except
    on E: EDominioErro do
    begin
      MostrarErro(MensagemDoErro(E));
      Exit;
    end;
  end;
  FPedido.Free;
  FPedido := Carregado;
  FIndiceEmEdicao := -1;
  AtualizarTela;
end;

procedure TfrmPedidoVenda.btnCancelarClick(Sender: TObject);
var
  Numero: Integer;
begin
  avisoMensagem.Limpar;
  Numero := FPedido.Numero;
  if Numero <= 0 then
    if not PedirNumeroPedido(Tr('dlg.numero_cancelar'), Numero) then
      Exit;

  if not ConfirmarAcao(Tr('msg.confirmar_cancelar', [Numero]), True) then
    Exit;

  try
    FCasosDeUso.Cancelar.Executar(Numero);
  except
    on E: EDominioErro do
    begin
      MostrarErro(MensagemDoErro(E));
      Exit;
    end;
  end;

  // Se o pedido cancelado era o da tela, limpa a tela.
  if FPedido.Numero = Numero then
    NovoPedido;
  avisoMensagem.Mostrar(Tr('msg.cancelado', [Numero]), taSucesso);
end;

procedure TfrmPedidoVenda.btnGravarClick(Sender: TObject);
var
  Numero: Integer;
begin
  avisoMensagem.Limpar;
  try
    FPedido.DefinirObservacao(edtObservacao.Texto);
    FCasosDeUso.Gravar.Executar(FPedido);
  except
    on E: EDominioErro do
    begin
      MostrarErro(MensagemDoErro(E));
      Exit;
    end;
  end;

  Numero := FPedido.Numero;
  NovoPedido;
  avisoMensagem.Mostrar(Tr('msg.gravado', [Numero]), taSucesso);
  edtCodCliente.SetFocus;
end;

procedure TfrmPedidoVenda.btnSairClick(Sender: TObject);
begin
  Close;
end;

end.
