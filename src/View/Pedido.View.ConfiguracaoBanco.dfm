object frmConfiguracaoBanco: TfrmConfiguracaoBanco
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Configurar a conex'#227'o'
  ClientHeight = 560
  ClientWidth = 640
  Color = 16184563
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 2562065
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 17
  object lblTitulo: TLabel
    Left = 28
    Top = 20
    Width = 180
    Height = 25
    Caption = 'Vamos configurar a conex'#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 2562065
    Font.Height = -19
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object lblAjuda: TLabel
    Left = 28
    Top = 54
    Width = 584
    Height = 40
    AutoSize = False
    Caption = 'Confira os dados de conex'#227'o com o Firebird.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 6509899
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object avisoMensagem: TAlertBar
    Left = 28
    Top = 100
    Width = 584
    Height = 38
  end
  object edtServidor: TModernEdit
    Left = 28
    Top = 148
    Width = 400
    Height = 60
    Rotulo = 'Servidor'
    TabOrder = 0
  end
  object edtPorta: TModernEdit
    Left = 444
    Top = 148
    Width = 168
    Height = 60
    Edit.MaxLength = 5
    Edit.NumbersOnly = True
    Rotulo = 'Porta'
    TabOrder = 1
  end
  object edtBanco: TModernEdit
    Left = 28
    Top = 220
    Width = 436
    Height = 60
    Edit.MaxLength = 255
    Icone = icPasta
    Rotulo = 'Arquivo do banco de dados (.fdb)'
    TabOrder = 2
  end
  object btnEscolherPasta: TRoundButton
    Left = 476
    Top = 242
    Width = 40
    Height = 40
    ParentShowHint = False
    ShowHint = True
    SomenteIcone = True
    TabOrder = 10
    Icone = icPasta
    Estilo = ebSecundario
    OnClick = btnEscolherPastaClick
  end
  object btnPastaPrograma: TRoundButton
    Left = 524
    Top = 242
    Width = 40
    Height = 40
    ParentShowHint = False
    ShowHint = True
    SomenteIcone = True
    TabOrder = 11
    Icone = icCaixa
    Estilo = ebSecundario
    OnClick = btnPastaProgramaClick
  end
  object btnPastaPadrao: TRoundButton
    Left = 572
    Top = 242
    Width = 40
    Height = 40
    ParentShowHint = False
    ShowHint = True
    SomenteIcone = True
    TabOrder = 12
    Icone = icNovo
    Estilo = ebSecundario
    OnClick = btnPastaPadraoClick
  end
  object edtUsuario: TModernEdit
    Left = 28
    Top = 292
    Width = 280
    Height = 60
    Edit.MaxLength = 31
    Icone = icUsuario
    Rotulo = 'Usu'#225'rio'
    TabOrder = 3
  end
  object edtSenha: TModernEdit
    Left = 324
    Top = 292
    Width = 288
    Height = 60
    Edit.MaxLength = 64
    Edit.PasswordChar = '*'
    Icone = icCadeado
    Rotulo = 'Senha'
    TabOrder = 4
  end
  object edtBiblioteca: TModernEdit
    Left = 28
    Top = 364
    Width = 584
    Height = 60
    Edit.MaxLength = 255
    Icone = icCaixa
    Rotulo = 'Biblioteca do cliente (fbclient.dll)'
    TabOrder = 5
  end
  object btnSugestoes: TRoundButton
    Left = 28
    Top = 480
    Width = 190
    Height = 46
    Caption = 'Usar sugest'#245'es'
    TabOrder = 6
    Icone = icBusca
    Estilo = ebSecundario
    OnClick = btnSugestoesClick
  end
  object btnCancelar: TRoundButton
    Left = 258
    Top = 480
    Width = 150
    Height = 46
    Caption = 'Cancelar'
    TabOrder = 7
    Icone = icSair
    Estilo = ebSecundario
    OnClick = btnCancelarClick
  end
  object btnSalvar: TRoundButton
    Left = 424
    Top = 480
    Width = 188
    Height = 46
    Caption = 'Salvar e continuar'
    TabOrder = 8
    Icone = icSalvar
    Estilo = ebPrimario
    OnClick = btnSalvarClick
  end
end
