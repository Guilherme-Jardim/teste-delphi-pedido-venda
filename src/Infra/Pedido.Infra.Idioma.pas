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
  TEXTOS: array[0..148] of TTexto = (
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
      Pt: 'A Port do config.ini precisa estar entre 1 e 65535.'),

    // Validação, configuração e inicialização
    (Chave: 'val.servidor_longo'; Es: 'El nombre del servidor es demasiado largo.';
      Pt: 'O nome do servidor é longo demais.'),
    (Chave: 'val.servidor_invalido'; Es: 'El servidor solo puede tener letras, números, punto, guion y dos puntos.';
      Pt: 'O servidor só pode ter letras, números, ponto, hífen e dois-pontos.'),
    (Chave: 'val.porta_invalida'; Es: 'La puerta debe ser un número entre 1 y 65535.';
      Pt: 'A porta precisa ser um número entre 1 e 65535.'),
    (Chave: 'val.banco_vazio'; Es: 'Indica la ruta del archivo de la base de datos.';
      Pt: 'Informe o caminho do arquivo do banco de dados.'),
    (Chave: 'val.banco_longo'; Es: 'La ruta de la base de datos es demasiado larga.';
      Pt: 'O caminho do banco de dados é longo demais.'),
    (Chave: 'val.banco_caracteres'; Es: 'La ruta de la base de datos tiene caracteres no permitidos (comillas, ; < > | * ? % o ..).';
      Pt: 'O caminho do banco de dados tem caracteres não permitidos (aspas, ; < > | * ? % ou ..).'),
    (Chave: 'val.banco_extensao'; Es: 'El archivo de la base de datos debe terminar en .fdb, .gdb o .fb.';
      Pt: 'O arquivo do banco de dados precisa terminar em .fdb, .gdb ou .fb.'),
    (Chave: 'val.usuario_invalido'; Es: 'El usuario debe tener hasta 31 caracteres (letras, números, _ $ . -).';
      Pt: 'O usuário precisa ter até 31 caracteres (letras, números, _ $ . -).'),
    (Chave: 'val.senha_invalida'; Es: 'La contraseña es demasiado larga o tiene caracteres de control.';
      Pt: 'A senha é longa demais ou tem caracteres de controle.'),
    (Chave: 'val.biblioteca_invalida'; Es: 'Indica la ruta de fbclient.dll (un archivo .dll sin comillas).';
      Pt: 'Informe o caminho do fbclient.dll (um arquivo .dll, sem aspas).'),
    (Chave: 'cfg.motivo_ilegivel'; Es: 'No se pudo leer el archivo.';
      Pt: 'Não foi possível ler o arquivo.'),
    (Chave: 'cfg.motivo_sem_secao'; Es: 'Falta la sección [Database].';
      Pt: 'Falta a seção [Database].'),
    (Chave: 'cfg.motivo_campo'; Es: '%s: %s';
      Pt: '%s: %s'),
    (Chave: 'cfg.motivo_campo_ausente'; Es: 'falta el campo';
      Pt: 'falta o campo'),
    (Chave: 'cfg.motivo_porta_texto'; Es: 'debe ser un número';
      Pt: 'precisa ser um número'),
    (Chave: 'cfgdlg.titulo_primeira'; Es: 'Vamos configurar la conexión';
      Pt: 'Vamos configurar a conexão'),
    (Chave: 'cfgdlg.titulo_reconfig'; Es: 'Ajustar la conexión';
      Pt: 'Ajustar a conexão'),
    (Chave: 'cfgdlg.ajuda_primeira'; Es: 'Es la primera vez que abres el sistema. Ya sugerimos los datos; solo revisa y escribe la contraseña del Firebird.';
      Pt: 'É a primeira vez que o sistema abre. Já sugerimos os dados; é só conferir e digitar a senha do Firebird.'),
    (Chave: 'cfgdlg.ajuda_reconfig'; Es: 'Revisa los datos de conexión con el Firebird. Guardamos una copia del archivo anterior.';
      Pt: 'Confira os dados de conexão com o Firebird. Guardamos uma cópia do arquivo anterior.'),
    (Chave: 'cfgdlg.servidor'; Es: 'Servidor';
      Pt: 'Servidor'),
    (Chave: 'cfgdlg.porta'; Es: 'Puerta';
      Pt: 'Porta'),
    (Chave: 'cfgdlg.banco'; Es: 'Archivo de la base de datos (.fdb)';
      Pt: 'Arquivo do banco de dados (.fdb)'),
    (Chave: 'cfgdlg.usuario'; Es: 'Usuario';
      Pt: 'Usuário'),
    (Chave: 'cfgdlg.senha'; Es: 'Contraseña';
      Pt: 'Senha'),
    (Chave: 'cfgdlg.biblioteca'; Es: 'Biblioteca del cliente (fbclient.dll)';
      Pt: 'Biblioteca do cliente (fbclient.dll)'),
    (Chave: 'cfgdlg.salvar'; Es: 'Guardar y continuar';
      Pt: 'Salvar e continuar'),
    (Chave: 'cfgdlg.sugestoes'; Es: 'Usar sugerencias';
      Pt: 'Usar sugestões'),
    (Chave: 'cfgdlg.hint_servidor'; Es: 'Deja vacío para conexión local sin servidor, o escribe localhost o la dirección del servidor';
      Pt: 'Deixe vazio para conexão local sem servidor, ou informe localhost ou o endereço do servidor'),
    (Chave: 'cfgdlg.hint_banco'; Es: 'Ruta del archivo en la máquina del servidor. Si no existe, el sistema lo crea';
      Pt: 'Caminho do arquivo na máquina do servidor. Se não existir, o sistema cria'),
    (Chave: 'cfgdlg.hint_senha'; Es: 'La contraseña no se muestra y solo se guarda en el config.ini';
      Pt: 'A senha não é exibida e só é gravada no config.ini'),
    (Chave: 'pb.config_invalida.titulo'; Es: 'El archivo de configuración no está correcto';
      Pt: 'O arquivo de configuração não está correto'),
    (Chave: 'pb.config_invalida.msg'; Es: 'No pude usar el config.ini (%s).' + sLineBreak + '' + sLineBreak + 'Puedo abrir la configuración para ajustarlo? Guardo una copia del archivo actual antes de cambiar.';
      Pt: 'Não consegui usar o config.ini (%s).' + sLineBreak + '' + sLineBreak + 'Posso abrir a configuração para ajustar? Guardo uma cópia do arquivo atual antes de alterar.'),
    (Chave: 'pb.banco_sumiu.titulo'; Es: 'No encontramos la base de datos';
      Pt: 'Não encontramos o banco de dados'),
    (Chave: 'pb.banco_sumiu.msg'; Es: 'La base de datos %s ya fue creada en este equipo, pero el archivo no está más ahí (¿lo borraron o lo movieron?).' + sLineBreak + '' + sLineBreak + 'Quieres crear una base nueva y vacía o prefieres ajustar la ruta?';
      Pt: 'O banco de dados %s já foi criado neste computador, mas o arquivo não está mais lá (foi apagado ou movido?).' + sLineBreak + '' + sLineBreak + 'Quer criar um banco novo e vazio ou prefere ajustar o caminho?'),
    (Chave: 'pb.sem_estrutura.titulo'; Es: 'La base de datos está vacía';
      Pt: 'O banco de dados está vazio'),
    (Chave: 'pb.sem_estrutura.msg'; Es: 'La base %s existe, pero no tiene las tablas del sistema.' + sLineBreak + '' + sLineBreak + 'Creo la estructura ahora? No se borra nada de lo que ya exista.';
      Pt: 'O banco %s existe, mas não tem as tabelas do sistema.' + sLineBreak + '' + sLineBreak + 'Posso criar a estrutura agora? Nada do que já existe será apagado.'),
    (Chave: 'pb.outro_sistema.titulo'; Es: 'Esta base de datos es de otro sistema';
      Pt: 'Este banco de dados é de outro sistema'),
    (Chave: 'pb.outro_sistema.msg'; Es: 'El archivo %s ya tiene tablas que no son de este sistema. Por seguridad no creo nada en él.' + sLineBreak + '' + sLineBreak + 'Elige otra ruta en la configuración.';
      Pt: 'O arquivo %s já tem tabelas que não são deste sistema. Por segurança não crio nada nele.' + sLineBreak + '' + sLineBreak + 'Escolha outro caminho na configuração.'),
    (Chave: 'pb.servidor.titulo'; Es: 'No pude comunicarme con el servidor Firebird';
      Pt: 'Não consegui falar com o servidor Firebird'),
    (Chave: 'pb.servidor.msg'; Es: 'Revisa si el Firebird está en ejecución en %s (puerta %d) y si la puerta está liberada.';
      Pt: 'Confira se o Firebird está em execução em %s (porta %d) e se a porta está liberada.'),
    (Chave: 'pb.credenciais.titulo'; Es: 'Usuario o contraseña de la base inválidos';
      Pt: 'Usuário ou senha do banco inválidos'),
    (Chave: 'pb.credenciais.msg'; Es: 'El Firebird rechazó el usuario %s. Revisa la contraseña en la configuración.';
      Pt: 'O Firebird recusou o usuário %s. Confira a senha na configuração.'),
    (Chave: 'pb.biblioteca.titulo'; Es: 'Biblioteca del Firebird no disponible';
      Pt: 'Biblioteca do Firebird indisponível'),
    (Chave: 'pb.biblioteca.msg'; Es: 'No pude cargar el fbclient.dll (%s).' + sLineBreak + '' + sLineBreak + 'Debe existir y tener los mismos bits del sistema (32 o 64).';
      Pt: 'Não consegui carregar o fbclient.dll (%s).' + sLineBreak + '' + sLineBreak + 'Ele precisa existir e ter os mesmos bits do sistema (32 ou 64).'),
    (Chave: 'pb.erro.titulo'; Es: 'No fue posible abrir la base de datos';
      Pt: 'Não foi possível abrir o banco de dados'),
    (Chave: 'pb.erro.msg'; Es: 'Ocurrió un error inesperado al acceder a la base %s. El detalle quedó guardado en el log.';
      Pt: 'Aconteceu um erro inesperado ao acessar o banco %s. O detalhe ficou guardado no log.'),
    (Chave: 'acao.reconfigurar'; Es: 'Ajustar configuración';
      Pt: 'Ajustar configuração'),
    (Chave: 'acao.tentar'; Es: 'Intentar de nuevo';
      Pt: 'Tentar de novo'),
    (Chave: 'acao.sair'; Es: 'Salir';
      Pt: 'Sair'),
    (Chave: 'acao.criar_novo'; Es: 'Crear base nueva';
      Pt: 'Criar banco novo'),
    (Chave: 'acao.criar_estrutura'; Es: 'Crear estructura';
      Pt: 'Criar estrutura'),
    (Chave: 'aviso.banco_criado.titulo'; Es: 'Base de datos creada';
      Pt: 'Banco de dados criado'),
    (Chave: 'aviso.banco_criado.msg'; Es: 'Creé la base %s con las tablas y los datos de ejemplo.';
      Pt: 'Criei o banco %s com as tabelas e os dados de exemplo.'),
    (Chave: 'aviso.estrutura_criada.titulo'; Es: 'Estructura creada';
      Pt: 'Estrutura criada'),
    (Chave: 'aviso.estrutura_criada.msg'; Es: 'Las tablas del sistema fueron creadas en %s.';
      Pt: 'As tabelas do sistema foram criadas em %s.'),
    (Chave: 'aviso.estrutura_atualizada.titulo'; Es: 'Base de datos actualizada';
      Pt: 'Banco de dados atualizado'),
    (Chave: 'aviso.estrutura_atualizada.msg'; Es: 'Actualicé la estructura de %s (campo Observación). No se perdió ningún dato.';
      Pt: 'Atualizei a estrutura de %s (campo Observação). Nenhum dado foi perdido.'),
    (Chave: 'cfgdlg.escolher_pasta'; Es: 'Elegir la carpeta de la base de datos';
      Pt: 'Escolher a pasta do banco de dados'),
    (Chave: 'cfgdlg.pasta_programa'; Es: 'Usar la carpeta del programa';
      Pt: 'Usar a pasta do programa'),
    (Chave: 'cfgdlg.pasta_padrao'; Es: 'Usar la carpeta estándar (ProgramData)';
      Pt: 'Usar a pasta padrão (ProgramData)'),
    (Chave: 'cfgdlg.titulo_pasta'; Es: 'Elige la carpeta donde quedará la base de datos';
      Pt: 'Escolha a pasta onde o banco de dados vai ficar'),
    (Chave: 'cfgdlg.hint_pasta_remota'; Es: 'Con un servidor en otra máquina, la carpeta es la de esa máquina; escribe la ruta en el campo';
      Pt: 'Com servidor em outra máquina, a pasta é a dessa máquina; digite o caminho no campo')
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
