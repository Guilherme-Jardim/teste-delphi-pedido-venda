unit ComponentAccess;


{ Acessibilidade dos componentes desenhados à mão, para leitores de tela.
  Controles feitos em GDI+ aparecem como um "painel" sem nome, sem papel e sem
  foco. Cada componente responde ao WM_GETOBJECT de duas formas:
    - MSAA (IAccessible): usado por NVDA e JAWS. Repassa tudo ao objeto padrão do
      Windows e troca só nome, papel, estado e ação padrão.
    - UI Automation (IRawElementProviderSimple): usado pelo Narrator. Informa o
      tipo (botão, campo de texto, lista...), o nome, o valor e a ação de clicar. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  Winapi.UIAutomation,
  Winapi.oleacc, // depois do UIAutomation: os dois declaram IAccessible e vale o último
  System.Classes,
  System.SysUtils,
  System.Variants,
  Vcl.Controls;

const
  // Papéis (ROLE_SYSTEM_*)
  PAPEL_PADRAO = -1;
  PAPEL_ALERTA = $8;
  PAPEL_AGRUPAMENTO = $14;
  PAPEL_LISTA = $21;
  PAPEL_BOTAO = $2B;
  PAPEL_RADIO = $2D;

  // Estados (STATE_SYSTEM_*)
  ESTADO_INDISPONIVEL = $1;
  ESTADO_COM_FOCO = $4;
  ESTADO_MARCADO = $10;
  ESTADO_INVISIVEL = $8000;
  ESTADO_FOCAVEL = $100000;

type
  TDadosAcessiveis = record
    Nome: string;
    Descricao: string;
    Valor: string;
    // PAPEL_PADRAO mantém o papel do Windows (usado nos campos de texto reais).
    Papel: Integer;
    // Estados extras além dos calculados (habilitado, com foco, focável).
    Estado: Integer;
    // Campo de texto: no UI Automation vira "edit" com valor.
    Campo: Boolean;
    SomenteLeitura: Boolean;
    // Aviso que deve ser anunciado assim que aparece.
    Atento: Boolean;
  end;

  TObterDadosAcessiveis = reference to function: TDadosAcessiveis;
  TAcaoPadrao = reference to procedure;
  TDefinirValor = reference to procedure(const AValor: string);

// Monta um registro com valores neutros (só o nome é obrigatório).
function NovosDados(const ANome: string; APapel: Integer = PAPEL_PADRAO): TDadosAcessiveis;

// Responde ao WM_GETOBJECT. Devolve True se a mensagem foi tratada.
function ResponderGetObject(AControle: TWinControl; var Msg: TMessage;
  const ADados: TObterDadosAcessiveis; const AAcao: TAcaoPadrao = nil;
  const ADefinir: TDefinirValor = nil): Boolean;

const
  EVENTO_ALERTA = $2;
  EVENTO_NOME_MUDOU = $800C;
  EVENTO_VALOR_MUDOU = $800E;

// Avisa os leitores de tela que algo mudou (alerta, valor, nome...).
procedure AvisarMudanca(AControle: TWinControl; AEvento: DWORD);

implementation

const
  OBJID_CLIENTE = -4; // OBJID_CLIENT do Windows ($FFFFFFFC)
  OBJID_CLIENTE_SEM_SINAL: DWORD = $FFFFFFFC; // mesmo valor, para APIs que pedem DWORD
  OBJID_UIA_RAIZ = -25; // UiaRootObjectId ($FFFFFFE7)
  HR_ELEMENTO_INDISPONIVEL = -2147220991; // UIA_E_ELEMENTNOTAVAILABLE
  HR_NAO_SUPORTADO = -2147220988; // UIA_E_NOTSUPPORTED

type
  TLigadoAoControle = class;

  // Fica de olho no controle: se ele for destruído, o objeto de acessibilidade
  // para de usá-lo (um leitor de tela pode guardar a referência por um tempo).
  TObservadorControle = class(TComponent)
  private
    FDono: TLigadoAoControle;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  end;

  TLigadoAoControle = class(TInterfacedObject)
  protected
    FControle: TWinControl;
    FDados: TObterDadosAcessiveis;
    FAcao: TAcaoPadrao;
    FDefinir: TDefinirValor;
    FObservador: TObservadorControle;
    function Vivo: Boolean;
    function Dados: TDadosAcessiveis;
  public
    constructor Create(AControle: TWinControl; const ADados: TObterDadosAcessiveis;
      const AAcao: TAcaoPadrao; const ADefinir: TDefinirValor);
    destructor Destroy; override;
    procedure ControleDestruido;
  end;

  TAcessivelEnvolvido = class(TLigadoAoControle, IAccessible)
  private
    FBase: IAccessible;
    function EhPropria(const AFilho: OleVariant): Boolean;
    // IDispatch
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer;
      DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
      var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
    // IAccessible
    function Get_accParent(out ppdispParent: IDispatch): HResult; stdcall;
    function Get_accChildCount(out pcountChildren: Integer): HResult; stdcall;
    function Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult; stdcall;
    function Get_accName(varChild: OleVariant; out pszName: WideString): HResult; stdcall;
    function Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult; stdcall;
    function Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult; stdcall;
    function Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult; stdcall;
    function Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult; stdcall;
    function Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult; stdcall;
    function Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
      out pidTopic: Integer): HResult; stdcall;
    function Get_accKeyboardShortcut(varChild: OleVariant;
      out pszKeyboardShortcut: WideString): HResult; stdcall;
    function Get_accFocus(out pvarChild: OleVariant): HResult; stdcall;
    function Get_accSelection(out pvarChildren: OleVariant): HResult; stdcall;
    function Get_accDefaultAction(varChild: OleVariant; out pszDefaultAction: WideString): HResult; stdcall;
    function accSelect(flagsSelect: Integer; varChild: OleVariant): HResult; stdcall;
    function accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
      out pcyHeight: Integer; varChild: OleVariant): HResult; stdcall;
    function accNavigate(navDir: Integer; varStart: OleVariant; out pvarEndUpAt: OleVariant): HResult; stdcall;
    function accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult; stdcall;
    function accDoDefaultAction(varChild: OleVariant): HResult; stdcall;
    function Set_accName(varChild: OleVariant; const pszName: WideString): HResult; stdcall;
    function Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult; stdcall;
  public
    constructor Create(AControle: TWinControl; const ABase: IAccessible;
      const ADados: TObterDadosAcessiveis; const AAcao: TAcaoPadrao;
      const ADefinir: TDefinirValor);
  end;

  TProvedorUia = class(TLigadoAoControle, IRawElementProviderSimple, IInvokeProvider,
    IValueProvider)
  private
    function TipoDeControle(const D: TDadosAcessiveis): Integer;
    // IRawElementProviderSimple
    function get_ProviderOptions(out pRetVal: ProviderOptions): HRESULT; stdcall;
    function GetPatternProvider(patternId: UIA_PATTERN_ID; out pRetVal: IUnknown): HRESULT; stdcall;
    function GetPropertyValue(propertyId: UIA_PROPERTY_ID; out pRetVal: OleVariant): HRESULT; stdcall;
    function get_HostRawElementProvider(out pRetVal: IRawElementProviderSimple): HRESULT; stdcall;
    // IInvokeProvider
    function Invoke: HRESULT; stdcall;
    // IValueProvider
    function SetValue(val: PChar): HRESULT; stdcall;
    function get_Value(out pRetVal: PChar): HRESULT; stdcall;
    function get_IsReadOnly(out pRetVal: BOOL): HRESULT; stdcall;
  end;

