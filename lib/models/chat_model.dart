class MensagemChat {
  final String id;
  final int pacienteId;
  final String pacienteNome;
  final String remetente; // 'PACIENTE' ou 'NUTRI'
  final String remetenteNome;
  final String texto;
  final DateTime timestamp;
  final bool lida;

  MensagemChat({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.remetente,
    required this.remetenteNome,
    required this.texto,
    required this.timestamp,
    this.lida = false,
  });

  bool get isNutri => remetente == 'NUTRI';
  bool get isPaciente => remetente == 'PACIENTE';

  String get horaFormatada {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    return MensagemChat(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      pacienteId: json['paciente_id'] is int
          ? json['paciente_id'] as int
          : int.tryParse(json['paciente_id']?.toString() ?? '1') ?? 1,
      pacienteNome: json['paciente_nome']?.toString() ?? 'Paciente',
      remetente: json['remetente']?.toString() ?? 'PACIENTE',
      remetenteNome: json['remetente_nome']?.toString() ?? 'Paciente',
      texto: json['texto']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lida: json['lida'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'paciente_nome': pacienteNome,
      'remetente': remetente,
      'remetente_nome': remetenteNome,
      'texto': texto,
      'timestamp': timestamp.toIso8601String(),
      'lida': lida,
    };
  }

  MensagemChat copyWith({
    String? id,
    int? pacienteId,
    String? pacienteNome,
    String? remetente,
    String? remetenteNome,
    String? texto,
    DateTime? timestamp,
    bool? lida,
  }) {
    return MensagemChat(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      pacienteNome: pacienteNome ?? this.pacienteNome,
      remetente: remetente ?? this.remetente,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      lida: lida ?? this.lida,
    );
  }
}

