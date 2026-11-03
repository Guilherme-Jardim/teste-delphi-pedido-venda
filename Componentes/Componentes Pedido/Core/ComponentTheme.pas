unit ComponentTheme;

{ Paleta e fontes usadas por todos os componentes da interface.
  Cores no formato TColor ($00BBGGRR). Os pares de texto e fundo foram conferidos
  para ter contraste mínimo de 4,5:1 (WCAG AA). }

interface

uses
  Vcl.Graphics;

const
  CorFundo = TColor($00F6F4F3);
  CorCartao = TColor($00FFFFFF);
  CorBorda = TColor($00EBE7E5);
  CorBordaForte = TColor($00DBD5D1);
  CorTexto = TColor($00271811);
  CorTextoSuave = TColor($0063554B);   // 4B5563: contraste 6,9:1 sobre o fundo
  CorTopo = TColor($002A170F);
  CorTopoTextoSuave = TColor($00B8A394);

  CorPrimaria = TColor($00EB6325);
  CorPrimariaHover = TColor($00D84E1D);
  CorPrimariaPress = TColor($00AF401E);
  CorPrimariaSuave = TColor($00FEEADB);

  CorPerigo = TColor($001C1CB9);        // B91C1C: 5,3:1 sobre o rosa claro
  CorPerigoHover = TColor($001B1B99);
  CorPerigoSuave = TColor($00E2E2FE);

  CorSucesso = TColor($00346516);       // 166534: 6,5:1 sobre o verde claro
  CorSucessoSuave = TColor($00E7FCDC);

  CorCampoFundo = TColor($00FBFAF9);
  CorZebra = TColor($00FBFAF9);
  CorHover = TColor($00F6F4F3);

  FonteNome = 'Segoe UI';
  FonteNomeNegrito = 'Segoe UI Semibold';

implementation

end.
