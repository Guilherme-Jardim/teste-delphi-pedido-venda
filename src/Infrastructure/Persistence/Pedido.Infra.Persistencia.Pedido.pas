unit Pedido.Infra.Persistencia.Pedido;

{ Repositório do agregado Pedido (FireDAC): grava e carrega o pedido inteiro
  (cabeçalho + itens) em uma única transação. }

interface

uses
  Pedido.Domain.Pedido,
  Pedido.Domain.Repositorios,
  Pedido.Infra.Persistencia.Base;

type
  TPedidoRepositorioFireDAC = class(TRepositorioFireDACBase, IPedidoRepository)
  private
    function ProximoNumero: Integer;
    procedure InserirCabecalho(APedido: TPedido);
    procedure AtualizarCabecalho(APedido: TPedido);
    procedure ExcluirItens(ANumero: Integer);
    procedure InserirItens(APedido: TPedido);
    procedure CarregarItens(APedido: TPedido);
  public
    procedure Salvar(APedido: TPedido);
    function ObterPorNumero(ANumero: Integer): TPedido;
    procedure Excluir(ANumero: Integer);
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  Pedido.Domain.Erros,
  Pedido.Domain.ObjetosValor,
  Pedido.Domain.PedidoItem,
  Pedido.Infra.Log;

const
  SQL_PROXIMO_NUMERO =
    'SELECT NEXT VALUE FOR GEN_PEDIDO_NUMERO AS NUMERO FROM RDB$DATABASE';

  SQL_INSERIR_CABECALHO =
    'INSERT INTO PEDIDO (NUMERO_PEDIDO, DATA_EMISSAO, CODIGO_CLIENTE, VALOR_TOTAL, ' +
    'OBSERVACAO) ' +
    'VALUES (:NUMERO, :DATA_EMISSAO, :CODIGO_CLIENTE, :VALOR_TOTAL, :OBSERVACAO)';

  SQL_ATUALIZAR_CABECALHO =
    'UPDATE PEDIDO SET DATA_EMISSAO = :DATA_EMISSAO, ' +
    'CODIGO_CLIENTE = :CODIGO_CLIENTE, VALOR_TOTAL = :VALOR_TOTAL, ' +
    'OBSERVACAO = :OBSERVACAO ' +
    'WHERE NUMERO_PEDIDO = :NUMERO';

  SQL_EXCLUIR_ITENS =
    'DELETE FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = :NUMERO';

  SQL_INSERIR_ITEM =
    'INSERT INTO PEDIDO_ITEM (NUMERO_PEDIDO, CODIGO_PRODUTO, QUANTIDADE, ' +
    'VLR_UNITARIO, VLR_TOTAL) ' +
    'VALUES (:NUMERO, :CODIGO_PRODUTO, :QUANTIDADE, :VLR_UNITARIO, :VLR_TOTAL)';

  SQL_BUSCAR_CABECALHO =
    'SELECT NUMERO_PEDIDO, DATA_EMISSAO, CODIGO_CLIENTE, VALOR_TOTAL, OBSERVACAO ' +
    'FROM PEDIDO WHERE NUMERO_PEDIDO = :NUMERO';

  SQL_BUSCAR_ITENS =
    'SELECT I.CODIGO_PRODUTO, P.DESCRICAO, I.QUANTIDADE, I.VLR_UNITARIO ' +
    'FROM PEDIDO_ITEM I ' +
    'JOIN PRODUTO P ON P.CODIGO = I.CODIGO_PRODUTO ' +
    'WHERE I.NUMERO_PEDIDO = :NUMERO ' +
    'ORDER BY I.ID';

  SQL_EXCLUIR_PEDIDO =
    'DELETE FROM PEDIDO WHERE NUMERO_PEDIDO = :NUMERO';

{ TPedidoRepositorioFireDAC }

function TPedidoRepositorioFireDAC.ProximoNumero: Integer;
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_PROXIMO_NUMERO);
  try
    Query.Open;
    Result := Query.FieldByName('NUMERO').AsInteger;
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.InserirCabecalho(APedido: TPedido);
var
  Query: TFDQuery;
