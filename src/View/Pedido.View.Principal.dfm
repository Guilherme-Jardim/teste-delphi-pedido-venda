object frmPedidoVenda: TfrmPedidoVenda
  Left = 0
  Top = 0
  Caption = 'Pedido de Venda'
  ClientHeight = 668
  ClientWidth = 980
  Color = 16184563
  Constraints.MinHeight = 600
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 2562065
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  object pnlTopo: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 68
    Align = alTop
    BevelOuter = bvNone
    Color = 3615007
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 10
      Width = 168
      Height = 30
      Caption = 'Pedido de Venda'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -22
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 16
      Top = 40
      Width = 283
      Height = 17
      Caption = 'Informe o cliente, adicione os itens e grave o pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14211288
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblNumeroPedido: TLabel
      Left = 700
      Top = 20
      Width = 264
      Height = 28
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'Novo pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15426341
      Font.Height = -20
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object lblMensagem: TLabel
    Left = 16
    Top = 76
    Width = 948
    Height = 20
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 2500316
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object gbCliente: TGroupBox
    Left = 16
    Top = 100
    Width = 948
    Height = 140
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Cliente '
    TabOrder = 1
    object lblCodCliente: TLabel
      Left = 16
      Top = 24
      Width = 41
      Height = 17
      Caption = 'C'#243'digo'
    end
    object lblNomeCliente: TLabel
      Left = 112
      Top = 24
      Width = 33
      Height = 17
      Caption = 'Nome'
    end
    object lblCidadeCliente: TLabel
      Left = 540
      Top = 24
      Width = 37
      Height = 17
      Caption = 'Cidade'
    end
    object lblUFCliente: TLabel
      Left = 860
      Top = 24
      Width = 16
      Height = 17
      Caption = 'UF'
    end
    object lblObservacao: TLabel
      Left = 16
      Top = 80
      Width = 65
      Height = 17
      Caption = 'Observa'#231#227'o'
    end
    object edtCodCliente: TEdit
      Left = 16
      Top = 44
      Width = 80
      Height = 25
      NumbersOnly = True
      TabOrder = 0
      OnExit = edtCodClienteExit
      OnKeyPress = CampoCodigoKeyPress
    end
    object edtNomeCliente: TEdit
      Left = 112
      Top = 44
      Width = 412
      Height = 25
      TabStop = False
      ReadOnly = True
      TabOrder = 1
    end
    object edtCidadeCliente: TEdit
      Left = 540
      Top = 44
      Width = 304
      Height = 25
      TabStop = False
      ReadOnly = True
      TabOrder = 2
    end
    object edtUFCliente: TEdit
      Left = 860
      Top = 44
      Width = 60
      Height = 25
      TabStop = False
      ReadOnly = True
      TabOrder = 3
    end
    object edtObservacao: TEdit
      Left = 16
      Top = 100
      Width = 904
      Height = 25
      MaxLength = 200
      TabOrder = 4
      OnKeyPress = CampoCodigoKeyPress
    end
  end
  object gbItem: TGroupBox
    Left = 16
    Top = 248
    Width = 948
    Height = 84
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Item '
    TabOrder = 2
    object lblCodProduto: TLabel
      Left = 16
      Top = 24
      Width = 41
      Height = 17
      Caption = 'C'#243'digo'
    end
    object lblDescricaoProduto: TLabel
      Left = 112
      Top = 24
      Width = 56
      Height = 17
      Caption = 'Descri'#231#227'o'
    end
    object lblQuantidade: TLabel
      Left = 520
      Top = 24
      Width = 66
      Height = 17
      Caption = 'Quantidade'
    end
    object lblVlrUnitario: TLabel
      Left = 636
      Top = 24
      Width = 83
      Height = 17
      Caption = 'Valor unit'#225'rio'
    end
    object edtCodProduto: TEdit
      Left = 16
      Top = 44
      Width = 80
      Height = 25
      NumbersOnly = True
      TabOrder = 0
      OnExit = edtCodProdutoExit
      OnKeyPress = CampoCodigoKeyPress
    end
    object edtDescricaoProduto: TEdit
      Left = 112
      Top = 44
      Width = 392
      Height = 25
      TabStop = False
      ReadOnly = True
      TabOrder = 1
    end
    object edtQuantidade: TEdit
      Left = 520
      Top = 44
      Width = 100
      Height = 25
      Alignment = taRightJustify
      TabOrder = 2
      OnKeyPress = CampoCodigoKeyPress
    end
    object edtVlrUnitario: TEdit
      Left = 636
      Top = 44
      Width = 120
      Height = 25
      Alignment = taRightJustify
      TabOrder = 3
      OnKeyPress = CampoCodigoKeyPress
    end
    object btnInserirItem: TButton
      Left = 772
      Top = 40
      Width = 160
      Height = 32
      Caption = 'Inserir Item'
      TabOrder = 4
      OnClick = btnInserirItemClick
    end
  end
  object sgItens: TStringGrid
    Left = 16
    Top = 344
    Width = 948
    Height = 236
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 5
    DefaultRowHeight = 26
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 3
    OnDrawCell = sgItensDrawCell
    OnKeyDown = sgItensKeyDown
  end
  object lblAtalhos: TLabel
    Left = 16
    Top = 586
    Width = 400
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Com o foco no grid: ENTER edita o item selecionado, DEL exclui.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 8417899
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object pnlRodape: TPanel
    Left = 0
    Top = 612
    Width = 980
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
    object lblTotalRotulo: TLabel
      Left = 16
      Top = 8
      Width = 129
      Height = 17
      Caption = 'Valor total do pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8417899
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblTotal: TLabel
      Left = 16
      Top = 24
      Width = 90
      Height = 28
      Caption = 'R$ 0,00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15426341
      Font.Height = -22
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object btnNovo: TButton
      Left = 456
      Top = 12
      Width = 110
      Height = 34
      Anchors = [akTop, akRight]
      Caption = 'Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnCarregar: TButton
      Left = 576
      Top = 12
      Width = 130
      Height = 34
      Anchors = [akTop, akRight]
      Caption = 'Carregar Pedido'
      TabOrder = 1
      OnClick = btnCarregarClick
    end
    object btnCancelarPedido: TButton
      Left = 716
      Top = 12
      Width = 130
      Height = 34
      Anchors = [akTop, akRight]
      Caption = 'Cancelar Pedido'
      TabOrder = 2
      OnClick = btnCancelarPedidoClick
    end
    object btnGravar: TButton
      Left = 856
      Top = 12
      Width = 108
      Height = 34
      Anchors = [akTop, akRight]
      Caption = 'Gravar Pedido'
      TabOrder = 3
      OnClick = btnGravarClick
    end
  end
end
