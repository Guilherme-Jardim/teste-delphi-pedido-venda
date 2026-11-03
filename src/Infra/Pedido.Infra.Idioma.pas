unit Pedido.Infra.Idioma;

{ Textos do sistema em português do Brasil (idioma padrão) e espanhol.
  Todo texto que a pessoa lê passa por Tr(); a escolha fica salva em
  %LOCALAPPDATA%\PedidoVenda\idioma.cfg e vale na próxima abertura. }

interface

type
  TIdioma = (idEspanhol, idPortugues);

function IdiomaPadrao: TIdioma;
function IdiomaAtual: TIdioma;
procedure DefinirIdioma(AIdioma: TIdioma; ASalvar: Boolean = True);
procedure CarregarIdiomaSalvo;

// Devolve o texto da chave no idioma atual (se a chave não existir, a própria chave).
function Tr(const AChave: string): string; overload;
function Tr(const AChave: string; const AArgs: array of const): string; overload;

implementation

uses
  System.SysUtils,
  System.IOUtils;

type
  TTexto = record
    Chave: string;
    Es: string;
    Pt: string;
  end;

const
  TEXTOS: array[0..86] of TTexto = (
    // Tela principal
    (Chave: 'app.titulo'; Es: 'Pedido de Venta'; Pt: 'Pedido de Venda'),
    (Chave: 'app.subtitulo'; Es: 'Indica el cliente, agrega los ítems y guarda el pedido';
      Pt: 'Informe o cliente, adicione os itens e grave o pedido'),
    (Chave: 'pedido.novo'; Es: 'Pedido nuevo'; Pt: 'Novo pedido'),
    (Chave: 'pedido.numero'; Es: 'Pedido n.º %d'; Pt: 'Pedido nº %d'),
    (Chave: 'cliente.titulo'; Es: 'Cliente'; Pt: 'Cliente'),
    (Chave: 'item.titulo'; Es: 'Ítem'; Pt: 'Item'),
    (Chave: 'campo.codigo'; Es: 'Código'; Pt: 'Código'),
    (Chave: 'campo.nome'; Es: 'Nombre'; Pt: 'Nome'),
    (Chave: 'campo.cidade'; Es: 'Ciudad'; Pt: 'Cidade'),
    (Chave: 'campo.uf'; Es: 'Estado (UF)'; Pt: 'UF'),
    (Chave: 'campo.obs'; Es: 'Observación'; Pt: 'Observação'),
    (Chave: 'campo.descricao'; Es: 'Descripción'; Pt: 'Descrição'),
    (Chave: 'campo.quantidade'; Es: 'Cantidad'; Pt: 'Quantidade'),
    (Chave: 'campo.vlrunit'; Es: 'Valor unitario'; Pt: 'Valor unitário'),
    (Chave: 'item.inserir'; Es: 'Agregar ítem'; Pt: 'Inserir item'),
    (Chave: 'item.atualizar'; Es: 'Actualizar ítem'; Pt: 'Atualizar item'),
    (Chave: 'grade.titulo'; Es: 'Ítems del pedido'; Pt: 'Itens do pedido'),
    (Chave: 'grade.codigo'; Es: 'Cód. producto'; Pt: 'Cód. produto'),
    (Chave: 'grade.descricao'; Es: 'Descripción'; Pt: 'Descrição'),
    (Chave: 'grade.quantidade'; Es: 'Cantidad'; Pt: 'Quantidade'),
    (Chave: 'grade.unitario'; Es: 'Valor unit.'; Pt: 'Vlr. unitário'),
    (Chave: 'grade.total'; Es: 'Valor total'; Pt: 'Vlr. total'),
    (Chave: 'total.rotulo'; Es: 'Total del pedido'; Pt: 'Valor total do pedido'),
    (Chave: 'btn.novo'; Es: 'Nuevo'; Pt: 'Novo'),
    (Chave: 'btn.carregar'; Es: 'Cargar pedido'; Pt: 'Carregar pedido'),
    (Chave: 'btn.cancelar'; Es: 'Cancelar pedido'; Pt: 'Cancelar pedido'),
    (Chave: 'btn.gravar'; Es: 'Guardar pedido'; Pt: 'Gravar pedido'),

    // Dicas (hints) e nomes para leitores de tela
    (Chave: 'hint.sair'; Es: 'Cerrar el sistema (Alt+F4)'; Pt: 'Fechar o sistema (Alt+F4)'),
    (Chave: 'hint.novo'; Es: 'Empezar un pedido nuevo (Ctrl+N)'; Pt: 'Começar um pedido novo (Ctrl+N)'),
    (Chave: 'hint.carregar'; Es: 'Abrir un pedido ya guardado (Ctrl+L)';
      Pt: 'Abrir um pedido já gravado (Ctrl+L)'),
    (Chave: 'hint.cancelar'; Es: 'Eliminar un pedido guardado con todos sus ítems (Ctrl+D)';
      Pt: 'Excluir um pedido gravado com todos os itens (Ctrl+D)'),
    (Chave: 'hint.gravar'; Es: 'Guardar el pedido en la base de datos (Ctrl+G)';
      Pt: 'Gravar o pedido no banco de dados (Ctrl+G)'),
    (Chave: 'hint.inserir'; Es: 'Agregar o actualizar el ítem en el pedido (Ctrl+Enter)';
      Pt: 'Adicionar ou atualizar o item no pedido (Ctrl+Enter)'),
    (Chave: 'hint.editar'; Es: 'Editar el ítem seleccionado (Enter en la grilla)';
      Pt: 'Editar o item selecionado (Enter na grade)'),
    (Chave: 'hint.excluir'; Es: 'Eliminar el ítem seleccionado (Supr en la grilla)';
      Pt: 'Excluir o item selecionado (Delete na grade)'),
    (Chave: 'hint.cod_cliente'; Es: 'Escribe el código del cliente y presiona Enter';
      Pt: 'Digite o código do cliente e tecle Enter'),
    (Chave: 'hint.cod_produto'; Es: 'Escribe el código del producto y presiona Enter';
      Pt: 'Digite o código do produto e tecle Enter'),
    (Chave: 'hint.quantidade'; Es: 'Cantidad del ítem (acepta decimales)';
      Pt: 'Quantidade do item (aceita decimais)'),
    (Chave: 'hint.vlrunit'; Es: 'Precio de venta sugerido; puedes cambiarlo';
      Pt: 'Preço de venda sugerido; você pode alterar'),
    (Chave: 'hint.obs'; Es: 'Opcional: un comentario corto sobre el pedido (máx. 200 caracteres)';
      Pt: 'Opcional: um comentário curto sobre o pedido (máx. 200 caracteres)'),
    (Chave: 'hint.nome'; Es: 'Se completa solo al indicar el código del cliente';
      Pt: 'Preenchido sozinho ao informar o código do cliente'),
    (Chave: 'hint.descricao'; Es: 'Se completa solo al indicar el código del producto';
      Pt: 'Preenchida sozinha ao informar o código do produto'),
    (Chave: 'hint.grade'; Es: 'Ítems del pedido. Enter edita, Supr elimina';
      Pt: 'Itens do pedido. Enter edita, Delete exclui'),
    (Chave: 'idioma.es'; Es: 'Español'; Pt: 'Español'),
    (Chave: 'idioma.pt'; Es: 'Português (Brasil)'; Pt: 'Português (Brasil)'),
    (Chave: 'idioma.trocar_es'; Es: 'Usar el sistema en español'; Pt: 'Usar o sistema em espanhol'),
    (Chave: 'idioma.trocar_pt'; Es: 'Usar el sistema en portugués'; Pt: 'Usar o sistema em português'),

    // Avisos na tela
    (Chave: 'msg.cliente_invalido'; Es: 'Ese código de cliente no es válido.';
      Pt: 'Esse código de cliente não é válido.'),
    (Chave: 'msg.cliente_nao_encontrado'; Es: 'No encontramos al cliente %d. Revisa el código.';
      Pt: 'Não encontramos o cliente %d. Confira o código.'),
    (Chave: 'msg.produto_invalido'; Es: 'Ese código de producto no es válido.';
      Pt: 'Esse código de produto não é válido.'),
    (Chave: 'msg.produto_nao_encontrado'; Es: 'No encontramos el producto %d. Revisa el código.';
      Pt: 'Não encontramos o produto %d. Confira o código.'),
    (Chave: 'msg.pedido_nao_encontrado'; Es: 'No encontramos el pedido %d.';
      Pt: 'Não encontramos o pedido %d.'),
    (Chave: 'msg.informe_produto'; Es: 'Indica el código del producto.';
      Pt: 'Informe o código do produto.'),
    (Chave: 'msg.informe_quantidade'; Es: 'La cantidad debe ser mayor que cero.';
      Pt: 'A quantidade precisa ser maior que zero.'),
    (Chave: 'msg.informe_valor'; Es: 'Revisa el valor unitario: tiene que ser un número válido.';
      Pt: 'Confira o valor unitário: precisa ser um número válido.'),
    (Chave: 'msg.selecione_item'; Es: 'Selecciona un ítem de la grilla.';
      Pt: 'Selecione um item da grade.'),
    (Chave: 'msg.numero_invalido'; Es: 'Ese número de pedido no es válido.';
      Pt: 'Esse número de pedido não é válido.'),
    (Chave: 'msg.confirmar_excluir_item'; Es: '¿Eliminar el ítem "%s" del pedido?';
      Pt: 'Excluir o item "%s" do pedido?'),
    (Chave: 'msg.confirmar_cancelar'; Es: '¿Cancelar el pedido %d? También se eliminarán sus ítems.';
      Pt: 'Cancelar o pedido %d? Os itens dele também serão excluídos.'),
    (Chave: 'msg.cancelado'; Es: 'Pedido %d cancelado.'; Pt: 'Pedido %d cancelado.'),
    (Chave: 'msg.gravado'; Es: '¡Pedido %d guardado con éxito!'; Pt: 'Pedido %d gravado com sucesso!'),
    (Chave: 'msg.sem_cliente'; Es: 'Primero indica el cliente del pedido.';
      Pt: 'Primeiro informe o cliente do pedido.'),
    (Chave: 'msg.sem_itens'; Es: 'Agrega al menos un ítem al pedido.';
      Pt: 'Adicione pelo menos um item ao pedido.'),
    (Chave: 'msg.qtd_maior_zero'; Es: 'La cantidad debe ser mayor que cero.';
      Pt: 'A quantidade precisa ser maior que zero.'),
    (Chave: 'msg.qtd_limite'; Es: 'La cantidad es demasiado grande (máximo 99.999,999).';
      Pt: 'A quantidade é grande demais (máximo 99.999,999).'),
    (Chave: 'msg.vlr_negativo'; Es: 'El valor unitario no puede ser negativo.';
      Pt: 'O valor unitário não pode ser negativo.'),
    (Chave: 'msg.vlr_limite'; Es: 'El valor unitario es demasiado grande (máximo 9.999.999,99).';
      Pt: 'O valor unitário é grande demais (máximo 9.999.999,99).'),
    (Chave: 'msg.produto_codigo'; Es: 'Indica el código del producto.'; Pt: 'Informe o código do produto.'),
    (Chave: 'msg.falha_gravar'; Es: 'No pudimos guardar el pedido. Tus datos siguen en pantalla; inténtalo de nuevo.';
      Pt: 'Não conseguimos gravar o pedido. Seus dados continuam na tela; tente de novo.'),
    (Chave: 'msg.falha_cancelar'; Es: 'No pudimos cancelar el pedido. Inténtalo de nuevo en un momento.';
      Pt: 'Não conseguimos cancelar o pedido. Tente de novo em instantes.'),
    (Chave: 'msg.falha_consulta'; Es: 'No pudimos consultar la base de datos. Revisa la conexión e inténtalo de nuevo.';
      Pt: 'Não conseguimos consultar o banco de dados. Confira a conexão e tente de novo.'),
    (Chave: 'msg.erro_inesperado'; Es: 'Algo salió mal. Inténtalo otra vez y, si sigue pasando, avisa a soporte.';
      Pt: 'Algo deu errado. Tente de novo e, se continuar, avise o suporte.'),

    // Diálogos
    (Chave: 'dlg.sim'; Es: 'Sí'; Pt: 'Sim'),
    (Chave: 'dlg.nao'; Es: 'No'; Pt: 'Não'),
    (Chave: 'dlg.ok'; Es: 'Aceptar'; Pt: 'OK'),
    (Chave: 'dlg.cancelar'; Es: 'Cancelar'; Pt: 'Cancelar'),
    (Chave: 'dlg.numero_pergunta'; Es: 'Número del pedido'; Pt: 'Número do pedido'),
    (Chave: 'dlg.numero_carregar'; Es: 'Cargar pedido'; Pt: 'Carregar pedido'),
    (Chave: 'dlg.numero_cancelar'; Es: 'Cancelar pedido'; Pt: 'Cancelar pedido'),
    (Chave: 'dlg.numero_ajuda'; Es: 'Escribe el número y presiona Enter';
      Pt: 'Digite o número e tecle Enter'),

    // Inicialização e configuração
    (Chave: 'app.falha_iniciar'; Es: 'No pudimos iniciar la aplicación:'; Pt: 'Não conseguimos iniciar a aplicação:'),
    (Chave: 'cfg.nao_encontrado';
      Es: 'No encontramos el archivo config.ini. Copia config.ini.example como config.ini en la raíz del proyecto y ajusta los datos.';
      Pt: 'Não encontramos o arquivo config.ini. Copie o config.ini.example como config.ini na raiz do projeto e ajuste os dados.'),
    (Chave: 'cfg.sem_database'; Es: 'Falta el campo Database en config.ini.'; Pt: 'Falta o campo Database no config.ini.'),
    (Chave: 'cfg.sem_username'; Es: 'Falta el campo Username en config.ini.'; Pt: 'Falta o campo Username no config.ini.'),
    (Chave: 'cfg.sem_fbclient'; Es: 'Falta el campo ClientLibrary (fbclient.dll) en config.ini.';
      Pt: 'Falta o campo ClientLibrary (fbclient.dll) no config.ini.'),
    (Chave: 'cfg.fbclient_inexistente'; Es: 'No encontramos fbclient.dll en: %s';
      Pt: 'Não encontramos o fbclient.dll em: %s'),
    (Chave: 'cfg.porta_invalida'; Es: 'La Port del config.ini debe estar entre 1 y 65535.';
      Pt: 'A Port do config.ini precisa estar entre 1 e 65535.')
  );

