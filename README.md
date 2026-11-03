# Pedido de Venda (Delphi + FireDAC + Firebird)

Tela de Pedido de Venda feita em Delphi (VCL), com persistência em Firebird via FireDAC e **sem componentes de terceiros**. O sistema abre em **português do Brasil** e troca para **espanhol** (idioma da equipe da empresa) com um clique nas bandeiras do topo.

Na primeira vez que abre, o próprio executável configura a conexão e **cria o banco de dados**. Quem prefere pode criar o banco à mão com o `db.sql`: os dois caminhos funcionam e dão no mesmo banco.

## O que o sistema faz

**Pedido de venda (requisitos do teste)**

- Informa o cliente pelo código e mostra nome, cidade e UF (somente leitura). Cliente inexistente gera um aviso claro na tela.
- Inclui itens com código do produto, quantidade e valor unitário. O valor vem com o preço de venda e pode ser alterado; a descrição aparece sozinha.
- Grade com código, descrição, quantidade, valor unitário e valor total do item. Aceita o mesmo produto em linhas diferentes.
- Com o foco na grade, **ENTER** carrega o item para edição (o botão vira "Atualizar item") e **DEL** exclui com confirmação. O total do pedido é recalculado na hora.
- Total no rodapé, sempre calculado a partir dos itens.
- **Gravar pedido** grava cabeçalho e itens na mesma transação (commit ou rollback).
- Campo **Observação** no cabeçalho.
- Bônus: **Carregar pedido** por número, **Cancelar pedido** (exclui pedido e itens em transação) e testes unitários DUnitX da totalização.

**Além do teste**

- Criação automática do `config.ini` e do banco na primeira execução, com tratamento de todos os cenários de falha (ver abaixo).
- Pasta do banco à escolha: pasta padrão, pasta do programa ou qualquer outra.
- Português e espanhol, com a escolha lembrada na próxima abertura.
- Componentes visuais próprios, em um pacote separado, e interface toda no `.dfm`.
- Atalhos de teclado, dicas nos campos e botões, contraste conferido.
- Versão do aplicativo no executável, na tela e no log.

## Estrutura do projeto

```
pedidoVendaProjectGroup.groupproj   grupo com o aplicativo, o pacote de componentes e os testes
Componentes/Componentes Pedido/     pacote de componentes visuais (Componentes.Pedido.dpk)
  Core/                             tema, ícones vetoriais e funções de apoio
  Buttons/ Cards/ Edits/            RoundButton, FlagButton, InfoCard, ModernEdit
  Alerts/ Grids/                    AlertBar, ModernGrid
src/
  Domain/                           núcleo do negócio: entidades, objetos de valor, agregado, erros,
                                    eventos e contratos dos repositórios (não depende de nada)
  Application/                      casos de uso (um por ação) e publicador de eventos
  Infrastructure/                   config.ini, conexão, esquema do banco, inicialização, idiomas, log
    Persistence/                    repositórios FireDAC: todo o SQL fica aqui
  Presentation/                     telas: o visual está no .dfm, o .pas só tem eventos
  Recursos/                         ícone do executável
db/db.sql                           DDL completo + carga de teste (criação manual)
db/migracoes/                       alterações para bancos já criados
bin/Win32, bin/Win64                fbclient.dll (e dependências) de cada plataforma
tests/                              testes DUnitX
config.ini.example                  modelo do arquivo de configuração
CHANGELOG.md                        histórico de versões
```

O projeto segue **Clean Architecture** com **DDD** (desenho orientado ao domínio) e **SOLID**. As dependências apontam sempre para dentro:

```
Presentation ──▶ Application ──▶ Domain ◀── Infrastructure
 (telas)         (casos de uso)  (regras)    (FireDAC, INI, log)
```

- **Domain** não conhece banco, tela nem idioma. É onde vivem as regras: `TPedido` (raiz do agregado), `TPedidoItem`, `TCliente`, `TProduto`, os objetos de valor `TQuantidade` e `TDinheiro`, os erros de negócio (`EDominioErro` com um código), os eventos e as interfaces dos repositórios (`IClienteRepository`, `IProdutoRepository`, `IPedidoRepository`).
- **Application** tem um caso de uso por ação da pessoa: consultar cliente, consultar produto, criar item, gravar, carregar e cancelar pedido. Cada um recebe suas dependências pelo construtor.
- **Infrastructure** implementa as interfaces do domínio com FireDAC (`Persistence/`) e cuida do que é técnico: `config.ini`, criação do banco, log e textos por idioma. A raiz de composição (`Pedido.Infra.Composicao`) é quem liga tudo.
- **Presentation** só chama casos de uso. Os erros chegam com um código e a tela os traduz para o idioma escolhido (`Pedido.Presentation.TradutorErros`).

