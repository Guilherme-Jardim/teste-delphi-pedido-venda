# Pedido de Venda (Delphi + FireDAC + Firebird)

Tela de Pedido de Venda feita em Delphi (VCL), com persistência em Firebird via FireDAC e **sem componentes de terceiros**. O sistema abre em **português do Brasil** e troca para **espanhol** (idioma da equipe da empresa) com um clique nas bandeiras do topo.

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

**Extras**

- Troca de idioma (português padrão / espanhol) em todo o sistema, com a escolha lembrada na próxima abertura.
- Componentes visuais próprios, num pacote separado (botões redondos com ícone, cartões, campos, avisos e grade).
- Atalhos de teclado, dicas (hints) em todos os campos e botões e foco sempre visível.

## Estrutura do projeto

```
Componentes/Componentes Pedido/   pacote de componentes visuais (Componentes.Pedido.dpk)
  Core/                           tema, ícones vetoriais e funções de apoio
  Buttons/ Cards/ Edits/          RoundButton, FlagButton, InfoCard, ModernEdit
  Alerts/ Grids/                  AlertBar, ModernGrid
src/
  Model/                          entidades e exceções de negócio
  DAO/                            acesso a dados: todo o SQL fica aqui
  Controller/                     regras de negócio (validações, montagem do item)
  View/                           telas: o visual está no .dfm, o .pas só tem eventos
  Infra/                          config.ini, conexão FireDAC, idiomas e log
  Recursos/                       ícone do executável
db/db.sql                         DDL completo + carga de teste
db/migracoes/                     alterações para bancos já criados
bin/Win32, bin/Win64              fbclient.dll (e dependências) de cada plataforma
tests/                            testes DUnitX
config.ini.example                modelo do arquivo de configuração
```

O fluxo é **View → Controller → DAO**. A tela nunca fala com o banco, o controller não tem SQL e o DAO não tem regra de negócio. O total do pedido vive no Model (`TPedidoModel.ValorTotal`) e é recalculado a cada leitura, então não existe valor guardado que possa ficar velho depois de excluir ou editar um item.

## Versão

