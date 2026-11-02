/* Evolucao: campo Observacao no cabecalho do pedido.
   Para bancos criados antes desta alteracao (o db.sql novo ja cria a coluna). */

ALTER TABLE PEDIDO ADD OBSERVACAO VARCHAR(200);

COMMIT;
