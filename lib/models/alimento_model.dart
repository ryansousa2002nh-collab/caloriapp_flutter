class Alimento {
  final String id;
  final String nome;
  final String categoria;
  final int caloriasPor100g;
  final double proteinasPor100g;
  final double carboidratosPor100g;
  final double gordurasPor100g;
  final String porcaoSugerida;

  const Alimento({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.caloriasPor100g,
    this.proteinasPor100g = 0,
    this.carboidratosPor100g = 0,
    this.gordurasPor100g = 0,
    this.porcaoSugerida = '100g',
  });

  int calcularCalorias(double gramas) {
    if (gramas <= 0) return 0;
    return ((caloriasPor100g * gramas) / 100).round();
  }
}

// Banco de dados nutricional rico baseado em alimentos populares no Brasil
class BancoAlimentos {
  static const List<Alimento> lista = [
    // Proteínas
    Alimento(
      id: 'frango_grelhado',
      nome: 'Frango grelhado (peito)',
      categoria: 'Proteínas',
      caloriasPor100g: 165,
      proteinasPor100g: 31.0,
      carboidratosPor100g: 0.0,
      gordurasPor100g: 3.6,
      porcaoSugerida: '100g (1 filé médio)',
    ),
    Alimento(
      id: 'ovo_cozido',
      nome: 'Ovo cozido',
      categoria: 'Proteínas',
      caloriasPor100g: 143,
      proteinasPor100g: 13.0,
      carboidratosPor100g: 0.8,
      gordurasPor100g: 9.5,
      porcaoSugerida: '50g (1 unidade grande)',
    ),
    Alimento(
      id: 'clara_ovo',
      nome: 'Clara de ovo cozida',
      categoria: 'Proteínas',
      caloriasPor100g: 52,
      proteinasPor100g: 11.0,
      carboidratosPor100g: 0.7,
      gordurasPor100g: 0.2,
      porcaoSugerida: '30g (1 clara)',
    ),
    Alimento(
      id: 'carne_patinho',
      nome: 'Carne bovina (Patinho)',
      categoria: 'Proteínas',
      caloriasPor100g: 219,
      proteinasPor100g: 35.9,
      carboidratosPor100g: 0.0,
      gordurasPor100g: 7.3,
      porcaoSugerida: '100g (1 bife)',
    ),
    Alimento(
      id: 'carne_moida',
      nome: 'Carne moída magra refogada',
      categoria: 'Proteínas',
      caloriasPor100g: 212,
      proteinasPor100g: 27.0,
      carboidratosPor100g: 0.0,
      gordurasPor100g: 11.0,
      porcaoSugerida: '100g (4 colheres)',
    ),
    Alimento(
      id: 'peixe_tilapia',
      nome: 'Filé de tilápia grelhado',
      categoria: 'Proteínas',
      caloriasPor100g: 128,
      proteinasPor100g: 26.0,
      carboidratosPor100g: 0.0,
      gordurasPor100g: 2.7,
      porcaoSugerida: '100g (1 filé)',
    ),
    Alimento(
      id: 'whey_protein',
      nome: 'Whey Protein (concentrado/isolado)',
      categoria: 'Suplementos',
      caloriasPor100g: 400,
      proteinasPor100g: 80.0,
      carboidratosPor100g: 6.0,
      gordurasPor100g: 5.0,
      porcaoSugerida: '30g (1 dosador)',
    ),

    // Carboidratos & Grãos
    Alimento(
      id: 'arroz_branco',
      nome: 'Arroz branco cozido',
      categoria: 'Carboidratos',
      caloriasPor100g: 130,
      proteinasPor100g: 2.5,
      carboidratosPor100g: 28.2,
      gordurasPor100g: 0.2,
      porcaoSugerida: '100g (4 colheres de sopa)',
    ),
    Alimento(
      id: 'arroz_integral',
      nome: 'Arroz integral cozido',
      categoria: 'Carboidratos',
      caloriasPor100g: 124,
      proteinasPor100g: 2.6,
      carboidratosPor100g: 25.8,
      gordurasPor100g: 1.0,
      porcaoSugerida: '100g (4 colheres de sopa)',
    ),
    Alimento(
      id: 'feijao_carioca',
      nome: 'Feijão carioca cozido',
      categoria: 'Leguminosas',
      caloriasPor100g: 76,
      proteinasPor100g: 4.8,
      carboidratosPor100g: 13.6,
      gordurasPor100g: 0.5,
      porcaoSugerida: '100g (1 concha média)',
    ),
    Alimento(
      id: 'feijao_preto',
      nome: 'Feijão preto cozido',
      categoria: 'Leguminosas',
      caloriasPor100g: 77,
      proteinasPor100g: 4.5,
      carboidratosPor100g: 14.0,
      gordurasPor100g: 0.5,
      porcaoSugerida: '100g (1 concha média)',
    ),
    Alimento(
      id: 'pao_frances',
      nome: 'Pão francês',
      categoria: 'Pães & Massas',
      caloriasPor100g: 270,
      proteinasPor100g: 9.0,
      carboidratosPor100g: 58.0,
      gordurasPor100g: 1.0,
      porcaoSugerida: '50g (1 unidade)',
    ),
    Alimento(
      id: 'pao_integral',
      nome: 'Pão de forma integral',
      categoria: 'Pães & Massas',
      caloriasPor100g: 247,
      proteinasPor100g: 9.4,
      carboidratosPor100g: 47.0,
      gordurasPor100g: 2.5,
      porcaoSugerida: '50g (2 fatias)',
    ),
    Alimento(
      id: 'tapioca',
      nome: 'Goma de tapioca hidratada',
      categoria: 'Carboidratos',
      caloriasPor100g: 240,
      proteinasPor100g: 0.0,
      carboidratosPor100g: 60.0,
      gordurasPor100g: 0.0,
      porcaoSugerida: '50g (2 colheres de sopa cheias)',
    ),
    Alimento(
      id: 'batata_doce',
      nome: 'Batata doce cozida',
      categoria: 'Tubérculos',
      caloriasPor100g: 77,
      proteinasPor100g: 0.6,
      carboidratosPor100g: 18.4,
      gordurasPor100g: 0.1,
      porcaoSugerida: '100g (1 pedaço médio)',
    ),
    Alimento(
      id: 'batata_inglesa',
      nome: 'Batata inglesa cozida',
      categoria: 'Tubérculos',
      caloriasPor100g: 52,
      proteinasPor100g: 1.2,
      carboidratosPor100g: 11.9,
      gordurasPor100g: 0.1,
      porcaoSugerida: '100g (1 unidade média)',
    ),
    Alimento(
      id: 'macarrao_cozido',
      nome: 'Macarrão cozido',
      categoria: 'Pães & Massas',
      caloriasPor100g: 158,
      proteinasPor100g: 5.8,
      carboidratosPor100g: 30.7,
      gordurasPor100g: 0.9,
      porcaoSugerida: '100g (1 prato raso)',
    ),
    Alimento(
      id: 'aveia_flocos',
      nome: 'Aveia em flocos',
      categoria: 'Cereais',
      caloriasPor100g: 389,
      proteinasPor100g: 14.0,
      carboidratosPor100g: 66.0,
      gordurasPor100g: 8.5,
      porcaoSugerida: '30g (2 colheres de sopa)',
    ),

    // Frutas
    Alimento(
      id: 'banana_prata',
      nome: 'Banana prata',
      categoria: 'Frutas',
      caloriasPor100g: 89,
      proteinasPor100g: 1.1,
      carboidratosPor100g: 22.8,
      gordurasPor100g: 0.3,
      porcaoSugerida: '70g (1 unidade média)',
    ),
    Alimento(
      id: 'maca',
      nome: 'Maçã com casca',
      categoria: 'Frutas',
      caloriasPor100g: 52,
      proteinasPor100g: 0.3,
      carboidratosPor100g: 13.8,
      gordurasPor100g: 0.2,
      porcaoSugerida: '120g (1 unidade)',
    ),
    Alimento(
      id: 'mamao_papaia',
      nome: 'Mamão papaia',
      categoria: 'Frutas',
      caloriasPor100g: 40,
      proteinasPor100g: 0.5,
      carboidratosPor100g: 10.4,
      gordurasPor100g: 0.1,
      porcaoSugerida: '150g (metade de 1 unidade)',
    ),
    Alimento(
      id: 'morango',
      nome: 'Morango fresco',
      categoria: 'Frutas',
      caloriasPor100g: 30,
      proteinasPor100g: 0.7,
      carboidratosPor100g: 6.8,
      gordurasPor100g: 0.3,
      porcaoSugerida: '100g (6 a 8 morangos)',
    ),
    Alimento(
      id: 'abacate',
      nome: 'Abacate',
      categoria: 'Frutas',
      caloriasPor100g: 96,
      proteinasPor100g: 1.2,
      carboidratosPor100g: 6.0,
      gordurasPor100g: 8.4,
      porcaoSugerida: '100g (2 colheres de sopa)',
    ),

    // Laticínios & Gorduras
    Alimento(
      id: 'leite_integral',
      nome: 'Leite integral',
      categoria: 'Laticínios',
      caloriasPor100g: 61,
      proteinasPor100g: 3.2,
      carboidratosPor100g: 4.8,
      gordurasPor100g: 3.2,
      porcaoSugerida: '200ml (1 copo)',
    ),
    Alimento(
      id: 'leite_desnatado',
      nome: 'Leite desnatado',
      categoria: 'Laticínios',
      caloriasPor100g: 35,
      proteinasPor100g: 3.4,
      carboidratosPor100g: 5.0,
      gordurasPor100g: 0.1,
      porcaoSugerida: '200ml (1 copo)',
    ),
    Alimento(
      id: 'iogurte_natural',
      nome: 'Iogurte natural desnatado',
      categoria: 'Laticínios',
      caloriasPor100g: 41,
      proteinasPor100g: 3.8,
      carboidratosPor100g: 5.8,
      gordurasPor100g: 0.3,
      porcaoSugerida: '160g (1 pote)',
    ),
    Alimento(
      id: 'queijo_minas',
      nome: 'Queijo minas frescal',
      categoria: 'Laticínios',
      caloriasPor100g: 228,
      proteinasPor100g: 17.4,
      carboidratosPor100g: 3.2,
      gordurasPor100g: 16.0,
      porcaoSugerida: '30g (1 fatia média)',
    ),
    Alimento(
      id: 'queijo_mussarela',
      nome: 'Queijo mussarela',
      categoria: 'Laticínios',
      caloriasPor100g: 280,
      proteinasPor100g: 22.0,
      carboidratosPor100g: 2.0,
      gordurasPor100g: 21.0,
      porcaoSugerida: '30g (1 fatia)',
    ),
    Alimento(
      id: 'pasta_amendoim',
      nome: 'Pasta de amendoim integral',
      categoria: 'Gorduras Saudáveis',
      caloriasPor100g: 588,
      proteinasPor100g: 25.0,
      carboidratosPor100g: 20.0,
      gordurasPor100g: 50.0,
      porcaoSugerida: '20g (1 colher de sopa)',
    ),
    Alimento(
      id: 'azeite_oliva',
      nome: 'Azeite de oliva extravirgem',
      categoria: 'Gorduras Saudáveis',
      caloriasPor100g: 884,
      proteinasPor100g: 0.0,
      carboidratosPor100g: 0.0,
      gordurasPor100g: 100.0,
      porcaoSugerida: '8g (1 colher de sobremesa)',
    ),
    Alimento(
      id: 'castanha_caju',
      nome: 'Castanha de caju torrada',
      categoria: 'Oleaginosas',
      caloriasPor100g: 574,
      proteinasPor100g: 18.2,
      carboidratosPor100g: 30.2,
      gordurasPor100g: 43.8,
      porcaoSugerida: '15g (5 unidades)',
    ),
  ];

  static Alimento? buscarPorNome(String nome) {
    try {
      return lista.firstWhere((a) => a.nome.toLowerCase() == nome.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static int buscarCaloriasPor100g(String nome) {
    final alimento = buscarPorNome(nome);
    return alimento?.caloriasPor100g ?? 0;
  }
}
