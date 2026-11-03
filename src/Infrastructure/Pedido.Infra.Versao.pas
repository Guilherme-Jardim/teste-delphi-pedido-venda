unit Pedido.Infra.Versao;

{ Versão do aplicativo, lida das informações de versão do próprio executável
  (as mesmas que aparecem em Propriedades > Detalhes). O número é definido uma
  vez só, nas opções do projeto, e segue versionamento semântico: MAIOR.MENOR.CORREÇÃO. }

interface

type
  TVersaoAplicacao = record
    Maior: Word;
    Menor: Word;
    Correcao: Word;
    Compilacao: Word;
    // "1.1.0"
    function Resumida: string;
    // "1.1.0.0"
    function Completa: string;
  end;

// Monta a versão a partir dos quatro números.
function CriarVersao(AMaior, AMenor, ACorrecao, ACompilacao: Word): TVersaoAplicacao;

// Interpreta um texto como "1.2.3" ou "1.2.3.4". Devolve False se o texto não for uma versão.
function TentarLerVersao(const ATexto: string; out AVersao: TVersaoAplicacao): Boolean;

// Versão do executável em execução (0.0.0.0 se o executável não tiver informações de versão).
function VersaoDoExecutavel: TVersaoAplicacao;

implementation

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows;

function TVersaoAplicacao.Resumida: string;
begin
  Result := Format('%d.%d.%d', [Maior, Menor, Correcao]);
end;

function TVersaoAplicacao.Completa: string;
begin
  Result := Format('%d.%d.%d.%d', [Maior, Menor, Correcao, Compilacao]);
end;

function CriarVersao(AMaior, AMenor, ACorrecao, ACompilacao: Word): TVersaoAplicacao;
begin
  Result.Maior := AMaior;
  Result.Menor := AMenor;
  Result.Correcao := ACorrecao;
  Result.Compilacao := ACompilacao;
end;

function TentarLerVersao(const ATexto: string; out AVersao: TVersaoAplicacao): Boolean;
var
  Partes: TArray<string>;
  Numeros: array[0..3] of Integer;
  I: Integer;
begin
  Result := False;
  AVersao := CriarVersao(0, 0, 0, 0);
  Partes := Trim(ATexto).Split(['.']);
  if (Length(Partes) < 3) or (Length(Partes) > 4) then
    Exit;
  FillChar(Numeros, SizeOf(Numeros), 0);
  for I := 0 to High(Partes) do
    if not TryStrToInt(Partes[I], Numeros[I]) or (Numeros[I] < 0) or (Numeros[I] > High(Word)) then
      Exit;
  AVersao := CriarVersao(Numeros[0], Numeros[1], Numeros[2], Numeros[3]);
  Result := True;
end;

function VersaoDoExecutavel: TVersaoAplicacao;
var
  Caminho: string;
  Tamanho, Ignorado: DWORD;
  Buffer: TBytes;
  Info: PVSFixedFileInfo;
  TamanhoInfo: UINT;
begin
  Result := CriarVersao(0, 0, 0, 0);
  Caminho := ParamStr(0);
  Tamanho := GetFileVersionInfoSize(PChar(Caminho), Ignorado);
  if Tamanho = 0 then
    Exit;
  SetLength(Buffer, Tamanho);
  if not GetFileVersionInfo(PChar(Caminho), 0, Tamanho, Buffer) then
    Exit;
  if VerQueryValue(Buffer, '\', Pointer(Info), TamanhoInfo) and (Info <> nil) then
    Result := CriarVersao(HiWord(Info^.dwFileVersionMS), LoWord(Info^.dwFileVersionMS),
      HiWord(Info^.dwFileVersionLS), LoWord(Info^.dwFileVersionLS));
end;

end.