function NovosDados(const ANome: string; APapel: Integer): TDadosAcessiveis;
begin
  Result := Default(TDadosAcessiveis);
  Result.Nome := ANome;
  Result.Papel := APapel;
end;

function ResponderGetObject(AControle: TWinControl; var Msg: TMessage;
  const ADados: TObterDadosAcessiveis; const AAcao: TAcaoPadrao;
  const ADefinir: TDefinirValor): Boolean;
var
  Ponteiro: Pointer;
  Base: IAccessible;
  Envolvido: IAccessible;
  Provedor: IRawElementProviderSimple;
begin
  Result := False;
  if not AControle.HandleAllocated then
    Exit;

  if Longint(Msg.LParam) = OBJID_UIA_RAIZ then
  begin
    Provedor := TProvedorUia.Create(AControle, ADados, AAcao, ADefinir);
    Msg.Result := UiaReturnRawElementProvider(AControle.Handle, Msg.WParam, Msg.LParam, Provedor);
    Exit(True);
  end;

  if Longint(Msg.LParam) <> OBJID_CLIENTE then
    Exit;
  Ponteiro := nil;
  if Failed(CreateStdAccessibleObject(AControle.Handle, OBJID_CLIENTE, IAccessible, Ponteiro))
    or (Ponteiro = nil) then
    Exit;
  Pointer(Base) := Ponteiro; // já vem com uma referência: não conta de novo
  Envolvido := TAcessivelEnvolvido.Create(AControle, Base, ADados, AAcao, ADefinir);
  Msg.Result := LresultFromObject(IAccessible, Msg.WParam, Envolvido);
  Result := True;
