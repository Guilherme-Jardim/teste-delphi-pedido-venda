# Pedido de Venda (Delphi + FireDAC + Firebird)

Tela de Pedido de Venda em Delphi (VCL) com persistência em Firebird via FireDAC, sem componentes de terceiros. O projeto foi organizado em camadas (Model, Repository, Service, Controller e View) e todo SQL usa parâmetros.

## O que a aplicação faz

- Informa o cliente pelo código e mostra nome, cidade e UF (somente leitura). Cliente inexistente gera aviso na tela.
- Insere itens com código do produto, quantidade e valor unitário. O valor vem preenchido com o preço de venda e pode ser alterado. A descrição aparece (somente leitura) ao informar o código.
- Grid com código, descrição, quantidade, valor unitário e valor total do item. Aceita o mesmo produto em linhas diferentes.
- Com o foco no grid: **ENTER** carrega o item nos campos para edição (o botão vira "Atualizar Item") e **DEL** exclui o item com confirmação.
- Total do pedido no rodapé, sempre calculado a partir dos itens.
- **Gravar Pedido** salva cabeçalho e itens na mesma transação (commit ou rollback).
- Campo **Observação** no cabeçalho (evolução pedida no teste).
- Bônus: **Carregar Pedido** por número, **Cancelar Pedido** (exclui pedido e itens em transação) e testes unitários DUnitX da totalização.

## Estrutura

```
bin/Win32, bin/Win64   fbclient.dll (e dependências) para cada plataforma
db/db.sql              DDL completo + carga de teste
db/migracoes/          alterações para bancos já criados
src/Infra/             leitura do config.ini e fábrica da conexão FireDAC
src/Model/             entidades e exceções de negócio
src/Repository/        acesso a dados (interfaces + FireDAC)
src/Service/           regras de negócio
src/Controller/        pedido em edição e coordenação da tela
src/View/              formulário VCL
tests/                 testes unitários DUnitX
config.ini.example     modelo do arquivo de configuração
```

## Requisitos

- Delphi com FireDAC (testado com a Community Edition) e, para os testes, DUnitX (já vem com o Delphi).
- Firebird 3, 4 ou 5 instalado.
- O `fbclient.dll` precisa ter o mesmo número de bits do executável: use `bin/Win32` para compilar em 32 bits e `bin/Win64` para 64 bits.

## 1. Criar o banco e rodar o script

Com o Firebird instalado, abra um terminal na raiz do projeto e use o `isql` (fica na pasta de instalação do Firebird):

```bat
isql -user SYSDBA -password SUA_SENHA
SQL> CREATE DATABASE 'localhost:C:\dados\PEDIDOS.FDB' USER 'SYSDBA' PASSWORD 'SUA_SENHA' DEFAULT CHARACTER SET UTF8;
SQL> QUIT;

isql -user SYSDBA -password SUA_SENHA localhost:C:\dados\PEDIDOS.FDB -i db\db.sql
```

A pasta `C:\dados` precisa existir e o servidor Firebird precisa ter permissão de escrita nela. O script cria as tabelas `CLIENTE`, `PRODUTO`, `PEDIDO` e `PEDIDO_ITEM`, o generator `GEN_PEDIDO_NUMERO` (número do pedido), o identity de `PEDIDO_ITEM.ID`, as FKs, os índices e 12 clientes e 12 produtos de exemplo.

Se você já tinha criado o banco antes do campo Observação, rode também `db/migracoes/001_pedido_observacao.sql`.

## 2. Configurar o INI

Copie `config.ini.example` para `config.ini` na raiz do projeto e ajuste:

```ini
[Database]
Database=C:\dados\PEDIDOS.FDB
Username=SYSDBA
Password=SUA_SENHA
Server=localhost
Port=3050
ClientLibrary=bin\Win32\fbclient.dll
```

`ClientLibrary` pode ser relativo à pasta do `config.ini` ou absoluto. O `config.ini` está no `.gitignore`, então a senha real nunca vai para o repositório.

## 3. Executar

1. Abra `src/PedidoVenda.dpr` no Delphi.
2. Plataforma Windows 32 bits (ou 64, ajustando o `ClientLibrary`), `Build` e `Run`.
3. O programa procura o `config.ini` subindo pastas a partir do executável, então funciona rodando de `Win32\Debug` ou de qualquer subpasta do projeto.

## Roteiro rápido de testes manuais

1. **Cliente inexistente:** digite `999` no código do cliente e saia do campo. Aparece "Cliente 999 não encontrado." em vermelho e os campos ficam vazios.
2. **Cliente válido:** digite `1`. Aparecem nome, cidade e UF.
3. **Inserir item:** código de produto `1`. A descrição e o preço (39,90) são preenchidos. Quantidade `2` e clique em **Inserir Item**. O grid mostra 1 linha e o total fica R$ 79,80.
4. **Produto repetido:** insira de novo o produto `1` com quantidade `1`. Ficam 2 linhas e o total vai a R$ 119,70.
5. **Editar com ENTER:** selecione a linha 1 no grid e tecle ENTER. Os campos são carregados e o botão vira "Atualizar Item". Mude a quantidade para `3` e clique no botão. A linha e o total são atualizados.
6. **Excluir com DEL:** selecione uma linha e tecle DEL. Confirme em "Sim". A linha some e o **total é recalculado na hora**. Repita e responda "Não" para ver que nada muda.
7. **Observação:** escreva "Entrega na parte da manhã" no campo Observação.
8. **Gravar:** clique em **Gravar Pedido**. A mensagem mostra o número gerado (1, 2, 3...). Confira no banco:
   ```sql
   SELECT * FROM PEDIDO;
   SELECT * FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = 1;
   ```
9. **Validações:** tente gravar sem cliente ou sem itens. A tela avisa e nada é gravado.
10. **Carregar Pedido:** clique em **Carregar Pedido**, informe o número gravado. Cabeçalho (com observação) e itens voltam para a tela. Altere e grave de novo: o pedido é atualizado, sem criar outro número.
11. **Cancelar Pedido:** com o pedido carregado, clique em **Cancelar Pedido** e confirme. Pedido e itens são excluídos (confira no banco).
12. **Rollback:** para ver a transação funcionando, pare o serviço do Firebird com a tela aberta e tente gravar. A mensagem de erro aparece e o banco permanece intacto.

## Testes unitários (DUnitX)

Abra `tests/PedidoVenda.Tests.dpr`, compile e execute. Os testes cobrem soma dos itens, produtos repetidos, arredondamento em centavos, exclusão com recálculo do total e validações de quantidade e valor. Eles não precisam de banco.

## Decisões técnicas

- **Total sempre calculado:** `TPedido.ValorTotal` soma os itens a cada leitura. Não existe total armazenado em memória que possa ficar desatualizado depois de excluir ou editar um item.
- **Transação:** `Gravar` e `Excluir` abrem transação, fazem commit no fim e rollback em qualquer erro. Se o número do pedido foi sorteado e a gravação falhou, o número volta ao valor anterior no objeto.
- **Índices:** os três índices pedidos são criados junto com as FKs (cláusula `USING INDEX`), assim o Firebird não cria índices duplicados.
- **Itens com `ON DELETE CASCADE`:** excluir um pedido apaga seus itens mesmo fora da aplicação.
- **Conexão por INI:** a conexão FireDAC é montada em tempo de execução a partir do INI, incluindo o `VendorLib` do `fbclient.dll`.
- **Mensagens na tela:** erros de validação aparecem em uma linha vermelha no topo, sem diálogos que travem o fluxo de digitação.
