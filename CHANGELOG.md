# Changelog

Todas as mudanças importantes deste projeto ficam registradas aqui.
O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto usa [versionamento semântico](https://semver.org/lang/pt-BR/).

A versão do aplicativo é definida uma vez, nas opções do projeto (Versão do aplicativo → Informações de versão), e aparece na tela principal, nas propriedades do `.exe` e no log.

## [Não lançado]

### Adicionado
- Versão do aplicativo no executável, na tela principal e no log.
- Grupo de projetos `pedidoVendaProjectGroup` com o aplicativo, o pacote de componentes e os testes.

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

[Não lançado]: https://github.com/Guilherme-Jardim/teste-delphi-pedido-venda/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Guilherme-Jardim/teste-delphi-pedido-venda/releases/tag/v1.0.0
