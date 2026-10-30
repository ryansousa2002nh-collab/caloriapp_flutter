import '../models/dieta_model.dart';
import '../models/metas_model.dart';
import '../models/paciente_model.dart';
import '../models/registro_diario_model.dart';
import 'api_service.dart';

class DadosService {
  // Singleton para manter o estado persistente durante a execução do app
  static final DadosService _instancia = DadosService._interno();
  factory DadosService() => _instancia;
  DadosService._interno();

  final List<PacienteModel> _pacientes = [];
  String _tipoUsuarioLogado = 'NUTRI'; // 'NUTRI' ou 'CLIENTE'
  String? _usernameLogado;
  String _nomeNutri = 'Dra. Juliana Braz';
  String _emailNutri = 'juliana.braz@nutri.com';

  String get tipoUsuarioLogado => _tipoUsuarioLogado;
  bool get isNutri => _tipoUsuarioLogado == 'NUTRI';
  String get nomeNutri => _nomeNutri;
  String get emailNutri => _emailNutri;

  void setTipoUsuarioLogado(String tipo) {
    _tipoUsuarioLogado = tipo;
  }

  void atualizarPerfilNutri({required String nome, required String email}) {
    _nomeNutri = nome;
    _emailNutri = email;
  }

  Future<void> carregarDadosDoBackend() async {
    try {
      _usernameLogado = await ApiService.getLoggedUsername();
      final jsonList = await ApiService.getPacientes();
      _pacientes.clear();
      _pacientes.addAll(
        jsonList.map((e) => PacienteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );

      // Carregar registros de hoje para todos os pacientes
      await carregarRegistrosDiarios(DateTime.now().toIso8601String().split('T').first);
    } catch (_) {}
  }

  Future<void> carregarRegistrosDiarios(String data) async {
    for (var p in _pacientes) {
      try {
        final regs = await ApiService.getRegistrosDiarios(data, pacienteId: p.id);
        p.registrosDiarios = regs
            .map((e) => RegistroDiarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
  }

  Future<void> salvarRegistroDiario(int pacienteId, Map<String, dynamic> data) async {
    final savedData = await ApiService.salvarRegistroDiario(data, id: data['id']?.toString());
    final payload = savedData ?? data;
    final newReg = RegistroDiarioModel.fromJson(payload);

    var paciente = getPacientePorId(pacienteId);
    if (paciente == null) {
      paciente = getPacienteAtivo();
    }

    final index = paciente.registrosDiarios.indexWhere(
      (r) => (r.id.isNotEmpty && r.id == newReg.id) || (r.data != null && r.data == newReg.data),
    );
    if (index >= 0) {
      paciente.registrosDiarios[index] = newReg;
    } else {
      paciente.registrosDiarios.insert(0, newReg);
    }
  }

  List<PacienteModel> getPacientes() {
    return List.unmodifiable(_pacientes);
  }

  /// Retorna o paciente correspondente ao usuário logado (ou o primeiro da lista)
  PacienteModel getPacienteAtivo() {
    if (_usernameLogado != null && _usernameLogado!.isNotEmpty) {
      final encontrado = _pacientes.where(
        (p) => p.usuario.toLowerCase() == _usernameLogado!.toLowerCase(),
      );
      if (encontrado.isNotEmpty) return encontrado.first;
    }
    if (_pacientes.isNotEmpty) return _pacientes.first;

    final padrao = PacienteModel(
      id: 1,
      nome: 'Paciente Teste',
      usuario: 'paciente.teste',
      email: 'paciente@teste.com',
      statusFinanceiro: StatusFinanceiro.pago,
    );
    _pacientes.add(padrao);
    return padrao;
  }

  PacienteModel? getPacientePorId(int id) {
    try {
      return _pacientes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void atualizarMetaCalorica(int pacienteId, double novaMeta) {
    final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();
    paciente.metaCalorica = novaMeta;
    ApiService.atualizarPaciente(paciente.id, {'meta_calorica': novaMeta});
  }

  void atualizarMetas(int pacienteId, MetasModel novasMetas) {
    final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();
    paciente.metas = novasMetas;
    ApiService.atualizarPaciente(paciente.id, {'metas': novasMetas.toJson()});
  }

  Future<void> atualizarDadosPerfilPaciente(
    int pacienteId, {
    required String nome,
    required String email,
    required String usuario,
    String? fotoUrl,
  }) async {
    final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();
    paciente.nome = nome;
    paciente.email = email;
    paciente.usuario = usuario;
    if (fotoUrl != null) {
      paciente.fotoUrl = fotoUrl.isEmpty ? null : fotoUrl;
    }
    _usernameLogado = usuario;
    await ApiService.atualizarPaciente(paciente.id, {
      'nome': nome,
      'email': email,
      'username': usuario,
      'foto_url': paciente.fotoUrl,
    });
  }

  void alternarStatusFinanceiro(int pacienteId) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      final novoStatus = paciente.statusFinanceiro == StatusFinanceiro.pago
          ? StatusFinanceiro.debito
          : StatusFinanceiro.pago;
      paciente.statusFinanceiro = novoStatus;
      ApiService.atualizarPaciente(pacienteId, {
        'status_financeiro': novoStatus == StatusFinanceiro.pago ? 'pago' : 'debito',
      });
    }
  }

  Future<void> salvarRefeicao(int pacienteId, RefeicaoModel refeicao) async {
    final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();
    final index = paciente.planoAlimentar.indexWhere((r) => r.id == refeicao.id);

    final data = refeicao.toJson();
    data['usuario_id'] = paciente.id;

    final savedData = await ApiService.salvarRefeicao(
      data,
      id: (refeicao.id.startsWith('ref_') || refeicao.id.isEmpty) ? null : refeicao.id,
    );

    if (savedData != null) {
      final newRef = RefeicaoModel.fromJson(savedData);
      if (index >= 0) {
        paciente.planoAlimentar[index] = newRef;
      } else {
        paciente.planoAlimentar.removeWhere((r) => r.id == refeicao.id);
        paciente.planoAlimentar.add(newRef);
      }
    } else {
      if (index >= 0) {
        paciente.planoAlimentar[index] = refeicao;
      } else {
        paciente.planoAlimentar.add(refeicao);
      }
    }
  }

  void removerRefeicao(int pacienteId, String refeicaoId) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      paciente.planoAlimentar.removeWhere((r) => r.id == refeicaoId);
      ApiService.excluirRefeicao(refeicaoId);
    }
  }

  void excluirRefeicao(int pacienteId, String refeicaoId) => removerRefeicao(pacienteId, refeicaoId);
}