### Glossário DDD

| Conceito | No projeto |
|---|---|
| Agregado e raiz | `TPedido` guarda os itens. Tudo que muda itens ou total passa por ele, e ele garante as regras (cliente e ao menos um item para gravar, índice de item válido, observação até 200 caracteres). |
| Entidade | `TPedido` (identificado pelo número), `TPedidoItem`, `TCliente`, `TProduto`. |
| Objeto de valor | `TQuantidade` (maior que zero, até 99.999,999) e `TDinheiro` (duas casas, limites do banco). São imutáveis e só existem válidos. |
| Repositório | Interfaces no domínio; implementação FireDAC na infraestrutura, com transação por pedido. |
| Evento de domínio | `PedidoGravado` e `PedidoCancelado`, publicados pelos casos de uso. Um assinante da infraestrutura registra cada um no log. |
| Linguagem ubíqua | Nomes em português do negócio: pedido, item, cliente, produto, gravar, cancelar, quantidade, valor unitário. |

O total do pedido é `TPedido.ValorTotal`, recalculado a cada leitura, então não existe valor guardado que possa ficar velho depois de excluir ou editar um item.

### SOLID

| Princípio | Onde aparece |
|---|---|
| Responsabilidade única | Cada unit tem um assunto: `Validacao` valida, `Config` lê e grava o INI, `EsquemaBanco` guarda o DDL, `RegistroBanco` lembra quais bancos já foram criados, `Inicializador` decide o que fazer em cada situação. |
| Aberto/fechado | Novos textos entram na tabela de idiomas e novos estados do banco no `Inicializador` sem mexer nas telas. |
| Substituição de Liskov | Qualquer implementação de `IClienteRepository`, `IProdutoRepository` e `IPedidoRepository` (FireDAC ou falsa, nos testes) serve para os casos de uso. |
| Segregação de interfaces | Interfaces pequenas: `IInspetorBanco` (só diagnostica), `ICriadorBanco` (só cria), `IRegistroBanco`, `IConfigRepositorio`, `IInteracaoInicializacao`. |
| Inversão de dependência | Casos de uso e inicializador recebem interfaces pelo construtor. A raiz de composição (`Pedido.Infra.Composicao`) e o `.dpr` são os únicos lugares que escolhem as classes concretas. |

## Requisitos

- Delphi com FireDAC (testado no Delphi 13 Community Edition). O DUnitX já vem com o Delphi.
- Firebird 3, 4 ou 5 instalado e em execução.
- O `fbclient.dll` precisa ter os mesmos bits do executável: `bin/Win32` para 32 bits e `bin/Win64` para 64 bits.

## Versão

