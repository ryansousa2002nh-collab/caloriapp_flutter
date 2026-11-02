import 'alimento_model.dart';

class ItemRefeicaoModel {
  String? alimentoNome;
  double gramas;
  int? caloriasManual; // opcional para quando não estiver na base

  ItemRefeicaoModel({this.alimentoNome, this.gramas = 0, this.caloriasManual});

  factory ItemRefeicaoModel.fromJson(Map<String, dynamic> json) {
    return ItemRefeicaoModel(
      alimentoNome: json['alimento_nome'] ?? json['nome'],
      gramas:
          double.tryParse(json['quantidade_gramas']?.toString() ?? '0') ?? 0,
      caloriasManual: json['calorias_manual'] != null
          ? int.tryParse(json['calori as_manual'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alimento_nome': alimentoNome,
      'quantidade_gramas': gramas,
      'calorias_manual': caloriasManual,
    };
  }

  Alimento? get alimentoObj {
    if (alimentoNome == null) return null;
    return BancoAlimentos.buscarPorNome(alimentoNome!);
  }

  bool get isLiquido => alimentoObj?.isLiquido ?? BancoAlimentos.ehLiquido(alimentoNome ?? '');
  String get unidadeMedida => isLiquido ? 'ml' : 'g';

  int get calorias {
    if (alimentoNome == null || gramas <= 0) return 0;
    if (caloriasManual != null && caloriasManual! > 0) return caloriasManual!;
    final cal100g = BancoAlimentos.buscarCaloriasPor100g(alimentoNome!);
    return ((cal100g * gramas) / 100).round();
  }

  // Cálculos dos macros proporcionais às gramas informadas
  // Se o alimento não estiver na base, faz uma estimativa rápida pelas calorias
  double get proteinas {
    if (gramas <= 0) return 0;
    final obj = alimentoObj;
    if (obj != null) return (obj.proteinasPor100g * gramas) / 100.0;
    return (calorias * 0.20) / 4.0;
  }

  double get carboidratos {
    if (gramas <= 0) return 0;
    final obj = alimentoObj;
    if (obj != null) return (obj.carboidratosPor100g * gramas) / 100.0;
    return (calorias * 0.50) / 4.0;
  }

  double get gorduras {
    if (gramas <= 0) return 0;
    final obj = alimentoObj;
    if (obj != null) return (obj.gordurasPor100g * gramas) / 100.0;
    return (calorias * 0.30) / 9.0;
  }

  double get fibras {
    if (gramas <= 0) return 0;
    final obj = alimentoObj;
    if (obj != null) return (obj.fibrasPor100g * gramas) / 100.0;
    return 0.0;
  }

  // Busca qualquer nutriente (macro ou micro) pela chave
  double valorNutriente(String chave) {
    if (gramas <= 0) return 0;
    if (chave == 'calorias') return calorias.toDouble();
    if (chave == 'proteinas') return proteinas;
    if (chave == 'carboidratos') return carboidratos;
    if (chave == 'gorduras') return gorduras;
    if (chave == 'fibras') return fibras;

    final obj = alimentoObj;
    if (obj == null) return 0.0;
    return obj.valorNutrientePorGramas(chave, gramas);
  }

  ItemRefeicaoModel copyWith({
    String? alimentoNome,
    double? gramas,
    int? caloriasManual,
  }) {
    return ItemRefeicaoModel(
      alimentoNome: alimentoNome ?? this.alimentoNome,
      gramas: gramas ?? this.gramas,
      caloriasManual: caloriasManual ?? this.caloriasManual,
    );
  }
}

class RefeicaoModel {
  final String id;
  String tipo; // Ex: 'Café da manhã', 'Almoço', 'Jantar'
  String? horarioSugerido; // Ex: '07:30'
  String? observacoes;
  List<ItemRefeicaoModel> itens;

  RefeicaoModel({
    required this.id,
    required this.tipo,
    this.horarioSugerido,
    this.observacoes,
    required this.itens,
  });

  factory RefeicaoModel.fromJson(Map<String, dynamic> json) {
    var itensList = json['itens'] as List? ?? [];
    return RefeicaoModel(
      id: (json['id'] ?? 'ref_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      tipo: json['tipo'] ?? '',
      horarioSugerido: json['horario_sugerido'],
      observacoes: json['observacoes'],
      itens: itensList
          .map((e) => ItemRefeicaoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'horario_sugerido': horarioSugerido,
      'observacoes': observacoes,
      'itens': itens.map((e) => e.toJson()).toList(),
    };
  }

  // Somatórios da refeição inteira
  int get totalCalorias => itens.fold(0, (soma, item) => soma + item.calorias);
  double get totalProteinas =>
      itens.fold(0.0, (soma, item) => soma + item.proteinas);
  double get totalCarboidratos =>
      itens.fold(0.0, (soma, item) => soma + item.carboidratos);
  double get totalGorduras =>
      itens.fold(0.0, (soma, item) => soma + item.gorduras);
  double get totalFibras => itens.fold(0.0, (soma, item) => soma + item.fibras);

  double totalNutriente(String chave) =>
      itens.fold(0.0, (soma, item) => soma + item.valorNutriente(chave));

  RefeicaoModel copyWith({
    String? id,
    String? tipo,
    String? horarioSugerido,
    String? observacoes,
    List<ItemRefeicaoModel>? itens,
  }) {
    return RefeicaoModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      horarioSugerido: horarioSugerido ?? this.horarioSugerido,
      observacoes: observacoes ?? this.observacoes,
      itens: itens != null ? List<ItemRefeicaoModel>.from(itens) : this.itens,
    );
  }
}

// Guarda quanto cada alimento contribuiu no total do dia (usado no ranking da nutri)
class ContribuicaoAlimento {
  final String alimentoNome;
  final String categoria;
  final String refeicoesOrigem;
  final double gramasTotais;
  final double valorNutriente;
  final double percentualNoTotal;
  final int calorias;
  final double proteinas;
  final double carboidratos;
  final double gorduras;

  const ContribuicaoAlimento({
    required this.alimentoNome,
    required this.categoria,
    required this.refeicoesOrigem,
    required this.gramasTotais,
    required this.valorNutriente,
    required this.percentualNoTotal,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
  });
}

// Classe auxiliar que junta todas as refeições do plano e faz as contas de VET, g/kg e micros
class ComposicaoNutricionalDieta {
  final List<RefeicaoModel> refeicoes;
  final double pesoPacienteKg;
  final double metaCalorica;

  ComposicaoNutricionalDieta({
    required this.refeicoes,
    this.pesoPacienteKg = 70.0,
    this.metaCalorica = 2000.0,
  });

  int get totalCalorias => refeicoes.fold(0, (s, r) => s + r.totalCalorias);
  double get totalProteinas =>
      refeicoes.fold(0.0, (s, r) => s + r.totalProteinas);
  double get totalCarboidratos =>
      refeicoes.fold(0.0, (s, r) => s + r.totalCarboidratos);
  double get totalGorduras =>
      refeicoes.fold(0.0, (s, r) => s + r.totalGorduras);
  double get totalFibras => refeicoes.fold(0.0, (s, r) => s + r.totalFibras);

  // Proteína e carbo valem 4 kcal por grama, gordura vale 9 kcal
  double get kcalProteinas => totalProteinas * 4.0;
  double get kcalCarboidratos => totalCarboidratos * 4.0;
  double get kcalGorduras => totalGorduras * 9.0;

  double get kcalMacrosTotal {
    final soma = kcalProteinas + kcalCarboidratos + kcalGorduras;
    return soma > 0 ? soma : 1.0;
  }

  // Porcentagem de cada macro no Valor Energético Total (VET)
  double get percentualProteinasVET =>
      (kcalProteinas + kcalCarboidratos + kcalGorduras) > 0
      ? (kcalProteinas / kcalMacrosTotal) * 100.0
      : 0.0;

  double get percentualCarboidratosVET =>
      (kcalProteinas + kcalCarboidratos + kcalGorduras) > 0
      ? (kcalCarboidratos / kcalMacrosTotal) * 100.0
      : 0.0;

  double get percentualGordurasVET =>
      (kcalProteinas + kcalCarboidratos + kcalGorduras) > 0
      ? (kcalGorduras / kcalMacrosTotal) * 100.0
      : 0.0;

  // Divisão pelo peso atual do paciente pra mostrar g/kg (igual no Dietbox/WebDiet)
  double get proteinasPorKg =>
      pesoPacienteKg > 0 ? totalProteinas / pesoPacienteKg : 0.0;
  double get carboidratosPorKg =>
      pesoPacienteKg > 0 ? totalCarboidratos / pesoPacienteKg : 0.0;
  double get gordurasPorKg =>
      pesoPacienteKg > 0 ? totalGorduras / pesoPacienteKg : 0.0;

  double totalNutriente(String chave) =>
      refeicoes.fold(0.0, (s, r) => s + r.totalNutriente(chave));

  double percentualMetaMicronutriente(MicronutrienteInfo info) {
    if (info.metaDiaria <= 0) return 0.0;
    return (totalNutriente(info.chave) / info.metaDiaria) * 100.0;
  }

  // Agrupa alimentos repetidos em várias refeições e ordena do maior pro menor
  List<ContribuicaoAlimento> rankingAlimentosPorNutriente(
    String chaveNutriente,
  ) {
    final Map<String, _AcumuladorAlimento> mapa = {};
    final totalGeral = totalNutriente(chaveNutriente);

    for (final ref in refeicoes) {
      for (final item in ref.itens) {
        final nome = (item.alimentoNome ?? '').trim();
        if (nome.isEmpty || item.gramas <= 0) continue;

        final obj = item.alimentoObj;
        final acumulado = mapa.putIfAbsent(
          nome,
          () => _AcumuladorAlimento(
            nome: nome,
            categoria: obj?.categoria ?? 'Outros',
          ),
        );
        acumulado.gramas += item.gramas;
        acumulado.valorNutriente += item.valorNutriente(chaveNutriente);
        acumulado.calorias += item.calorias;
        acumulado.proteinas += item.proteinas;
        acumulado.carboidratos += item.carboidratos;
        acumulado.gorduras += item.gorduras;
        if (ref.tipo.trim().isNotEmpty) {
          acumulado.refeicoes.add(ref.tipo.trim());
        }
      }
    }

    final lista = mapa.values.map((a) {
      final pct = totalGeral > 0
          ? (a.valorNutriente / totalGeral) * 100.0
          : 0.0;
      return ContribuicaoAlimento(
        alimentoNome: a.nome,
        categoria: a.categoria,
        refeicoesOrigem: a.refeicoes.join(' • '),
        gramasTotais: a.gramas,
        valorNutriente: a.valorNutriente,
        percentualNoTotal: pct,
        calorias: a.calorias,
        proteinas: a.proteinas,
        carboidratos: a.carboidratos,
        gorduras: a.gorduras,
      );
    }).toList();

    lista.sort((a, b) => b.valorNutriente.compareTo(a.valorNutriente));
    return lista;
  }
}

class _AcumuladorAlimento {
  final String nome;
  final String categoria;
  final Set<String> refeicoes = {};
  double gramas = 0;
  double valorNutriente = 0;
  int calorias = 0;
  double proteinas = 0;
  double carboidratos = 0;
  double gorduras = 0;

  _AcumuladorAlimento({required this.nome, required this.categoria});
}
