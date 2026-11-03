unit ModernGrid;

{ Grade de itens com cabeçalho e seleção estilizados. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  System.Classes,
  System.SysUtils,
  System.Math,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Grids,
  ComponentAccess,
  ComponentIcons,
  ComponentTheme,
  ComponentUtils;

const
  WM_AVISO_ACESSIVEL = WM_USER + 301;

type
  { TModernGrid }
  TModernGrid = class(TStringGrid)
  private
    FColunaFlexivel: Integer;
    FPrimeiraColunaNumerica: Integer;
    FNomeAcessivel: string;
    FTextoLinha: string;
    function DescreverLinhaAtual: string;
    procedure WMGetObject(var Msg: TMessage); message WM_GETOBJECT;
    procedure WMAvisoAcessivel(var Msg: TMessage); message WM_AVISO_ACESSIVEL;
  protected
    function SelectCell(ACol, ARow: LongInt): Boolean; override;
    procedure DrawCell(ACol, ARow: LongInt; ARect: TRect; AState: TGridDrawState); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DefinirColunas(const ATitulos: array of string;
      const ALarguras: array of Integer);
    procedure LimparLinhas;
  published
    // Coluna que ocupa o espaço que sobra na largura da grade.
    property ColunaFlexivel: Integer read FColunaFlexivel write FColunaFlexivel;
    // Colunas a partir desta ficam alinhadas à direita.
    property PrimeiraColunaNumerica: Integer read FPrimeiraColunaNumerica
      write FPrimeiraColunaNumerica;
    // Nome lido por leitores de tela (ex.: "Itens do pedido").
    property NomeAcessivel: string read FNomeAcessivel write FNomeAcessivel;
    // Modelo da frase da linha atual: primeiro a posição, depois o total (ex.: "Linha %d de %d").
    property TextoLinha: string read FTextoLinha write FTextoLinha;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pedido', [TModernGrid]);
end;

{ TModernGrid }

constructor TModernGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BorderStyle := bsNone;
  Color := CorCartao;
  DefaultRowHeight := 38;
  RowHeights[0] := 36;
  FixedCols := 0;
  FixedRows := 1;
  RowCount := 2;
  GridLineWidth := 0;
  ScrollBars := ssVertical;
  Options := [goRowSelect, goThumbTracking];
  Font.Name := FonteNome;
  Font.Size := 10;
  FColunaFlexivel := -1;
  FPrimeiraColunaNumerica := MaxInt;
  FTextoLinha := 'Linha %d de %d';
end;

function TModernGrid.DescreverLinhaAtual: string;
var
  Coluna, Linha, Total: Integer;
begin
  Result := '';
  if (Row < 1) or (Cells[0, Row] = '') then
    Exit;
  Total := 0;
  for Linha := 1 to RowCount - 1 do
    if Cells[0, Linha] <> '' then
      Inc(Total);
  Result := Format(FTextoLinha, [Row, Total]);
  for Coluna := 0 to ColCount - 1 do
    Result := Result + '; ' + Cells[Coluna, 0] + ' ' + Cells[Coluna, Row];
end;

procedure TModernGrid.WMGetObject(var Msg: TMessage);
begin
  if not ResponderGetObject(Self, Msg,
    function: TDadosAcessiveis
    begin
      Result := NovosDados(FNomeAcessivel, PAPEL_LISTA);
      Result.Valor := DescreverLinhaAtual;
    end) then
    inherited;
end;

function TModernGrid.SelectCell(ACol, ARow: LongInt): Boolean;
begin
  Result := inherited SelectCell(ACol, ARow);
  // O valor novo só existe depois que a seleção termina: avisa em seguida.
  if Result and HandleAllocated then
    PostMessage(Handle, WM_AVISO_ACESSIVEL, 0, 0);
end;

procedure TModernGrid.WMAvisoAcessivel(var Msg: TMessage);
begin
  AvisarMudanca(Self, EVENTO_VALOR_MUDOU);
end;

procedure TModernGrid.DefinirColunas(const ATitulos: array of string;
  const ALarguras: array of Integer);
var
  I: Integer;
begin
  ColCount := Length(ATitulos);
  for I := 0 to High(ATitulos) do
  begin
    Cells[I, 0] := ATitulos[I];
    if I <= High(ALarguras) then
      ColWidths[I] := ALarguras[I];
  end;
end;

procedure TModernGrid.LimparLinhas;
var
  I: Integer;
begin
  for I := 1 to RowCount - 1 do
    Rows[I].Clear;
  RowCount := 2;
end;

procedure TModernGrid.Resize;
var
  I, Outras: Integer;
begin
  inherited;
  if (FColunaFlexivel >= 0) and (FColunaFlexivel < ColCount) then
  begin
    Outras := 0;
    for I := 0 to ColCount - 1 do
      if I <> FColunaFlexivel then
        Inc(Outras, ColWidths[I]);
    ColWidths[FColunaFlexivel] := Max(160, ClientWidth - Outras - GetSystemMetrics(SM_CXVSCROLL) - 2);
  end;
end;

procedure TModernGrid.DrawCell(ACol, ARow: LongInt; ARect: TRect; AState: TGridDrawState);
var
  Texto: string;
  Formato: Cardinal;
  Selecionada: Boolean;
begin
  Texto := Cells[ACol, ARow];
  Selecionada := (ARow > 0) and (gdSelected in AState) and (Cells[0, ARow] <> '');

  if ARow = 0 then
  begin
    Canvas.Brush.Color := CorFundo;
    Canvas.Font.Name := FonteNomeNegrito;
    Canvas.Font.Size := 9;
    Canvas.Font.Color := CorTextoSuave;
  end
  else if Selecionada then
  begin
    Canvas.Brush.Color := CorPrimariaSuave;
    Canvas.Font.Name := FonteNomeNegrito;
    Canvas.Font.Size := 10;
    Canvas.Font.Color := CorPrimariaPress;
  end
  else
  begin
    Canvas.Brush.Color := CorCartao;
    Canvas.Font.Name := FonteNome;
    Canvas.Font.Size := 10;
    Canvas.Font.Color := CorTexto;
  end;
  Canvas.FillRect(ARect);

  // Linha divisória inferior
  Canvas.Pen.Color := CorBorda;
  Canvas.MoveTo(ARect.Left, ARect.Bottom - 1);
  Canvas.LineTo(ARect.Right, ARect.Bottom - 1);

  Formato := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
  if ACol >= FPrimeiraColunaNumerica then
    Formato := Formato or DT_RIGHT
  else
    Formato := Formato or DT_LEFT;
  Inc(ARect.Left, 14);
  Dec(ARect.Right, 14);
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(Texto), Length(Texto), ARect, Formato);
end;


end.