begin
  APedido.Numero := ProximoNumero;
  Query := NovaQuery(SQL_INSERIR_CABECALHO);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.ParamByName('DATA_EMISSAO').AsDate := APedido.DataEmissao;
    Query.ParamByName('CODIGO_CLIENTE').AsInteger := APedido.CodigoCliente;
    Query.ParamByName('VALOR_TOTAL').AsCurrency := APedido.ValorTotal.Valor;
    Query.ParamByName('OBSERVACAO').AsString := APedido.Observacao;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.AtualizarCabecalho(APedido: TPedido);
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_ATUALIZAR_CABECALHO);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.ParamByName('DATA_EMISSAO').AsDate := APedido.DataEmissao;
    Query.ParamByName('CODIGO_CLIENTE').AsInteger := APedido.CodigoCliente;
    Query.ParamByName('VALOR_TOTAL').AsCurrency := APedido.ValorTotal.Valor;
    Query.ParamByName('OBSERVACAO').AsString := APedido.Observacao;
    Query.ExecSQL;
    if Query.RowsAffected = 0 then
      raise EDominioErro.Create(cePedidoNaoEncontrado, APedido.Numero);
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.ExcluirItens(ANumero: Integer);
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_EXCLUIR_ITENS);
  try
    Query.ParamByName('NUMERO').AsInteger := ANumero;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.InserirItens(APedido: TPedido);
var
  Query: TFDQuery;
  Item: TPedidoItem;
begin
  Query := NovaQuery(SQL_INSERIR_ITEM);
  try
    for Item in APedido.Itens do
    begin
      Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
      Query.ParamByName('CODIGO_PRODUTO').AsInteger := Item.CodigoProduto;
      Query.ParamByName('QUANTIDADE').AsFloat := Item.Quantidade.Valor;
      Query.ParamByName('VLR_UNITARIO').AsCurrency := Item.VlrUnitario.Valor;
      Query.ParamByName('VLR_TOTAL').AsCurrency := Item.VlrTotal.Valor;
      Query.ExecSQL;
    end;
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.Salvar(APedido: TPedido);
var
  NumeroOriginal: Integer;
begin
  NumeroOriginal := APedido.Numero;
  FConexao.StartTransaction;
  try
    if APedido.Numero = 0 then
      InserirCabecalho(APedido)
    else
    begin
      AtualizarCabecalho(APedido);
      ExcluirItens(APedido.Numero);
    end;
    InserirItens(APedido);
    FConexao.Commit;
  except
    on E: Exception do
    begin
      if FConexao.InTransaction then
        FConexao.Rollback;
      // Se o número foi sorteado dentro da transação, volta ao estado anterior.
      APedido.Numero := NumeroOriginal;
      if E is EDominioErro then
        raise;
      RegistrarLog('Falha ao gravar o pedido', E);
      raise EDominioErro.Create(ceFalhaAoGravar);
    end;
  end;
end;

procedure TPedidoRepositorioFireDAC.CarregarItens(APedido: TPedido);
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_BUSCAR_ITENS);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.Open;
    while not Query.Eof do
    begin
      APedido.AdicionarItem(TPedidoItem.Create(
        Query.FieldByName('CODIGO_PRODUTO').AsInteger,
        Query.FieldByName('DESCRICAO').AsString,
        TQuantidade.Criar(Query.FieldByName('QUANTIDADE').AsFloat),
        TDinheiro.DeResultado(Query.FieldByName('VLR_UNITARIO').AsCurrency)));
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TPedidoRepositorioFireDAC.ObterPorNumero(ANumero: Integer): TPedido;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := NovaQuery(SQL_BUSCAR_CABECALHO);
  try
    Query.ParamByName('NUMERO').AsInteger := ANumero;
    Query.Open;
    if Query.IsEmpty then
      Exit;

    Result := TPedido.Create;
    try
      Result.Numero := Query.FieldByName('NUMERO_PEDIDO').AsInteger;
      Result.DataEmissao := Query.FieldByName('DATA_EMISSAO').AsDateTime;
      Result.InformarCliente(Query.FieldByName('CODIGO_CLIENTE').AsInteger);
      Result.DefinirObservacao(Query.FieldByName('OBSERVACAO').AsString);
      CarregarItens(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure TPedidoRepositorioFireDAC.Excluir(ANumero: Integer);
var
  Query: TFDQuery;
begin
  FConexao.StartTransaction;
  try
    ExcluirItens(ANumero);
    Query := NovaQuery(SQL_EXCLUIR_PEDIDO);
    try
      Query.ParamByName('NUMERO').AsInteger := ANumero;
      Query.ExecSQL;
      if Query.RowsAffected = 0 then
        raise EDominioErro.Create(cePedidoNaoEncontrado, ANumero);
    finally
      Query.Free;
    end;
    FConexao.Commit;
  except
    on E: Exception do
    begin
      if FConexao.InTransaction then
        FConexao.Rollback;
      if E is EDominioErro then
        raise;
      RegistrarLog('Falha ao cancelar o pedido', E);
      raise EDominioErro.Create(ceFalhaAoCancelar);
    end;
  end;
end;

end.
