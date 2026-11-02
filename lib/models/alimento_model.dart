// Modelo pros metadados de cada micronutriente (pra facilitar listar na tela depois)
class MicronutrienteInfo {
  final String chave;
  final String nome;
  final String simbolo;
  final String unidade;
  final String grupo; // 'Mineral' ou 'Vitamina'
  final double metaDiaria; // meta diária padrão de adulto
  final bool isLimiteMaximo; // pro sódio funcionar ao contrário (não pode passar do limite)
  final String funcaoClinica;

  const MicronutrienteInfo({
    required this.chave,
    required this.nome,
    required this.simbolo,
    required this.unidade,
    required this.grupo,
    required this.metaDiaria,
    this.isLimiteMaximo = false,
    required this.funcaoClinica,
  });
}

class Alimento {
  final String id;
  final String nome;
  final String categoria;
  final int caloriasPor100g;
  final double proteinasPor100g;
  final double carboidratosPor100g;
  final double gordurasPor100g;
  final double fibrasPor100g;

  // Minerais (valores baseados em 100g do alimento)
  final double calcioMgPor100g;
  final double ferroMgPor100g;
  final double zincoMgPor100g;
  final double magnesioMgPor100g;
  final double potassioMgPor100g;
  final double sodioMgPor100g;

  // Vitaminas (valores baseados em 100g do alimento)
  final double vitaminaAMcgPor100g;
  final double vitaminaCMgPor100g;
  final double vitaminaDMcgPor100g;
  final double vitaminaB12McgPor100g;

  final String porcaoSugerida;

  const Alimento({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.caloriasPor100g,
    this.proteinasPor100g = 0,
    this.carboidratosPor100g = 0,
    this.gordurasPor100g = 0,
    this.fibrasPor100g = 0,
    this.calcioMgPor100g = 0,
    this.ferroMgPor100g = 0,
    this.zincoMgPor100g = 0,
    this.magnesioMgPor100g = 0,
    this.potassioMgPor100g = 0,
    this.sodioMgPor100g = 0,
    this.vitaminaAMcgPor100g = 0,
    this.vitaminaCMgPor100g = 0,
    this.vitaminaDMcgPor100g = 0,
    this.vitaminaB12McgPor100g = 0,
    this.porcaoSugerida = '100g',
  });

  int calcularCalorias(double gramas) {
    if (gramas <= 0) return 0;
    return ((caloriasPor100g * gramas) / 100).round();
  }

  /// Identifica se o alimento é líquido (leite, sucos, azeite, etc.) para exibir 'ml' em vez de 'g'
  bool get isLiquido {
    if (porcaoSugerida.toLowerCase().contains('ml')) return true;
    final n = nome.toLowerCase();
    return n.contains('leite') ||
        n.contains('suco') ||
        n.contains('água') ||
        n.contains('agua') ||
        n.contains('café') ||
        n.contains('cafe') ||
        n.contains('chá') ||
        n.contains('cha') ||
        n.contains('azeite') ||
        n.contains('óleo') ||
        n.contains('oleo') ||
        n.contains('iogurte líquido') ||
        n.contains('bebida');
  }

  String get unidadeMedida => isLiquido ? 'ml' : 'g';

  // Pega o valor de qualquer nutriente já calculado pra quantidade em gramas que a nutri colocou
  double valorNutrientePorGramas(String chave, double gramas) {
    if (gramas <= 0) return 0;
    final fator = gramas / 100.0; // regra de 3 simples em cima dos 100g
    switch (chave) {
      case 'calorias':
        return caloriasPor100g * fator;
      case 'proteinas':
        return proteinasPor100g * fator;
      case 'carboidratos':
        return carboidratosPor100g * fator;
      case 'gorduras':
        return gordurasPor100g * fator;
      case 'fibras':
        return fibrasPor100g * fator;
      case 'calcio':
        return calcioMgPor100g * fator;
      case 'ferro':
        return ferroMgPor100g * fator;
      case 'zinco':
        return zincoMgPor100g * fator;
      case 'magnesio':
        return magnesioMgPor100g * fator;
      case 'potassio':
        return potassioMgPor100g * fator;
      case 'sodio':
        return sodioMgPor100g * fator;
      case 'vitamina_a':
        return vitaminaAMcgPor100g * fator;
      case 'vitamina_c':
        return vitaminaCMgPor100g * fator;
      case 'vitamina_d':
        return vitaminaDMcgPor100g * fator;
      case 'vitamina_b12':
        return vitaminaB12McgPor100g * fator;
      default:
        return 0;
    }
  }
}

