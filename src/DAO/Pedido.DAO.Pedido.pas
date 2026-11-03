unit Pedido.DAO.Pedido;

interface

uses
  Pedido.DAO.Base,
  Pedido.Model.Pedido;

type
  TPedidoDAO = class(TDAOBase)
  private
    function ProximoNumero: Integer;
    procedure InserirCabecalho(APedido: TPedidoModel);
    procedure AtualizarCabecalho(APedido: TPedidoModel);
    procedure ExcluirItens(ANumero: Integer);
    procedure InserirItens(APedido: TPedidoModel);
    procedure CarregarItens(APedido: TPedidoModel);
  public
    // Grava cabeçalho e itens na mesma transação (commit ou rollback).
    // Em pedido novo (Numero = 0) o número vem do generator.
    procedure Gravar(APedido: TPedidoModel);
    // Devolve nil quando não existe. Quem chama é dono do objeto.
    function GetPedido(ANumero: Integer): TPedidoModel;
    procedure Excluir(ANumero: Integer);
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Pedido.Infra.Idioma,
  Pedido.Infra.Log,
  Pedido.Model.Excecoes,
  Pedido.Model.PedidoItem;

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

{ TPedidoDAO }

function TPedidoDAO.ProximoNumero: Integer;
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

procedure TPedidoDAO.InserirCabecalho(APedido: TPedidoModel);
var
  Query: TFDQuery;
begin
  APedido.Numero := ProximoNumero;
  Query := NovaQuery(SQL_INSERIR_CABECALHO);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.ParamByName('DATA_EMISSAO').AsDate := APedido.DataEmissao;
    Query.ParamByName('CODIGO_CLIENTE').AsInteger := APedido.CodigoCliente;
    Query.ParamByName('VALOR_TOTAL').AsCurrency := APedido.ValorTotal;
    Query.ParamByName('OBSERVACAO').AsString := APedido.Observacao;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TPedidoDAO.AtualizarCabecalho(APedido: TPedidoModel);
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_ATUALIZAR_CABECALHO);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.ParamByName('DATA_EMISSAO').AsDate := APedido.DataEmissao;
    Query.ParamByName('CODIGO_CLIENTE').AsInteger := APedido.CodigoCliente;
    Query.ParamByName('VALOR_TOTAL').AsCurrency := APedido.ValorTotal;
    Query.ParamByName('OBSERVACAO').AsString := APedido.Observacao;
    Query.ExecSQL;
    if Query.RowsAffected = 0 then
      raise EPedidoNaoEncontrado.Create(APedido.Numero);
  finally
    Query.Free;
  end;
end;

procedure TPedidoDAO.ExcluirItens(ANumero: Integer);
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

procedure TPedidoDAO.InserirItens(APedido: TPedidoModel);
var
  Query: TFDQuery;
  Item: TPedidoItemModel;
begin
  Query := NovaQuery(SQL_INSERIR_ITEM);
  try
    for Item in APedido.Itens do
    begin
      Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
      Query.ParamByName('CODIGO_PRODUTO').AsInteger := Item.CodigoProduto;
      Query.ParamByName('QUANTIDADE').AsFloat := Item.Quantidade;
      Query.ParamByName('VLR_UNITARIO').AsCurrency := Item.VlrUnitario;
      Query.ParamByName('VLR_TOTAL').AsCurrency := Item.VlrTotal;
      Query.ExecSQL;
    end;
  finally
    Query.Free;
  end;
end;

procedure TPedidoDAO.Gravar(APedido: TPedidoModel);
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
      if E is EPedidoErro then
        raise;
      begin
        RegistrarLog('Falha ao gravar o pedido', E);
        raise EPersistencia.Create(Tr('msg.falha_gravar'));
      end;
    end;
  end;
end;

procedure TPedidoDAO.CarregarItens(APedido: TPedidoModel);
var
  Query: TFDQuery;
begin
  Query := NovaQuery(SQL_BUSCAR_ITENS);
  try
    Query.ParamByName('NUMERO').AsInteger := APedido.Numero;
    Query.Open;
    while not Query.Eof do
    begin
      APedido.AdicionarItem(TPedidoItemModel.Create(
        Query.FieldByName('CODIGO_PRODUTO').AsInteger,
        Query.FieldByName('DESCRICAO').AsString,
        Query.FieldByName('QUANTIDADE').AsFloat,
        Query.FieldByName('VLR_UNITARIO').AsCurrency));
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TPedidoDAO.GetPedido(ANumero: Integer): TPedidoModel;
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

    Result := TPedidoModel.Create;
    try
      Result.Numero := Query.FieldByName('NUMERO_PEDIDO').AsInteger;
      Result.DataEmissao := Query.FieldByName('DATA_EMISSAO').AsDateTime;
      Result.CodigoCliente := Query.FieldByName('CODIGO_CLIENTE').AsInteger;
      Result.Observacao := Query.FieldByName('OBSERVACAO').AsString;
      CarregarItens(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure TPedidoDAO.Excluir(ANumero: Integer);
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
        raise EPedidoNaoEncontrado.Create(ANumero);
    finally
      Query.Free;
    end;
    FConexao.Commit;
  except
    on E: Exception do
    begin
      if FConexao.InTransaction then
        FConexao.Rollback;
      if E is EPedidoErro then
        raise;
      begin
        RegistrarLog('Falha ao cancelar o pedido', E);
        raise EPersistencia.Create(Tr('msg.falha_cancelar'));
      end;
    end;
  end;
end;

end.