end;

procedure AvisarMudanca(AControle: TWinControl; AEvento: DWORD);
var
  Provedor: IRawElementProviderSimple;
begin
  if not AControle.HandleAllocated then
    Exit;
  NotifyWinEvent(AEvento, AControle.Handle, OBJID_CLIENTE_SEM_SINAL, CHILDID_SELF);

  // UI Automation (Narrator): o provedor só precisa apontar para a janela.
  if not UiaClientsAreListening then
    Exit;
  Provedor := TProvedorUia.Create(AControle,
    function: TDadosAcessiveis
    begin
      Result := NovosDados('');
    end, nil, nil);
  if AEvento = EVENTO_ALERTA then
    UiaRaiseAutomationEvent(Provedor, UIA_LiveRegionChangedEventId)
  else if (AEvento = EVENTO_VALOR_MUDOU) and AControle.Focused then
    UiaRaiseAutomationEvent(Provedor, UIA_AutomationFocusChangedEventId);
end;

{ TObservadorControle }

procedure TObservadorControle.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (FDono <> nil) and (AComponent = FDono.FControle) then
    FDono.ControleDestruido;
end;

{ TLigadoAoControle }

constructor TLigadoAoControle.Create(AControle: TWinControl; const ADados: TObterDadosAcessiveis;
  const AAcao: TAcaoPadrao; const ADefinir: TDefinirValor);
begin
  inherited Create;
  FControle := AControle;
  FDados := ADados;
  FAcao := AAcao;
  FDefinir := ADefinir;
  FObservador := TObservadorControle.Create(nil);
  FObservador.FDono := Self;
  AControle.FreeNotification(FObservador);
end;

destructor TLigadoAoControle.Destroy;
begin
  if FControle <> nil then
    FControle.RemoveFreeNotification(FObservador);
  FObservador.FDono := nil;
  FObservador.Free;
  inherited;
end;

procedure TLigadoAoControle.ControleDestruido;
begin
  FControle := nil;
  FDados := nil;
  FAcao := nil;
  FDefinir := nil;
end;

function TLigadoAoControle.Vivo: Boolean;
begin
  Result := (FControle <> nil) and Assigned(FDados);
end;

function TLigadoAoControle.Dados: TDadosAcessiveis;
begin
  Result := FDados();
end;

{ TProvedorUia }

function TProvedorUia.TipoDeControle(const D: TDadosAcessiveis): Integer;
begin
  if D.Campo then
    Exit(UIA_EditControlTypeId);
  case D.Papel of
    PAPEL_BOTAO, PAPEL_RADIO: Result := UIA_ButtonControlTypeId;
    PAPEL_LISTA: Result := UIA_ListControlTypeId;
    PAPEL_AGRUPAMENTO: Result := UIA_GroupControlTypeId;
    PAPEL_ALERTA: Result := UIA_TextControlTypeId;
  else
    Result := UIA_CustomControlTypeId;
  end;
end;

function TProvedorUia.get_ProviderOptions(out pRetVal: ProviderOptions): HRESULT;
begin
  pRetVal := ProviderOptions_ServerSideProvider or ProviderOptions_UseComThreading;
  Result := S_OK;
end;

function TProvedorUia.get_HostRawElementProvider(out pRetVal: IRawElementProviderSimple): HRESULT;
begin
  if Vivo and FControle.HandleAllocated then
    Result := UiaHostProviderFromHwnd(FControle.Handle, pRetVal)
  else
  begin
    pRetVal := nil;
    Result := S_OK;
  end;
end;

function TProvedorUia.GetPatternProvider(patternId: UIA_PATTERN_ID; out pRetVal: IUnknown): HRESULT;
var
  D: TDadosAcessiveis;
begin
  pRetVal := nil;
  if Vivo then
  begin
    D := Dados;
    if (patternId = UIA_InvokePatternId) and Assigned(FAcao)
      and (D.Papel in [PAPEL_BOTAO, PAPEL_RADIO]) then
      pRetVal := Self as IInvokeProvider
    else if (patternId = UIA_ValuePatternId) and D.Campo then
      pRetVal := Self as IValueProvider;
  end;
  Result := S_OK;
end;

function TProvedorUia.GetPropertyValue(propertyId: UIA_PROPERTY_ID; out pRetVal: OleVariant): HRESULT;
var
  D: TDadosAcessiveis;
  Nome: string;
