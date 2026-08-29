import 'alimento_model.dart';

class ItemRefeicaoModel {
  String? alimentoNome;
  double gramas;
  int? caloriasManual; // opcional para quando não estiver na base

  ItemRefeicaoModel({
    this.alimentoNome,
    this.gramas = 0,
    this.caloriasManual,
  });

  int get calorias {
    if (alimentoNome == null || gramas <= 0) return 0;
    if (caloriasManual != null && caloriasManual! > 0) return caloriasManual!;
    final cal100g = BancoAlimentos.buscarCaloriasPor100g(alimentoNome!);
    return ((cal100g * gramas) / 100).round();
  }

  Alimento? get alimentoObj {
    if (alimentoNome == null) return null;
    return BancoAlimentos.buscarPorNome(alimentoNome!);
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
  List<ItemRefeicaoModel> itens;

  RefeicaoModel({
    required this.id,
    required this.tipo,
    this.horarioSugerido,
    required this.itens,
  });

  int get totalCalorias => itens.fold(0, (soma, item) => soma + item.calorias);

  RefeicaoModel copyWith({
    String? id,
    String? tipo,
    String? horarioSugerido,
    List<ItemRefeicaoModel>? itens,
  }) {
    return RefeicaoModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      horarioSugerido: horarioSugerido ?? this.horarioSugerido,
      itens: itens != null ? List<ItemRefeicaoModel>.from(itens) : this.itens,
    );
  }
}
