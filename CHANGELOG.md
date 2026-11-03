# Changelog

Todas as mudanças importantes deste projeto ficam registradas aqui.
O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto usa [versionamento semântico](https://semver.org/lang/pt-BR/).

A versão do aplicativo é definida uma vez, nas opções do projeto (Versão do aplicativo → Informações de versão), e aparece na tela principal, nas propriedades do `.exe` e no log.

## [Não lançado]

## [1.2.0] - 2026-11-03

Clean Architecture e DDD.

### Alterado
- O código foi reorganizado em quatro camadas: `Domain`, `Application`, `Infrastructure` e `Presentation`, com as dependências apontando para dentro.
- `Model`, `Controller` e `DAO` deram lugar a entidades e agregado no domínio, casos de uso na aplicação e repositórios FireDAC na infraestrutura.
- Os erros de negócio passam a ter um código (`EDominioErro`) e a tela os traduz para o idioma escolhido.

### Adicionado
- Objetos de valor `TQuantidade` e `TDinheiro`, imutáveis e sempre válidos.
- `TPedido` como raiz de agregado, com regras de gravação e da observação dentro dele.
- Interfaces dos repositórios no domínio e um caso de uso para cada ação (consultar cliente, consultar produto, criar item, gravar, carregar e cancelar).
- Eventos de domínio `PedidoGravado` e `PedidoCancelado`, com publicador em memória e assinante que registra no log.
- 40 testes novos (259 no total): domínio, eventos e casos de uso.

## [1.1.0] - 2026-11-03

Inicialização automática, SOLID e segurança.

### Adicionado
- Criação automática do `config.ini` e do banco de dados na primeira execução, com tela de configuração (servidor, porta, usuário, senha, biblioteca e caminho do banco).
- Pasta do banco à escolha: seletor de pasta, pasta do programa ou pasta padrão.
- Tratamento de cada situação ao abrir: INI ausente ou corrompido (com cópia de segurança), banco que sumiu depois de criado (pergunta antes de criar outro), banco vazio, banco de outro sistema, estrutura desatualizada, servidor parado, senha recusada e `fbclient.dll` ausente ou com bits errados.
- Validação de tudo que vem de fora (servidor, porta, caminho, usuário, senha, biblioteca).
- Versão do aplicativo no executável, na tela principal e no log.
- Grupo de projetos `pedidoVendaProjectGroup` com o aplicativo, o pacote de componentes e os testes.
- 219 testes automatizados, incluindo cenários com Firebird real.

### Alterado
- Controllers e DAOs passam a depender de interfaces, com injeção de dependências por construtor e raiz de composição (SOLID).
- O script de criação do banco fica embutido no executável e continua igual ao `db/db.sql` (conferido por teste).
- README com as duas formas de criar o banco, os cenários de inicialização e o roteiro de testes atualizado.

## [1.0.0] - 2026-11-02

Primeira entrega, com tudo que o teste técnico pede e os bônus.

### Adicionado
- Tela de Pedido de Venda: cliente por código, itens com produto repetido, grade com ENTER (editar) e DEL (excluir com confirmação) e total no rodapé.
- Gravação do pedido em transação (commit ou rollback) e campo Observação.
- Total recalculado na hora ao excluir um item.
- Carregar pedido por número e cancelar pedido (exclui pedido e itens em transação).
- `db.sql` com tabelas, generator, identity, FKs, índices e carga de teste; `config.ini.example`.
- Pacote de componentes visuais próprio (`Componentes.Pedido`) e interface toda no `.dfm`.
- Português (padrão) e espanhol, com troca pelas bandeiras.
- Atalhos de teclado, dicas nos campos e contraste conferido.
- Testes DUnitX (totalização, validação, idioma, controller e integração com o Firebird).

[Não lançado]: https://github.com/Guilherme-Jardim/teste-delphi-pedido-venda/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Guilherme-Jardim/teste-delphi-pedido-venda/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Guilherme-Jardim/teste-delphi-pedido-venda/releases/tag/v1.0.0