begin
  pRetVal := Unassigned; // "não sei": o Windows usa o valor padrão dele
  Result := S_OK;
  if not Vivo then
    Exit;
  D := Dados;
  case propertyId of
    UIA_ControlTypePropertyId:
      pRetVal := TipoDeControle(D);
    UIA_NamePropertyId:
      begin
        Nome := D.Nome;
        // Na lista, o nome já leva a linha atual (a lista não expõe os itens um a um).
        if (D.Papel = PAPEL_LISTA) and (D.Valor <> '') then
          Nome := Nome + ': ' + D.Valor;
        pRetVal := Nome;
      end;
    UIA_HelpTextPropertyId:
      if D.Descricao <> '' then
        pRetVal := D.Descricao;
    UIA_IsEnabledPropertyId:
      pRetVal := FControle.Enabled;
    UIA_IsKeyboardFocusablePropertyId:
      pRetVal := FControle.Enabled and (FControle.TabStop or D.Campo);
    UIA_HasKeyboardFocusPropertyId:
      pRetVal := FControle.Focused;
    UIA_IsPasswordPropertyId:
      pRetVal := False;
    UIA_LiveSettingPropertyId:
      if D.Atento then
        pRetVal := 2; // Assertive: anuncia na hora
  end;
end;

function TProvedorUia.Invoke: HRESULT;
begin
  Result := HR_ELEMENTO_INDISPONIVEL;
  if Vivo and Assigned(FAcao) and FControle.Enabled then
  begin
    FAcao();
    Result := S_OK;
  end;
end;

function TProvedorUia.SetValue(val: PChar): HRESULT;
begin
  Result := HR_ELEMENTO_INDISPONIVEL;
  if not Vivo then
    Exit;
  if Dados.SomenteLeitura or not Assigned(FDefinir) then
    Exit(HR_NAO_SUPORTADO);
  FDefinir(string(val));
  Result := S_OK;
end;

function TProvedorUia.get_Value(out pRetVal: PChar): HRESULT;
begin
  pRetVal := nil;
  if not Vivo then
    Exit(HR_ELEMENTO_INDISPONIVEL);
  pRetVal := PChar(SysAllocString(PChar(Dados.Valor)));
  Result := S_OK;
end;

function TProvedorUia.get_IsReadOnly(out pRetVal: BOOL): HRESULT;
begin
  pRetVal := not Vivo or Dados.SomenteLeitura or not Assigned(FDefinir);
  Result := S_OK;
end;

{ TAcessivelEnvolvido }

constructor TAcessivelEnvolvido.Create(AControle: TWinControl; const ABase: IAccessible;
  const ADados: TObterDadosAcessiveis; const AAcao: TAcaoPadrao; const ADefinir: TDefinirValor);
begin
  inherited Create(AControle, ADados, AAcao, ADefinir);
  FBase := ABase;
end;

function TAcessivelEnvolvido.EhPropria(const AFilho: OleVariant): Boolean;
begin
  Result := VarIsOrdinal(AFilho) and (Integer(AFilho) = CHILDID_SELF);
end;

// ---- IDispatch: repassa ao objeto padrão

function TAcessivelEnvolvido.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := (FBase as IDispatch).GetTypeInfoCount(Count);
end;

function TAcessivelEnvolvido.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := (FBase as IDispatch).GetTypeInfo(Index, LocaleID, TypeInfo);
end;

function TAcessivelEnvolvido.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount,
  LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := (FBase as IDispatch).GetIDsOfNames(IID, Names, NameCount, LocaleID, DispIDs);
end;

function TAcessivelEnvolvido.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := (FBase as IDispatch).Invoke(DispID, IID, LocaleID, Flags, Params, VarResult,
    ExcepInfo, ArgErr);
end;

// ---- IAccessible

function TAcessivelEnvolvido.Get_accParent(out ppdispParent: IDispatch): HResult;
begin
  Result := FBase.Get_accParent(ppdispParent);
end;

function TAcessivelEnvolvido.Get_accChildCount(out pcountChildren: Integer): HResult;
begin
  Result := FBase.Get_accChildCount(pcountChildren);
end;

function TAcessivelEnvolvido.Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult;
begin
  Result := FBase.Get_accChild(varChild, ppdispChild);
end;

function TAcessivelEnvolvido.Get_accName(varChild: OleVariant; out pszName: WideString): HResult;
begin
  if Vivo and EhPropria(varChild) and (Dados.Nome <> '') then
  begin
    pszName := Dados.Nome;
    Result := S_OK;
  end
  else
    Result := FBase.Get_accName(varChild, pszName);
end;

