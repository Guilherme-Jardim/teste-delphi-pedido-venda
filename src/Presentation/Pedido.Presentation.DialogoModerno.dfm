object frmDialogoModerno: TfrmDialogoModerno
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Pedido de Venda'
  ClientHeight = 232
  ClientWidth = 460
  Color = 16184563
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 2562065
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poMainFormCenter
  OnKeyDown = FormKeyDown
  TextHeight = 17
  object cardDialogo: TInfoCard
    Left = 16
    Top = 16
    Width = 428
    Height = 200
    Titulo = 'Aviso'
    Icone = icInfo
    object txtMensagem: TStaticText
      Left = 20
      Top = 56
      Width = 388
      Height = 24
      AutoSize = False
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2562065
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      ShowAccelChar = False
      TabOrder = 4
      Transparent = False
    end
    object btnOpcao1: TRoundButton
      Left = 20
      Top = 100
      Width = 388
      Height = 46
      Caption = 'OK'
      TabOrder = 0
      Icone = icCheck
      Estilo = ebPrimario
      OnClick = BotaoClick
    end
    object btnOpcao2: TRoundButton
      Left = 20
      Top = 156
      Width = 388
      Height = 46
      Caption = 'Cancelar'
      TabOrder = 1
      Visible = False
      Icone = icSair
      Estilo = ebSecundario
      OnClick = BotaoClick
    end
    object btnOpcao3: TRoundButton
      Left = 20
      Top = 212
      Width = 388
      Height = 46
      Caption = 'Opcao 3'
      TabOrder = 2
      Visible = False
      Estilo = ebSecundario
      OnClick = BotaoClick
    end
    object btnOpcao4: TRoundButton
      Left = 20
      Top = 268
      Width = 388
      Height = 46
      Caption = 'Opcao 4'
      TabOrder = 3
      Visible = False
      Estilo = ebSecundario
      OnClick = BotaoClick
    end
  end
end