A versão atual aparece no título da janela, ao lado do nome na tela principal, nas propriedades do `.exe` e no log. Ela segue [versionamento semântico](https://semver.org/lang/pt-BR/) e é definida uma vez, nas opções do projeto (*Versão do aplicativo*). O histórico de mudanças está no [CHANGELOG](CHANGELOG.md) e cada entrega vira uma *tag* e uma *release* no GitHub.

## Requisitos

- Delphi com FireDAC (testado no Delphi 13 Community Edition). O DUnitX já vem com o Delphi.
- Firebird 3, 4 ou 5.
- O `fbclient.dll` precisa ter os mesmos bits do executável: `bin/Win32` para 32 bits e `bin/Win64` para 64 bits.

## 1. Criar o banco

Com o Firebird instalado, abra um terminal na raiz do projeto e use o `isql` (pasta de instalação do Firebird):

```bat
isql -user SYSDBA -password SUA_SENHA
SQL> CREATE DATABASE 'localhost:C:\dados\PEDIDOS.FDB' USER 'SYSDBA' PASSWORD 'SUA_SENHA' DEFAULT CHARACTER SET UTF8;
SQL> QUIT;

isql -user SYSDBA -password SUA_SENHA localhost:C:\dados\PEDIDOS.FDB -i db\db.sql
```

A pasta `C:\dados` precisa existir e o servidor Firebird precisa poder gravar nela. O script cria `CLIENTE`, `PRODUTO`, `PEDIDO` e `PEDIDO_ITEM`, o generator `GEN_PEDIDO_NUMERO`, o identity de `PEDIDO_ITEM.ID`, FKs, os índices pedidos e 12 clientes e 12 produtos de exemplo.

Se o banco já existia antes do campo Observação, rode também `db/migracoes/001_pedido_observacao.sql`.

## 2. Configurar o INI

Copie `config.ini.example` para `config.ini` na raiz e ajuste:

```ini
[Database]
Database=C:\dados\PEDIDOS.FDB
Username=SYSDBA
Password=SUA_SENHA
Server=localhost
Port=3050
ClientLibrary=bin\Win32\fbclient.dll
```

`ClientLibrary` pode ser relativo à pasta do `config.ini` ou absoluto. O `config.ini` está no `.gitignore`: a senha real nunca vai para o repositório.

## 3. Compilar e executar

1. Abra `pedidoVendaProjectGroup.groupproj` no Delphi (ele reúne o pacote de componentes e o aplicativo).
2. Compile o pacote **Componentes.Pedido** e instale-o (clique direito no projeto → *Install*). Assim os componentes aparecem na paleta, na página "Pedido", e o formulário abre no designer.
3. Compile e execute o projeto **PedidoVenda** (Windows 32 bits).

O programa procura o `config.ini` subindo pastas a partir do executável, então funciona rodando de qualquer subpasta do projeto.

## Atalhos de teclado

| Atalho | Ação |
|---|---|
| Ctrl+G | Gravar o pedido |
| Ctrl+N | Pedido novo |
| Ctrl+L | Carregar um pedido gravado |
| Ctrl+D | Cancelar um pedido gravado |
| Ctrl+Enter | Inserir ou atualizar o item |
| Enter / Supr na grade | Editar / excluir o item selecionado |
| Tab / Shift+Tab | Navegar entre os campos |

## Idiomas

As bandeiras no topo (Brasil à esquerda, Espanha à direita) trocam todo o texto do sistema na hora: rótulos, botões, dicas, mensagens e diálogos. O português do Brasil é o padrão. A escolha fica em `%LOCALAPPDATA%\PedidoVenda\idioma.cfg`. Todos os textos estão em `src/Infra/Pedido.Infra.Idioma.pas`, lado a lado nos dois idiomas, e um teste confere que nenhuma tela fica sem tradução.

## Acessibilidade

- Tudo funciona só com o teclado, com ordem de Tab lógica e anel de foco visível em botões e campos.
- Dica (hint) em todo campo e botão, incluindo o atalho correspondente.
- Botões só com ícone usam o próprio `Caption` como nome para leitores de tela (propriedade `SomenteIcone`).
- Contraste conferido: texto principal e botões azuis passam de 4,5:1 sobre o fundo branco.
- Erros aparecem em uma faixa com ícone, cor e texto (nunca só cor) e não bloqueiam a digitação.
- Confirmações destrutivas (excluir item, cancelar pedido) usam botões Sim/Não no idioma escolhido.

## Segurança

- Todo SQL é parametrizado e fica só nos DAOs (sem concatenação de texto digitado).
- O `config.ini` real nunca é versionado e a senha não é gravada em log.
- Erros de banco não vão para a tela: a pessoa vê uma mensagem simples e o detalhe técnico vai para `%LOCALAPPDATA%\PedidoVenda\pedido.log`.
- Limites de entrada (quantidade, valor, tamanho dos textos) evitam estouro das colunas `NUMERIC` e do `VARCHAR`.
- Gravação e cancelamento usam transação; em qualquer falha há rollback e o número do pedido volta ao estado anterior.
- Recomenda-se usar no `config.ini` um usuário do Firebird com permissão só nas quatro tabelas do sistema, e não o SYSDBA.

## Roteiro rápido de testes manuais

1. **Idioma:** o sistema abre em português. Clique na bandeira da Espanha: tudo muda para espanhol. Clique na do Brasil para voltar.
2. **Cliente inexistente:** digite `999` no código do cliente e saia do campo. Aparece o aviso em vermelho e o nome fica vazio.
3. **Cliente válido:** digite `1`. Aparecem nome, cidade e UF.
4. **Inserir item:** produto `1`. Descrição e preço (39,90) aparecem. Quantidade `2` e Ctrl+Enter (ou o botão). A grade mostra 1 linha e o total fica 79,80.
5. **Produto repetido:** insira o produto `1` de novo com quantidade `1`. Ficam 2 linhas e o total vai a 119,70.
6. **Editar com ENTER:** selecione uma linha e tecle ENTER. O botão vira "Atualizar item". Mude a quantidade e confirme.
7. **Excluir com DEL:** selecione uma linha, tecle DEL e confirme. O total é recalculado na hora. Responda "No" para ver que nada muda.
8. **Observação:** escreva um comentário curto no campo Observação.
9. **Gravar:** Ctrl+G. O aviso mostra o número gerado. Confira no banco:
   ```sql
   SELECT * FROM PEDIDO;
   SELECT * FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = 1;
   ```
10. **Validações:** tente gravar sem cliente e sem itens. A tela avisa e nada é gravado.
11. **Carregar:** Ctrl+L, informe o número gravado. Cabeçalho, observação e itens voltam. Altere e grave de novo: o pedido é atualizado, sem criar outro número.
12. **Cancelar:** com o pedido carregado, Ctrl+D e confirme. Pedido e itens somem do banco.
13. **Rollback:** pare o serviço do Firebird com a tela aberta e tente gravar. A mensagem é simples e o banco continua íntegro.

## Testes automatizados (DUnitX)

Abra `tests/PedidoVenda.Tests.dpr`, compile e execute (ou rode o `PedidoVenda.Tests.exe` no terminal). São 44 testes, em cinco grupos:

| Grupo | O que confere | Precisa de banco |
|---|---|---|
| Totalização | soma dos itens, produtos repetidos, arredondamento, recálculo ao excluir | não |
| Validação do item | limites de quantidade e valor, código inválido, mensagens por idioma | não |
| Idioma | português padrão, troca para espanhol, formatação, tradução completa | não |
| Controller | regras que bloqueiam a gravação antes de ir ao banco | não |
| Integração | gravar/carregar/cancelar, número crescente, rollback, FK, consulta parametrizada | sim (usa o `config.ini`) |

Os testes de integração criam pedidos de teste e removem tudo no final. Sem `config.ini` ou sem banco eles são ignorados, e os demais continuam rodando.

## Créditos

As bandeiras desenhadas no seletor de idioma seguem as formas do conjunto [flag-icons](https://github.com/lipis/flag-icons) (licença MIT). O `fbclient.dll` incluído é do Firebird (licença IPL/IDPL, texto em `bin/`).