function TAcessivelEnvolvido.Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult;
begin
  if Vivo and EhPropria(varChild) and (Dados.Valor <> '') then
  begin
    pszValue := Dados.Valor;
    Result := S_OK;
  end
  else
    Result := FBase.Get_accValue(varChild, pszValue);
end;

function TAcessivelEnvolvido.Get_accDescription(varChild: OleVariant;
  out pszDescription: WideString): HResult;
begin
  if Vivo and EhPropria(varChild) and (Dados.Descricao <> '') then
  begin
    pszDescription := Dados.Descricao;
    Result := S_OK;
  end
  else
    Result := FBase.Get_accDescription(varChild, pszDescription);
end;

function TAcessivelEnvolvido.Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult;
begin
  if Vivo and EhPropria(varChild) and (Dados.Papel >= 0) then
  begin
    pvarRole := Dados.Papel;
    Result := S_OK;
  end
  else
    Result := FBase.Get_accRole(varChild, pvarRole);
end;

function TAcessivelEnvolvido.Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult;
var
  D: TDadosAcessiveis;
  Estado: Integer;
begin
  Result := FBase.Get_accState(varChild, pvarState);
  if not (Vivo and EhPropria(varChild)) then
    Exit;
  D := Dados;
  if D.Papel < 0 then
    Exit; // campo de texto real: o estado do Windows já está certo
  Estado := 0;
  if Succeeded(Result) and VarIsOrdinal(pvarState) then
    Estado := Integer(pvarState);
  Estado := Estado or D.Estado;
  if not FControle.Enabled then
    Estado := Estado or ESTADO_INDISPONIVEL
  else if FControle.TabStop then
    Estado := Estado or ESTADO_FOCAVEL;
  if FControle.Focused then
    Estado := Estado or ESTADO_COM_FOCO;
  if not FControle.Visible then
    Estado := Estado or ESTADO_INVISIVEL;
  pvarState := Estado;
  Result := S_OK;
end;

function TAcessivelEnvolvido.Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult;
begin
  Result := FBase.Get_accHelp(varChild, pszHelp);
end;

function TAcessivelEnvolvido.Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
  out pidTopic: Integer): HResult;
begin
  Result := FBase.Get_accHelpTopic(pszHelpFile, varChild, pidTopic);
end;

function TAcessivelEnvolvido.Get_accKeyboardShortcut(varChild: OleVariant;
  out pszKeyboardShortcut: WideString): HResult;
begin
  Result := FBase.Get_accKeyboardShortcut(varChild, pszKeyboardShortcut);
end;

function TAcessivelEnvolvido.Get_accFocus(out pvarChild: OleVariant): HResult;
begin
  Result := FBase.Get_accFocus(pvarChild);
end;

function TAcessivelEnvolvido.Get_accSelection(out pvarChildren: OleVariant): HResult;
begin
  Result := FBase.Get_accSelection(pvarChildren);
end;

function TAcessivelEnvolvido.Get_accDefaultAction(varChild: OleVariant;
  out pszDefaultAction: WideString): HResult;
begin
  Result := FBase.Get_accDefaultAction(varChild, pszDefaultAction);
end;

function TAcessivelEnvolvido.accSelect(flagsSelect: Integer; varChild: OleVariant): HResult;
begin
  Result := FBase.accSelect(flagsSelect, varChild);
end;

function TAcessivelEnvolvido.accLocation(out pxLeft, pyTop, pcxWidth, pcyHeight: Integer;
  varChild: OleVariant): HResult;
begin
  Result := FBase.accLocation(pxLeft, pyTop, pcxWidth, pcyHeight, varChild);
end;

function TAcessivelEnvolvido.accNavigate(navDir: Integer; varStart: OleVariant;
  out pvarEndUpAt: OleVariant): HResult;
begin
  Result := FBase.accNavigate(navDir, varStart, pvarEndUpAt);
end;

function TAcessivelEnvolvido.accHitTest(xLeft, yTop: Integer; out pvarChild: OleVariant): HResult;
begin
  Result := FBase.accHitTest(xLeft, yTop, pvarChild);
end;

function TAcessivelEnvolvido.accDoDefaultAction(varChild: OleVariant): HResult;
begin
  if Vivo and EhPropria(varChild) and Assigned(FAcao) then
  begin
    FAcao();
    Result := S_OK;
  end
  else
    Result := FBase.accDoDefaultAction(varChild);
end;

function TAcessivelEnvolvido.Set_accName(varChild: OleVariant; const pszName: WideString): HResult;
begin
  Result := FBase.Set_accName(varChild, pszName);
end;

function TAcessivelEnvolvido.Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult;
begin
  Result := FBase.Set_accValue(varChild, pszValue);
end;

end.