A versão atual aparece no título da janela, ao lado do nome na tela principal, nas propriedades do `.exe` e no log. Ela segue [versionamento semântico](https://semver.org/lang/pt-BR/) e é definida uma vez, nas opções do projeto (*Versão do aplicativo*). O histórico de mudanças está no [CHANGELOG](CHANGELOG.md) e cada entrega vira uma *tag* e uma *release* no GitHub.

## Banco de dados: duas formas de criar

### Forma 1: automática, pelo executável (recomendada)

Abra o sistema. Na **primeira execução**:

1. Se não existir `config.ini`, abre a tela **Vamos configurar a conexão**, já preenchida com sugestões (servidor `localhost`, porta `3050`, usuário `SYSDBA`, o `fbclient.dll` do projeto e o caminho do banco). A **senha nunca é adivinhada**: é só digitar a senha do seu Firebird.
2. Ao salvar, o `config.ini` é gravado (na raiz do projeto) e o sistema confere o banco.
3. Se o banco ainda não existe e **nunca foi criado neste computador**, o sistema cria sozinho o arquivo `.fdb`, as tabelas, o generator, os índices, as chaves estrangeiras e os dados de exemplo, e mostra um aviso de que terminou.

**Onde o banco fica.** Na tela de configuração, ao lado do campo do arquivo, há três botões:

| Botão | O que faz |
|---|---|
| Pasta | Abre o seletor para você escolher a pasta do banco |
| Caixa | Usa a pasta do programa (a mesma do executável) |
| Documento novo | Volta para a pasta padrão (`C:\ProgramData\PedidoVenda\dados`) |

O nome do arquivo também é livre (`PEDIDOS.FDB` por padrão). A pasta é criada se não existir. Se o servidor Firebird estiver em outra máquina, digite o caminho que **aquela máquina** enxerga.

> A pasta padrão é a `ProgramData` porque o serviço do Firebird costuma rodar como SYSTEM e consegue gravar ali. Em outra pasta, o serviço do Firebird precisa ter permissão de escrita.

### Forma 2: manual, com o `db.sql`

Com o Firebird instalado, abra um terminal na raiz do projeto e use o `isql` (pasta de instalação do Firebird):

```bat
isql -user SYSDBA -password SUA_SENHA
SQL> CREATE DATABASE 'localhost:C:\dados\PEDIDOS.FDB' USER 'SYSDBA' PASSWORD 'SUA_SENHA' DEFAULT CHARACTER SET UTF8;
SQL> QUIT;

isql -user SYSDBA -password SUA_SENHA localhost:C:\dados\PEDIDOS.FDB -i db\db.sql
```

A pasta (`C:\dados` no exemplo) pode ser **qualquer uma**; ela só precisa existir e o servidor Firebird precisa poder gravar nela. Também dá para usar FlameRobin, DBeaver ou outra ferramenta: o `db.sql` é um script SQL comum.

O script cria `CLIENTE`, `PRODUTO`, `PEDIDO` e `PEDIDO_ITEM`, o generator `GEN_PEDIDO_NUMERO`, o identity de `PEDIDO_ITEM.ID`, as FKs, os índices pedidos (`PEDIDO(CODIGO_CLIENTE)`, `PEDIDO_ITEM(NUMERO_PEDIDO)` e `PEDIDO_ITEM(CODIGO_PRODUTO)`) e 12 clientes e 12 produtos de exemplo. Se o banco já existia antes do campo Observação, rode também `db/migracoes/001_pedido_observacao.sql` (o sistema também faz isso sozinho ao abrir).

Depois, crie o `config.ini` à mão (próxima seção) ou deixe o sistema abrir a tela de configuração. Como o banco já existe e tem estrutura, o sistema só confere e abre.

> O script de criação embutido no executável e o `db/db.sql` são **o mesmo script**: um teste automatizado confere que continuam iguais.

## Configuração: `config.ini`

O arquivo fica na **raiz do projeto**. Nos dois jeitos a configuração termina no mesmo formato:

```ini
[Database]
Database=C:\ProgramData\PedidoVenda\dados\PEDIDOS.FDB
Username=SYSDBA
Password=SUA_SENHA
Server=localhost
Port=3050
ClientLibrary=bin\Win32\fbclient.dll
```

- **Automático:** a tela de configuração cria o arquivo e permite ajustar tudo (servidor, porta, caminho do banco, usuário, senha e biblioteca).
- **Manual:** copie `config.ini.example` para `config.ini` e edite.

`ClientLibrary` pode ser relativo à pasta do `config.ini` ou absoluto. O `config.ini` está no `.gitignore`: a senha real nunca vai para o repositório. Todos os campos são validados na leitura e na gravação.

## O que acontece em cada situação ao abrir

| Situação | O que o sistema faz |
|---|---|
| Sem `config.ini` (primeira vez) | Abre a configuração com sugestões; grava o arquivo |
| `config.ini` ilegível, sem a seção `[Database]`, com campo faltando ou valor inválido | Avisa o motivo, **guarda uma cópia** (`config.ini.bak-DATA-HORA`) e pergunta se pode reconfigurar |
| Banco não existe e **nunca foi criado** neste computador | Cria o banco, a estrutura e a carga de exemplo e avisa |
| Banco **já foi criado** antes, mas o arquivo sumiu (apagado, movido) | Avisa e pergunta: criar banco novo e vazio, ajustar o caminho ou sair |
| Banco existe, mas está **vazio** ou com tabelas faltando | Pergunta se pode criar o que falta (nunca apaga nem altera dados) |
| Banco existe, mas é de **outro sistema** | Não mexe em nada; pede outro caminho |
| Banco antigo, sem o campo `OBSERVACAO` | Acrescenta a coluna sozinho, sem perder dados |
| Servidor Firebird parado ou inalcançável | Avisa o endereço e a porta; oferece tentar de novo ou ajustar |
| Usuário ou senha recusados | Avisa e oferece ajustar a configuração |
| `fbclient.dll` ausente ou com bits diferentes do aplicativo | Avisa o caminho e oferece ajustar |
| Falha inesperada | Mostra uma mensagem simples, grava o detalhe no log e oferece tentar de novo, ajustar ou sair |

A decisão "nunca foi criado" ou "já existiu" vem de um registro local em `%LOCALAPPDATA%\PedidoVenda\bancos.ini`, que guarda só um código (hash) do endereço do banco: nenhuma senha e nenhum caminho legível.

## Compilar e executar

1. Abra `pedidoVendaProjectGroup.groupproj` no Delphi (aplicativo, pacote de componentes e testes).
2. Compile o pacote **Componentes.Pedido** e instale-o (clique direito no projeto → *Install*). Assim os componentes aparecem na paleta, na página "Pedido", e os formulários abrem no designer.
3. Compile e execute o projeto **PedidoVenda**. O padrão é Windows 32 bits; para 64 bits, escolha a plataforma *Windows 64-bit* e use o `fbclient.dll` de `bin/Win64` no `config.ini`.

O programa procura o `config.ini` subindo pastas a partir do executável, então funciona rodando de qualquer subpasta do projeto.

## Atalhos de teclado

| Atalho | Ação |
|---|---|
| Ctrl+G | Gravar o pedido |
| Ctrl+N | Pedido novo |
| Ctrl+L | Carregar um pedido gravado |
| Ctrl+D | Cancelar um pedido gravado |
| Ctrl+Enter | Inserir ou atualizar o item |
| Enter / Delete na grade | Editar / excluir o item selecionado |
| Tab / Shift+Tab | Navegar entre os campos |

## Idiomas

As bandeiras no topo (Brasil à esquerda, Espanha à direita) trocam todo o texto do sistema na hora: rótulos, botões, dicas, mensagens e diálogos, inclusive os da inicialização. O português do Brasil é o padrão. A escolha fica em `%LOCALAPPDATA%\PedidoVenda\idioma.cfg`. Todos os textos estão em `src/Infrastructure/Pedido.Infra.Idioma.pas`, lado a lado nos dois idiomas, e um teste confere que nenhuma tela fica sem tradução.

## Acessibilidade

- Tudo funciona só com o teclado, com ordem de Tab lógica e anel de foco visível em botões e campos.
- Dica (hint) em todo campo e botão, incluindo o atalho correspondente.
- **Leitores de tela (NVDA, JAWS e Narrator):** os componentes desenhados à mão respondem ao MSAA e ao UI Automation (`ComponentAccess`). Botões aparecem como botão, campos de texto como campo, com o rótulo como nome, o valor e a dica; a grade é lida como lista com a linha atual ("Linha 2 de 3; Cód. produto 1; ..."); os avisos são anunciados assim que aparecem; a bandeira do idioma em uso aparece como marcada.
- Botões só com ícone usam o próprio `Caption` como nome para leitores de tela (propriedade `SomenteIcone`).
- Contraste conferido: texto e botões passam de 4,5:1 sobre o fundo (WCAG AA).
- Erros aparecem em uma faixa com ícone, cor e texto (nunca só cor) e não bloqueiam a digitação.
- Confirmações, avisos e as janelas de inicialização têm o mesmo visual do sistema (cartão, ícone e botões arredondados), com Enter no botão principal, Esc para fechar e o foco devolvido ao campo de onde a pessoa veio. Só o seletor de pasta usa a janela do Windows.

## Segurança

- Todo SQL é parametrizado e fica só nos repositórios de `Infrastructure/Persistence`. Um teste varre esses arquivos e falha se algum SQL for montado com texto variável.
- O que vem de fora (servidor, porta, caminho do banco, usuário, senha, biblioteca) é validado: aspas, `;`, `..`, `|`, `*`, caracteres de controle e tamanhos absurdos são recusados. A senha nunca vira SQL.
- A criação do banco usa os parâmetros de conexão do FireDAC; o caminho do arquivo nunca é colado em comando SQL.
- O `config.ini` é gravado de forma atômica (arquivo temporário e troca) e o arquivo antigo é copiado antes de ser substituído.
- Banco de outro sistema nunca é alterado; "criar estrutura" só acrescenta o que falta.
- O `config.ini` real nunca é versionado e a senha não é gravada em log.
- Erros de banco não vão para a tela: a pessoa vê uma mensagem simples e o detalhe técnico vai para `%LOCALAPPDATA%\PedidoVenda\pedido.log`.
- Limites de entrada (quantidade, valor, tamanho dos textos) evitam estouro das colunas `NUMERIC` e do `VARCHAR`.
- Gravação e cancelamento usam transação; em qualquer falha há rollback e o número do pedido volta ao estado anterior.
- Recomenda-se usar no `config.ini` um usuário do Firebird com permissão só nas quatro tabelas do sistema, e não o SYSDBA.

## Roteiro rápido de testes manuais

**Primeira execução**

1. Apague (ou renomeie) o `config.ini` e abra o sistema. Aparece a tela *Vamos configurar a conexão* com tudo sugerido. Digite a senha, confira a porta e clique em *Salvar e continuar*.
2. O sistema cria o banco e mostra o aviso *Banco de dados criado*. A tela principal abre.
3. Banco sumiu: feche o sistema, apague o arquivo `.fdb` e abra de novo. Aparece *Não encontramos o banco de dados* com as opções *Criar banco novo*, *Ajustar configuração* e *Sair*.
4. INI corrompido: abra o `config.ini` e apague a linha `Port=`. Abra o sistema: aparece *O arquivo de configuração não está correto*, citando o campo `Port`.
5. Servidor parado: pare o serviço do Firebird e abra o sistema. Aparece o aviso com *Tentar de novo*.

**Pedido**

6. **Idioma:** clique na bandeira da Espanha: tudo muda para espanhol. Clique na do Brasil para voltar.
7. **Cliente inexistente:** digite `999` no código do cliente e saia do campo. Aparece o aviso em vermelho e o nome fica vazio.
8. **Cliente válido:** digite `1`. Aparecem nome, cidade e UF.
9. **Inserir item:** produto `1`. Descrição e preço (39,90) aparecem. Quantidade `2` e Ctrl+Enter (ou o botão). A grade mostra 1 linha e o total fica 79,80.
10. **Produto repetido:** insira o produto `1` de novo com quantidade `1`. Ficam 2 linhas e o total vai a 119,70.
11. **Editar com ENTER:** selecione uma linha e tecle ENTER. O botão vira "Atualizar item". Mude a quantidade e confirme.
12. **Excluir com DEL:** selecione uma linha, tecle DEL e confirme. O total é recalculado na hora. Responda "Não" para ver que nada muda.
13. **Observação:** escreva um comentário curto no campo Observação.
14. **Gravar:** Ctrl+G. O aviso mostra o número gerado. Confira no banco:
    ```sql
    SELECT * FROM PEDIDO;
    SELECT * FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = 1;
    ```
15. **Validações:** tente gravar sem cliente e sem itens. A tela avisa e nada é gravado.
16. **Carregar:** Ctrl+L, informe o número gravado. Cabeçalho, observação e itens voltam. Altere e grave de novo: o pedido é atualizado, sem criar outro número.
17. **Cancelar:** com o pedido carregado, Ctrl+D e confirme. Pedido e itens somem do banco.

## Testes automatizados (DUnitX)

Abra `tests/PedidoVenda.Tests.dpr`, compile e execute (ou rode o `PedidoVenda.Tests.exe` no terminal). São 259 testes:

| Grupo | O que confere | Precisa de banco |
|---|---|---|
| Totalização | soma dos itens, produtos repetidos, arredondamento, recálculo ao excluir | não |
| Validação do item | limites de quantidade e valor, código inválido, mensagens por idioma | não |
| Idioma e versão | português padrão, troca para espanhol, tradução completa, leitura de versão | não |
| Domínio | objetos de valor, invariantes do agregado `TPedido`, erros com código | não |
| Eventos | eventos de domínio e publicador em memória (inclusive assinante com defeito) | não |
| Casos de uso | regras da aplicação, com repositórios falsos e conferência dos eventos | não |
| Validação das entradas | caminhos, servidores, portas, usuários e senhas, incluindo tentativas de injeção | não |
| Configuração (INI) | arquivo ausente, válido, corrompido, campos inválidos, gravação atômica, cópia de segurança | não |
| Inicializador | todos os cenários de inicialização, com peças falsas, inclusive o limite contra laço infinito | não |
| Esquema, segurança e registro | `db.sql` igual ao esquema embutido; repositórios sem SQL montado; registro de bancos criados | não |
| Integração com o pedido | gravar, carregar, cancelar, número crescente, rollback, FK | sim |
| Banco de verdade | criar banco novo, pasta inexistente, estrutura idempotente, banco vazio, banco de outro sistema, migração de `OBSERVACAO`, servidor fora do ar, senha errada, biblioteca ausente ou com bits errados, fluxo completo de primeira execução | sim |

Os testes que usam banco criam o que precisam em pasta temporária (ou apagam o que criaram) e usam o servidor do `config.ini`. Sem `config.ini` ou sem servidor local, eles passam sem verificar nada e os demais continuam rodando.

## Créditos

As bandeiras desenhadas no seletor de idioma seguem as formas do conjunto [flag-icons](https://github.com/lipis/flag-icons) (licença MIT). O `fbclient.dll` incluído é do Firebird (licença IPL/IDPL, texto em `bin/`).
