import 'dieta_model.dart';
import 'registro_diario_model.dart';
import 'metas_model.dart';

enum StatusFinanceiro {
  pago,
  debito,
}

class PacienteModel {
  final int id;
  final String nome;
  final String usuario;
  final String? email;
  final String? fotoUrl;
  StatusFinanceiro statusFinanceiro;
  double valorMensalidade;
  double metaCalorica;
  List<RefeicaoModel> planoAlimentar;
  List<RegistroDiarioModel> registrosDiarios;
  MetasModel metas;

  PacienteModel({
    required this.id,
    required this.nome,
    required this.usuario,
    this.email,
    this.fotoUrl,
    required this.statusFinanceiro,
    this.valorMensalidade = 400.0,
    this.metaCalorica = 2000.0,
    List<RefeicaoModel>? planoAlimentar,
    List<RegistroDiarioModel>? registrosDiarios,
    MetasModel? metas,
  }) : planoAlimentar = planoAlimentar ?? [],
       registrosDiarios = registrosDiarios ?? [],
       metas = metas ?? MetasModel();

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    var planoList = json['plano_alimentar'] as List? ?? [];
    return PacienteModel(
      id: json['id'],
      nome: json['nome'] ?? json['username'] ?? '',
      usuario: json['username'] ?? '',
      email: json['email'],
      fotoUrl: json['foto_url'],
      statusFinanceiro: json['status_financeiro'] == 'pago' ? StatusFinanceiro.pago : StatusFinanceiro.debito,
      valorMensalidade: double.tryParse(json['valor_mensalidade']?.toString() ?? '400') ?? 400.0,
      metaCalorica: double.tryParse(json['meta_calorica']?.toString() ?? '2000') ?? 2000.0,
      planoAlimentar: planoList.map((e) => RefeicaoModel.fromJson(e as Map<String, dynamic>)).toList(),
      registrosDiarios: [], // Será preenchido separadamente através da API de registros
    );
  }

  bool get isPago => statusFinanceiro == StatusFinanceiro.pago;
  bool get isDebito => statusFinanceiro == StatusFinanceiro.debito;

  String get valorFormatado {
    return 'R\$ ${valorMensalidade.toStringAsFixed(0)}';
  }

  String get statusTexto {
    return isPago ? 'Em dia' : 'Em débito';
  }

  int get totalCaloriasPlano =>
      planoAlimentar.fold(0, (soma, ref) => soma + ref.totalCalorias);

  int get totalCaloriasConsumidasHoje {
    if (registrosDiarios.isEmpty) return 0;
    // O primeiro registro é o mais recente ou do dia atual (se ordenado)
    return registrosDiarios.first.totalCalorias;
  }

  double get caloriasRestantes => metaCalorica - totalCaloriasConsumidasHoje;

  PacienteModel copyWith({
    int? id,
    String? nome,
    String? usuario,
    String? email,
    String? fotoUrl,
    StatusFinanceiro? statusFinanceiro,
    double? valorMensalidade,
    double? metaCalorica,
    List<RefeicaoModel>? planoAlimentar,
    List<RegistroDiarioModel>? registrosDiarios,
    MetasModel? metas,
  }) {
    return PacienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      usuario: usuario ?? this.usuario,
      email: email ?? this.email,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      statusFinanceiro: statusFinanceiro ?? this.statusFinanceiro,
      valorMensalidade: valorMensalidade ?? this.valorMensalidade,
      metaCalorica: metaCalorica ?? this.metaCalorica,
      planoAlimentar: planoAlimentar ?? List.from(this.planoAlimentar),
      registrosDiarios: registrosDiarios ?? List.from(this.registrosDiarios),
      metas: metas ?? this.metas,
    );
  }
}
