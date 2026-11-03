object frmPedidoVenda: TfrmPedidoVenda
  Left = 0
  Top = 0
  Caption = 'Pedido de Venda'
  ClientHeight = 780
  ClientWidth = 1120
  Color = 16184563
  Constraints.MinHeight = 680
  Constraints.MinWidth = 1040
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 2562065
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  TextHeight = 17
  object avisoMensagem: TAlertBar
    AlignWithMargins = True
    Left = 24
    Top = 88
    Width = 1072
    Height = 38
    Margins.Left = 24
    Margins.Top = 12
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
  end
  object cardCliente: TInfoCard
    AlignWithMargins = True
    Left = 24
    Top = 138
    Width = 1072
    Height = 204
    Margins.Left = 24
    Margins.Top = 8
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    Titulo = 'Cliente'
    Icone = icUsuario
    object edtCodCliente: TModernEdit
      Left = 20
      Top = 52
      Width = 130
      Height = 60
      Edit.MaxLength = 9
      Edit.NumbersOnly = True
      Rotulo = 'C'#243'digo'
      Icone = icBusca
      OnSaida = edtCodClienteSaida
      TabOrder = 0
    end
    object edtNomeCliente: TModernEdit
      Left = 166
      Top = 52
      Width = 440
      Height = 60
      Anchors = [akLeft, akTop, akRight]
      Rotulo = 'Nome'
      SomenteLeitura = True
      TabOrder = 1
    end
    object edtCidadeCliente: TModernEdit
      Left = 622
      Top = 52
      Width = 310
      Height = 60
      Anchors = [akTop, akRight]
      Rotulo = 'Cidade'
      SomenteLeitura = True
      TabOrder = 2
    end
    object edtUFCliente: TModernEdit
      Left = 948
      Top = 52
      Width = 104
      Height = 60
      Anchors = [akTop, akRight]
      Rotulo = 'UF'
      SomenteLeitura = True
      TabOrder = 3
    end
    object edtObservacao: TModernEdit
      Left = 20
      Top = 124
      Width = 1032
      Height = 60
      Anchors = [akLeft, akTop, akRight]
      Edit.MaxLength = 200
      Rotulo = 'Observa'#231#227'o'
      TabOrder = 4
    end
  end
  object cardItem: TInfoCard
    AlignWithMargins = True
    Left = 24
    Top = 350
    Width = 1072
    Height = 132
    Margins.Left = 24
    Margins.Top = 8
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    Titulo = 'Item'
    Icone = icCaixa
    object edtCodProduto: TModernEdit
      Left = 20
      Top = 52
      Width = 130
      Height = 60
      Edit.MaxLength = 9
      Edit.NumbersOnly = True
      Rotulo = 'C'#243'digo'
      Icone = icBusca
      OnSaida = edtCodProdutoSaida
      TabOrder = 0
    end
    object edtDescricao: TModernEdit
      Left = 166
      Top = 52
      Width = 388
      Height = 60
      Anchors = [akLeft, akTop, akRight]
      Rotulo = 'Descri'#231#227'o'
      SomenteLeitura = True
      TabOrder = 1
    end
    object edtQuantidade: TModernEdit
      Left = 570
      Top = 52
      Width = 130
      Height = 60
      Anchors = [akTop, akRight]
      Edit.Alignment = taRightJustify
      Edit.MaxLength = 15
      Rotulo = 'Quantidade'
      TabOrder = 2
    end
    object edtVlrUnitario: TModernEdit
      Left = 716
      Top = 52
      Width = 150
      Height = 60
      Anchors = [akTop, akRight]
      Edit.Alignment = taRightJustify
      Edit.MaxLength = 15
      Rotulo = 'Valor unit'#225'rio'
      TabOrder = 3
    end
    object btnInserirItem: TRoundButton
      Left = 882
      Top = 73
      Width = 170
      Height = 40
      Anchors = [akTop, akRight]
      Caption = 'Inserir item'
      TabOrder = 4
      Icone = icMais
      Estilo = ebPrimario
      OnClick = btnInserirItemClick
    end
  end
  object cardGrade: TInfoCard
    AlignWithMargins = True
    Left = 24
    Top = 744
    Width = 1072
    Height = 100
    Margins.Left = 24
    Margins.Top = 8
    Margins.Right = 24
    Margins.Bottom = 8
    Align = alClient
    Padding.Left = 1
    Padding.Top = 52
    Padding.Right = 1
    Padding.Bottom = 1
    Titulo = 'Itens do pedido'
    Icone = icPasta
    object gridItens: TModernGrid
      Left = 1
      Top = 52
      Width = 1070
      Height = 47
      Align = alClient
      ColCount = 5
      FixedCols = 0
      RowCount = 2
      TabOrder = 0
      OnDblClick = btnEditarItemClick
      OnKeyDown = gridItensKeyDown
      ColunaFlexivel = 1
      PrimeiraColunaNumerica = 2
      ColWidths = (
        120
        400
        120
        140
        140)
    end
    object btnEditarItem: TRoundButton
      Left = 972
      Top = 8
      Width = 36
      Height = 36
      Hint = 'Editar o item selecionado (Enter na grade)'
      Anchors = [akTop, akRight]
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      SomenteIcone = True
      Icone = icLapis
      Estilo = ebSecundario
      OnClick = btnEditarItemClick
    end
    object btnExcluirItem: TRoundButton
      Left = 1016
      Top = 8
      Width = 36
      Height = 36
      Hint = 'Excluir o item selecionado (Delete na grade)'
      Anchors = [akTop, akRight]
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      SomenteIcone = True
      Icone = icLixeira
      Estilo = ebPerigo
      OnClick = btnExcluirItemClick
    end
  end
  object pnlRodape: TPanel
    Left = 0
    Top = 692
    Width = 1120
    Height = 88
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    object pnlRodapeLinha: TPanel
      Left = 0
      Top = 0
      Width = 1120
      Height = 1
      Align = alTop
      BevelOuter = bvNone
      Color = 15460325
      ParentBackground = False
      TabOrder = 4
    end
    object lblTotalRotulo: TLabel
      Left = 24
      Top = 16
      Width = 129
      Height = 17
      Caption = 'Valor total do pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6509899
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblTotal: TLabel
      Left = 24
      Top = 36
      Width = 90
      Height = 39
      Caption = 'R$ 0,00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15426341
      Font.Height = -29
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object btnNovo: TRoundButton
      Left = 348
      Top = 21
      Width = 120
      Height = 46
      Anchors = [akTop, akRight]
      Caption = 'Novo'
      TabOrder = 0
      Icone = icNovo
      Estilo = ebSecundario
      OnClick = btnNovoClick
    end
    object btnCarregar: TRoundButton
      Left = 484
      Top = 21
      Width = 190
      Height = 46
      Anchors = [akTop, akRight]
      Caption = 'Carregar pedido'
      TabOrder = 1
      Icone = icPasta
      Estilo = ebSecundario
      OnClick = btnCarregarClick
    end
    object btnCancelar: TRoundButton
      Left = 690
      Top = 21
      Width = 190
      Height = 46
      Anchors = [akTop, akRight]
      Caption = 'Cancelar pedido'
      TabOrder = 2
      Icone = icLixeira
      Estilo = ebPerigo
      OnClick = btnCancelarClick
    end
    object btnGravar: TRoundButton
      Left = 896
      Top = 21
      Width = 200
      Height = 46
      Anchors = [akTop, akRight]
      Caption = 'Gravar pedido'
      TabOrder = 3
      Icone = icSalvar
      Estilo = ebPrimario
      OnClick = btnGravarClick
    end
  end
  object pnlTopo: TPanel
    Left = 0
    Top = 0
    Width = 1120
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    Color = 2758415
    ParentBackground = False
    object btnLogo: TRoundButton
      Left = 24
      Top = 15
      Width = 46
      Height = 46
      Cursor = crDefault
      TabStop = False
      SomenteIcone = True
      Icone = icCaixa
      Estilo = ebPrimario
    end
    object lblTitulo: TLabel
      Left = 84
      Top = 13
      Width = 133
      Height = 28
      Caption = 'Pedido de Venda'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblVersao: TLabel
      Left = 232
      Top = 19
      Width = 36
      Height = 17
      Caption = 'v1.1.0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12100500
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblSubtitulo: TLabel
      Left = 84
      Top = 42
      Width = 288
      Height = 17
      Caption = 'Informe o cliente, adicione os itens e grave o pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12100500
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblNumeroPedido: TLabel
      Left = 724
      Top = 26
      Width = 200
      Height = 24
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'Novo pedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16102026
      Font.Height = -15
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object btnBandeiraPt: TFlagButton
      Left = 944
      Top = 16
      Width = 44
      Height = 44
      Anchors = [akTop, akRight]
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Bandeira = bdBrasil
      Ativo = True
      OnClick = btnBandeiraPtClick
    end
    object btnBandeiraEs: TFlagButton
      Left = 996
      Top = 16
      Width = 44
      Height = 44
      Anchors = [akTop, akRight]
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Bandeira = bdEspanha
      OnClick = btnBandeiraEsClick
    end
    object btnSair: TRoundButton
      Left = 1052
      Top = 16
      Width = 44
      Height = 44
      Hint = 'Fechar o sistema (Alt+F4)'
      Anchors = [akTop, akRight]
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      SomenteIcone = True
      Icone = icSair
      Estilo = ebFantasma
      OnClick = btnSairClick
    end
  end
end
