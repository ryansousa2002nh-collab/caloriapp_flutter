import 'alimento_model.dart';

class ItemRegistroDiarioModel {
  final int? id;
  final String? refeicaoNome; // Nome da refeição planejada
  final int? refeicaoPlanejadaId;
  String? alimentoNome;
  double gramas;
  int? caloriasManual;
  int? caloriasTotaisAPI;
  String? observacoes;

  ItemRegistroDiarioModel({
    this.id,
    this.refeicaoNome,
    this.refeicaoPlanejadaId,
    this.alimentoNome,
    this.gramas = 0,
    this.caloriasManual,
    this.caloriasTotaisAPI,
    this.observacoes,
  });

  factory ItemRegistroDiarioModel.fromJson(Map<String, dynamic> json) {
    return ItemRegistroDiarioModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      refeicaoNome: json['refeicao_nome'],
      refeicaoPlanejadaId: json['refeicao_planejada'] is int
          ? json['refeicao_planejada']
          : int.tryParse(json['refeicao_planejada']?.toString() ?? ''),
      alimentoNome: json['alimento_nome'] ?? json['nome'],
      gramas: double.tryParse(json['quantidade_gramas']?.toString() ?? '0') ?? 0,
      caloriasManual: json['calorias_manual'] != null ? int.tryParse(json['calorias_manual'].toString()) : null,
      caloriasTotaisAPI: json['calorias_totais'] != null ? int.tryParse(json['calorias_totais'].toString()) : null,
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'refeicao_nome': refeicaoNome,
      'refeicao_planejada': refeicaoPlanejadaId,
      'alimento_nome': alimentoNome,
      'quantidade_gramas': gramas,
      'calorias_manual': calorias,
      'observacoes': observacoes,
    };
  }

  int get calorias {
    if (caloriasTotaisAPI != null && caloriasTotaisAPI! > 0) return caloriasTotaisAPI!;
    if (caloriasManual != null && caloriasManual! > 0) return caloriasManual!;
    if (alimentoNome == null || gramas <= 0) return 0;
    final cal100g = BancoAlimentos.buscarCaloriasPor100g(alimentoNome!);
    return ((cal100g * gramas) / 100).round();
  }
}

class RegistroDiarioModel {
  final String id;
  final String? data;
  List<ItemRegistroDiarioModel> itens;
  int? totalCaloriasAPI;

  RegistroDiarioModel({
    required this.id,
    this.data,
    required this.itens,
    this.totalCaloriasAPI,
  });

  factory RegistroDiarioModel.fromJson(Map<String, dynamic> json) {
    var itensList = json['itens'] as List? ?? [];
    return RegistroDiarioModel(
      id: (json['id'] ?? 'reg_${DateTime.now().millisecondsSinceEpoch}').toString(),
      data: json['data'],
      totalCaloriasAPI: json['total_calorias'] != null ? int.tryParse(json['total_calorias'].toString()) : null,
      itens: itensList.map((e) => ItemRegistroDiarioModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'total_calorias': totalCalorias,
      'itens': itens.map((e) => e.toJson()).toList(),
    };
  }

  int get totalCalorias {
    if (itens.isNotEmpty) {
      return itens.fold(0, (soma, item) => soma + item.calorias);
    }
    return totalCaloriasAPI ?? 0;
  }
}