var
  GIdioma: TIdioma = idPortugues;

function ArquivoIdioma: string;
begin
  Result := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'PedidoVenda'), 'idioma.cfg');
end;

function IdiomaPadrao: TIdioma;
begin
  Result := idPortugues;
end;

function IdiomaAtual: TIdioma;
begin
  Result := GIdioma;
end;

procedure DefinirIdioma(AIdioma: TIdioma; ASalvar: Boolean);
begin
  GIdioma := AIdioma;
  if not ASalvar then
    Exit;
  try
    TDirectory.CreateDirectory(TPath.GetDirectoryName(ArquivoIdioma));
    if AIdioma = idPortugues then
      TFile.WriteAllText(ArquivoIdioma, 'pt')
    else
      TFile.WriteAllText(ArquivoIdioma, 'es');
  except
    // Sem permissão de escrita? Tudo bem: o sistema só não lembra a escolha.
  end;
end;

procedure CarregarIdiomaSalvo;
begin
  GIdioma := IdiomaPadrao;
  try
    if TFile.Exists(ArquivoIdioma) and SameText(Trim(TFile.ReadAllText(ArquivoIdioma)), 'es') then
      GIdioma := idEspanhol;
  except
    GIdioma := IdiomaPadrao;
  end;
end;

function Tr(const AChave: string): string;
var
  I: Integer;
begin
  for I := Low(TEXTOS) to High(TEXTOS) do
    if TEXTOS[I].Chave = AChave then
    begin
      if GIdioma = idPortugues then
        Result := TEXTOS[I].Pt
      else
        Result := TEXTOS[I].Es;
      Exit;
    end;
  Result := AChave;
end;

function Tr(const AChave: string; const AArgs: array of const): string;
begin
  Result := Format(Tr(AChave), AArgs);
end;

end.
