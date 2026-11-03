object frmNumeroPedido: TfrmNumeroPedido
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Carregar pedido'
  ClientHeight = 250
  ClientWidth = 420
  Color = 16184563
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 2562065
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 17
  object lblTitulo: TLabel
    Left = 24
    Top = 20
    Width = 91
    Height = 25
    Caption = 'Carregar pedido'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 2562065
    Font.Height = -19
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object lblAjuda: TLabel
    Left = 24
    Top = 52
    Width = 260
    Height = 17
    Caption = 'Digite o n'#250'mero e tecle Enter'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 6509899
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object edtNumero: TModernEdit
    Left = 24
    Top = 88
    Width = 372
    Height = 60
    Edit.MaxLength = 9
    Edit.NumbersOnly = True
    Rotulo = 'N'#250'mero do pedido'
    Icone = icBusca
    OnConfirmar = edtNumeroConfirmar
    TabOrder = 0
  end
  object btnConfirmar: TRoundButton
    Left = 196
    Top = 176
    Width = 200
    Height = 46
    Caption = 'OK'
    TabOrder = 1
    Icone = icCheck
    Estilo = ebPrimario
    OnClick = btnConfirmarClick
  end
  object btnCancelar: TRoundButton
    Left = 24
    Top = 176
    Width = 160
    Height = 46
    Caption = 'Cancelar'
    TabOrder = 2
    Icone = icSair
    Estilo = ebSecundario
    OnClick = btnCancelarClick
  end
end
