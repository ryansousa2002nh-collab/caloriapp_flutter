class TreinoModel {
  final int id;
  final String nome;
  final String dataCriacao;
  final bool concluidoHoje;
  final List<ItemTreinoModel> itens;

  TreinoModel({
    required this.id,
    required this.nome,
    required this.dataCriacao,
    required this.concluidoHoje,
    required this.itens,
  });

  factory TreinoModel.fromJson(Map<String, dynamic> json) {
    var list = json['itemtreino_set'] as List? ?? [];
    List<ItemTreinoModel> itensList = list.map((i) => ItemTreinoModel.fromJson(i)).toList();

    return TreinoModel(
      id: json['id'],
      nome: json['nome'] ?? '',
      dataCriacao: json['data_criacao'] ?? '',
      concluidoHoje: json['concluido_hoje'] ?? false,
      itens: itensList,
    );
  }
}

class ItemTreinoModel {
  final int id;
  final int exercicioId;
  final String exercicioNome;
  final int series;
  final int repeticoes;
  final String observacoes;

  ItemTreinoModel({
    required this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.series,
    required this.repeticoes,
    required this.observacoes,
  });

  factory ItemTreinoModel.fromJson(Map<String, dynamic> json) {
    return ItemTreinoModel(
      id: json['id'],
      exercicioId: json['exercicio'],
      exercicioNome: json['exercicio_nome'] ?? '',
      series: json['series'] ?? 0,
      repeticoes: json['repeticoes'] ?? 0,
      observacoes: json['observacoes'] ?? '',
    );
  }
}
