class MensagemChat {
  final String id;
  final int pacienteId;
  final String pacienteNome;
  final String remetente; // 'PACIENTE' ou 'NUTRI'
  final String remetenteNome;
  final String texto;
  final DateTime timestamp;
  final bool lida;
  final bool minhaMensagem;
  final bool paraMim;
  final bool notificar;

  MensagemChat({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.remetente,
    required this.remetenteNome,
    required this.texto,
    required this.timestamp,
    this.lida = false,
    this.minhaMensagem = false,
    this.paraMim = false,
    this.notificar = false,
  });

  bool get isNutri => remetente == 'NUTRI';
  bool get isPaciente => remetente == 'PACIENTE';

  String get horaFormatada {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    final tipoRemetente = json['remetente_tipo']?.toString().toUpperCase() ??
        json['remetente']?.toString().toUpperCase() ??
        'PACIENTE';
    final isNutri = tipoRemetente == 'NUTRI';

    int pId = 1;
    if (json['paciente_id'] != null) {
      pId = int.tryParse(json['paciente_id'].toString()) ?? 1;
    } else if (isNutri) {
      pId = int.tryParse(json['destinatario']?.toString() ?? '1') ?? 1;
    } else {
      pId = int.tryParse(json['remetente']?.toString() ?? '1') ?? 1;
    }

    final pNome = json['paciente_nome']?.toString() ??
        (isNutri ? json['destinatario_nome']?.toString() : json['remetente_nome']?.toString()) ??
        'Paciente';

    final remNome = json['remetente_nome']?.toString() ??
        (isNutri ? 'Dra. Juliana Braz' : pNome);

    DateTime dataHora = DateTime.now();
    if (json['data_criacao'] != null) {
      dataHora = DateTime.tryParse(json['data_criacao'].toString()) ?? DateTime.now();
    } else if (json['timestamp'] != null) {
      dataHora = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    }

    return MensagemChat(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      pacienteId: pId,
      pacienteNome: pNome,
      remetente: isNutri ? 'NUTRI' : 'PACIENTE',
      remetenteNome: remNome,
      texto: json['texto']?.toString() ?? '',
      timestamp: dataHora,
      lida: json['lida'] == true,
      minhaMensagem: json['minha_mensagem'] == true,
      paraMim: json['para_mim'] == true,
      notificar: json['notificar'] == true,
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
      'minha_mensagem': minhaMensagem,
      'para_mim': paraMim,
      'notificar': notificar,
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
    bool? minhaMensagem,
    bool? paraMim,
    bool? notificar,
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
      minhaMensagem: minhaMensagem ?? this.minhaMensagem,
      paraMim: paraMim ?? this.paraMim,
      notificar: notificar ?? this.notificar,
    );
  }
}