// Banco de dados nutricional baseado nos alimentos mais comuns (valores médios da tabela TACO)
class BancoAlimentos {
  // Lista fixa dos micronutrientes que vão aparecer na análise da nutri
  static const List<MicronutrienteInfo> catalogoMicronutrientes = [
    // Minerais
    MicronutrienteInfo(
      chave: 'ferro',
      nome: 'Ferro',
      simbolo: 'Fe',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 14.0,
      funcaoClinica: 'Transporte de oxigênio, prevenção de anemia e disposição',
    ),
    MicronutrienteInfo(
      chave: 'calcio',
      nome: 'Cálcio',
      simbolo: 'Ca',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 1000.0,
      funcaoClinica: 'Saúde dos ossos, dentes e contração muscular',
    ),
    MicronutrienteInfo(
      chave: 'zinco',
      nome: 'Zinco',
      simbolo: 'Zn',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 11.0,
      funcaoClinica: 'Imunidade, síntese de proteínas e cicatrização',
    ),
    MicronutrienteInfo(
      chave: 'magnesio',
      nome: 'Magnésio',
      simbolo: 'Mg',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 350.0,
      funcaoClinica: 'Relaxamento muscular, metabolismo e qualidade do sono',
    ),
    MicronutrienteInfo(
      chave: 'potassio',
      nome: 'Potássio',
      simbolo: 'K',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 3500.0,
      funcaoClinica: 'Equilíbrio de líquidos, pressão arterial e músculos',
    ),
    MicronutrienteInfo(
      chave: 'sodio',
      nome: 'Sódio',
      simbolo: 'Na',
      unidade: 'mg',
      grupo: 'Mineral',
      metaDiaria: 2000.0,
      isLimiteMaximo: true,
      funcaoClinica: 'Controle hídrico (ideal manter abaixo de 2000 mg por dia)',
    ),
    // Vitaminas
    MicronutrienteInfo(
      chave: 'vitamina_c',
      nome: 'Vitamina C',
      simbolo: 'Vit C',
      unidade: 'mg',
      grupo: 'Vitamina',
      metaDiaria: 90.0,
      funcaoClinica: 'Antioxidante, produção de colágeno e ajuda a absorver ferro',
    ),
    MicronutrienteInfo(
      chave: 'vitamina_a',
      nome: 'Vitamina A',
      simbolo: 'Vit A',
      unidade: 'mcg',
      grupo: 'Vitamina',
      metaDiaria: 800.0,
      funcaoClinica: 'Visão, saúde da pele e imunidade',
    ),
    MicronutrienteInfo(
      chave: 'vitamina_d',
      nome: 'Vitamina D',
      simbolo: 'Vit D',
      unidade: 'mcg',
      grupo: 'Vitamina',
      metaDiaria: 15.0,
      funcaoClinica: 'Fixação de cálcio nos ossos e sistema imune',
    ),
    MicronutrienteInfo(
      chave: 'vitamina_b12',
      nome: 'Vitamina B12',
      simbolo: 'B12',
      unidade: 'mcg',
      grupo: 'Vitamina',
      metaDiaria: 2.4,
      funcaoClinica: 'Formação do sangue e funcionamento do sistema nervoso',
    ),
  ];

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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 15.0,
      ferroMgPor100g: 1.0,
      zincoMgPor100g: 1.0,
      magnesioMgPor100g: 29.0,
      potassioMgPor100g: 256.0,
      sodioMgPor100g: 74.0,
      vitaminaAMcgPor100g: 6.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.2,
      vitaminaB12McgPor100g: 0.34,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 50.0,
      ferroMgPor100g: 1.8,
      zincoMgPor100g: 1.1,
      magnesioMgPor100g: 10.0,
      potassioMgPor100g: 126.0,
      sodioMgPor100g: 124.0,
      vitaminaAMcgPor100g: 149.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 2.2,
      vitaminaB12McgPor100g: 1.11,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 7.0,
      ferroMgPor100g: 0.1,
      zincoMgPor100g: 0.03,
      magnesioMgPor100g: 11.0,
      potassioMgPor100g: 163.0,
      sodioMgPor100g: 166.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.09,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 5.0,
      ferroMgPor100g: 2.8,
      zincoMgPor100g: 5.8,
      magnesioMgPor100g: 24.0,
      potassioMgPor100g: 340.0,
      sodioMgPor100g: 60.0,
      vitaminaAMcgPor100g: 3.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.1,
      vitaminaB12McgPor100g: 2.6,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 12.0,
      ferroMgPor100g: 2.5,
      zincoMgPor100g: 5.2,
      magnesioMgPor100g: 21.0,
      potassioMgPor100g: 310.0,
      sodioMgPor100g: 72.0,
      vitaminaAMcgPor100g: 4.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.1,
      vitaminaB12McgPor100g: 2.4,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 14.0,
      ferroMgPor100g: 0.7,
      zincoMgPor100g: 0.4,
      magnesioMgPor100g: 34.0,
      potassioMgPor100g: 380.0,
      sodioMgPor100g: 56.0,
      vitaminaAMcgPor100g: 12.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 3.7,
      vitaminaB12McgPor100g: 1.86,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 450.0,
      ferroMgPor100g: 0.8,
      zincoMgPor100g: 2.0,
      magnesioMgPor100g: 60.0,
      potassioMgPor100g: 500.0,
      sodioMgPor100g: 210.0,
      vitaminaAMcgPor100g: 15.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.5,
      vitaminaB12McgPor100g: 2.0,
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
      fibrasPor100g: 1.6,
      calcioMgPor100g: 4.0,
      ferroMgPor100g: 0.3,
      zincoMgPor100g: 0.5,
      magnesioMgPor100g: 12.0,
      potassioMgPor100g: 35.0,
      sodioMgPor100g: 2.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 2.7,
      calcioMgPor100g: 5.0,
      ferroMgPor100g: 0.4,
      zincoMgPor100g: 0.7,
      magnesioMgPor100g: 59.0,
      potassioMgPor100g: 86.0,
      sodioMgPor100g: 4.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 8.5,
      calcioMgPor100g: 27.0,
      ferroMgPor100g: 1.3,
      zincoMgPor100g: 0.7,
      magnesioMgPor100g: 42.0,
      potassioMgPor100g: 255.0,
      sodioMgPor100g: 2.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.8,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 8.4,
      calcioMgPor100g: 29.0,
      ferroMgPor100g: 1.5,
      zincoMgPor100g: 0.8,
      magnesioMgPor100g: 45.0,
      potassioMgPor100g: 280.0,
      sodioMgPor100g: 2.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.5,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 2.3,
      calcioMgPor100g: 19.0,
      ferroMgPor100g: 1.0,
      zincoMgPor100g: 0.8,
      magnesioMgPor100g: 25.0,
      potassioMgPor100g: 142.0,
      sodioMgPor100g: 580.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 6.9,
      calcioMgPor100g: 107.0,
      ferroMgPor100g: 2.4,
      zincoMgPor100g: 1.8,
      magnesioMgPor100g: 75.0,
      potassioMgPor100g: 248.0,
      sodioMgPor100g: 400.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 0.4,
      calcioMgPor100g: 15.0,
      ferroMgPor100g: 0.9,
      zincoMgPor100g: 0.1,
      magnesioMgPor100g: 3.0,
      potassioMgPor100g: 18.0,
      sodioMgPor100g: 5.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 2.2,
      calcioMgPor100g: 17.0,
      ferroMgPor100g: 0.4,
      zincoMgPor100g: 0.2,
      magnesioMgPor100g: 18.0,
      potassioMgPor100g: 230.0,
      sodioMgPor100g: 9.0,
      vitaminaAMcgPor100g: 380.0,
      vitaminaCMgPor100g: 23.8,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 1.3,
      calcioMgPor100g: 4.0,
      ferroMgPor100g: 0.2,
      zincoMgPor100g: 0.2,
      magnesioMgPor100g: 15.0,
      potassioMgPor100g: 328.0,
      sodioMgPor100g: 4.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 13.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 1.8,
      calcioMgPor100g: 7.0,
      ferroMgPor100g: 1.3,
      zincoMgPor100g: 0.5,
      magnesioMgPor100g: 18.0,
      potassioMgPor100g: 44.0,
      sodioMgPor100g: 6.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 9.1,
      calcioMgPor100g: 48.0,
      ferroMgPor100g: 4.4,
      zincoMgPor100g: 2.6,
      magnesioMgPor100g: 119.0,
      potassioMgPor100g: 336.0,
      sodioMgPor100g: 5.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 2.0,
      calcioMgPor100g: 8.0,
      ferroMgPor100g: 0.4,
      zincoMgPor100g: 0.2,
      magnesioMgPor100g: 26.0,
      potassioMgPor100g: 358.0,
      sodioMgPor100g: 1.0,
      vitaminaAMcgPor100g: 8.0,
      vitaminaCMgPor100g: 21.6,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 2.4,
      calcioMgPor100g: 6.0,
      ferroMgPor100g: 0.1,
      zincoMgPor100g: 0.04,
      magnesioMgPor100g: 5.0,
      potassioMgPor100g: 107.0,
      sodioMgPor100g: 1.0,
      vitaminaAMcgPor100g: 3.0,
      vitaminaCMgPor100g: 4.6,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 1.8,
      calcioMgPor100g: 22.0,
      ferroMgPor100g: 0.2,
      zincoMgPor100g: 0.1,
      magnesioMgPor100g: 17.0,
      potassioMgPor100g: 182.0,
      sodioMgPor100g: 3.0,
      vitaminaAMcgPor100g: 47.0,
      vitaminaCMgPor100g: 82.2,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 1.7,
      calcioMgPor100g: 16.0,
      ferroMgPor100g: 0.4,
      zincoMgPor100g: 0.14,
      magnesioMgPor100g: 13.0,
      potassioMgPor100g: 153.0,
      sodioMgPor100g: 1.0,
      vitaminaAMcgPor100g: 2.0,
      vitaminaCMgPor100g: 63.6,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 6.3,
      calcioMgPor100g: 8.0,
      ferroMgPor100g: 0.2,
      zincoMgPor100g: 0.2,
      magnesioMgPor100g: 15.0,
      potassioMgPor100g: 206.0,
      sodioMgPor100g: 2.0,
      vitaminaAMcgPor100g: 7.0,
      vitaminaCMgPor100g: 8.7,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 123.0,
      ferroMgPor100g: 0.05,
      zincoMgPor100g: 0.4,
      magnesioMgPor100g: 10.0,
      potassioMgPor100g: 143.0,
      sodioMgPor100g: 43.0,
      vitaminaAMcgPor100g: 46.0,
      vitaminaCMgPor100g: 0.9,
      vitaminaDMcgPor100g: 1.0,
      vitaminaB12McgPor100g: 0.45,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 134.0,
      ferroMgPor100g: 0.04,
      zincoMgPor100g: 0.4,
      magnesioMgPor100g: 11.0,
      potassioMgPor100g: 156.0,
      sodioMgPor100g: 52.0,
      vitaminaAMcgPor100g: 5.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 1.0,
      vitaminaB12McgPor100g: 0.5,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 157.0,
      ferroMgPor100g: 0.1,
      zincoMgPor100g: 0.6,
      magnesioMgPor100g: 14.0,
      potassioMgPor100g: 195.0,
      sodioMgPor100g: 60.0,
      vitaminaAMcgPor100g: 4.0,
      vitaminaCMgPor100g: 0.8,
      vitaminaDMcgPor100g: 0.1,
      vitaminaB12McgPor100g: 0.6,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 579.0,
      ferroMgPor100g: 0.3,
      zincoMgPor100g: 2.3,
      magnesioMgPor100g: 18.0,
      potassioMgPor100g: 105.0,
      sodioMgPor100g: 310.0,
      vitaminaAMcgPor100g: 110.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.4,
      vitaminaB12McgPor100g: 0.9,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 875.0,
      ferroMgPor100g: 0.3,
      zincoMgPor100g: 3.5,
      magnesioMgPor100g: 24.0,
      potassioMgPor100g: 76.0,
      sodioMgPor100g: 580.0,
      vitaminaAMcgPor100g: 180.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.5,
      vitaminaB12McgPor100g: 1.5,
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
      fibrasPor100g: 8.0,
      calcioMgPor100g: 43.0,
      ferroMgPor100g: 1.9,
      zincoMgPor100g: 2.9,
      magnesioMgPor100g: 154.0,
      potassioMgPor100g: 649.0,
      sodioMgPor100g: 17.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 0.0,
      calcioMgPor100g: 1.0,
      ferroMgPor100g: 0.6,
      zincoMgPor100g: 0.0,
      magnesioMgPor100g: 0.0,
      potassioMgPor100g: 1.0,
      sodioMgPor100g: 2.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
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
      fibrasPor100g: 3.7,
      calcioMgPor100g: 33.0,
      ferroMgPor100g: 5.2,
      zincoMgPor100g: 4.7,
      magnesioMgPor100g: 237.0,
      potassioMgPor100g: 585.0,
      sodioMgPor100g: 16.0,
      vitaminaAMcgPor100g: 0.0,
      vitaminaCMgPor100g: 0.0,
      vitaminaDMcgPor100g: 0.0,
      vitaminaB12McgPor100g: 0.0,
      porcaoSugerida: '15g (5 unidades)',
    ),
  ];

  static Alimento? buscarPorNome(String nome) {
    final termo = nome.trim().toLowerCase();
    if (termo.isEmpty) return null;
    for (final a in lista) {
      if (a.nome.toLowerCase() == termo) return a;
    }
    for (final a in lista) {
      if (a.nome.toLowerCase().contains(termo) || termo.contains(a.nome.toLowerCase())) {
        return a;
      }
    }
    return null;
  }

  static int buscarCaloriasPor100g(String nome) {
    final alimento = buscarPorNome(nome);
    return alimento?.caloriasPor100g ?? 120;
  }

  /// Verifica se o alimento especificado é líquido para exibição automática de 'ml'
  static bool ehLiquido(String nome) {
    final alimento = buscarPorNome(nome);
    if (alimento != null) return alimento.isLiquido;
    final n = nome.trim().toLowerCase();
    return n.contains('leite') ||
        n.contains('suco') ||
        n.contains('água') ||
        n.contains('agua') ||
        n.contains('café') ||
        n.contains('cafe') ||
        n.contains('chá') ||
        n.contains('cha') ||
        n.contains('azeite') ||
        n.contains('óleo') ||
        n.contains('oleo') ||
        n.contains('ml');
  }

  /// Retorna 'ml' para líquidos e 'g' para sólidos
  static String obterUnidade(String nome) => ehLiquido(nome) ? 'ml' : 'g';
}
