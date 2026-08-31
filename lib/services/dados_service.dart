import '../models/dieta_model.dart';
import '../models/paciente_model.dart';
import 'api_service.dart';

class DadosService {
  // Singleton para manter o estado persistente durante a execução do app
  static final DadosService _instancia = DadosService._interno();
  factory DadosService() => _instancia;
  DadosService._interno() {
    _inicializarDados();
  }

  final List<PacienteModel> _pacientes = [];
  String _tipoUsuarioLogado = 'NUTRI'; // 'NUTRI' ou 'CLIENTE'

  String get tipoUsuarioLogado => _tipoUsuarioLogado;
  bool get isNutri => _tipoUsuarioLogado == 'NUTRI' || _tipoUsuarioLogado == 'PERSONAL';

  void setTipoUsuarioLogado(String tipo) {
    _tipoUsuarioLogado = tipo;
  }

  void _inicializarDados() {
    // Dados agora são carregados do backend
  }

  Future<void> carregarDadosDoBackend() async {
    try {
      final jsonList = await ApiService.getPacientes();
      _pacientes.clear();
      _pacientes.addAll(jsonList.map((e) => PacienteModel.fromJson(e)).toList());
    } catch (e) {
      // Caso dê erro, os dados ficarão vazios (ou usar cache local no futuro)
    }
  }

  List<PacienteModel> getPacientes() {
    return List.unmodifiable(_pacientes);
  }

  PacienteModel? getPacientePorId(int id) {
    try {
      return _pacientes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void atualizarMetaCalorica(int pacienteId, double novaMeta) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      paciente.metaCalorica = novaMeta;
      ApiService.atualizarPaciente(pacienteId, {'meta_calorica': novaMeta});
    }
  }

  void alternarStatusFinanceiro(int pacienteId) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      final novoStatus = paciente.statusFinanceiro == StatusFinanceiro.pago
          ? StatusFinanceiro.debito
          : StatusFinanceiro.pago;
      paciente.statusFinanceiro = novoStatus;
      ApiService.atualizarPaciente(pacienteId, {
        'status_financeiro': novoStatus == StatusFinanceiro.pago ? 'pago' : 'debito'
      });
    }
  }

  Future<void> salvarRefeicao(int pacienteId, RefeicaoModel refeicao) async {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      final index = paciente.planoAlimentar.indexWhere((r) => r.id == refeicao.id);
      
      final data = refeicao.toJson();
      data['usuario_id'] = pacienteId;
      
      final savedData = await ApiService.salvarRefeicao(
        data, 
        id: (refeicao.id.startsWith('ref_') || refeicao.id.isEmpty) ? null : refeicao.id
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
         // fallback local se falhar, apenas pra UI não quebrar
         if (index >= 0) {
           paciente.planoAlimentar[index] = refeicao;
         } else {
           paciente.planoAlimentar.add(refeicao);
         }
      }
    }
  }

  void removerRefeicao(int pacienteId, String refeicaoId) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      paciente.planoAlimentar.removeWhere((r) => r.id == refeicaoId);
      if (!refeicaoId.startsWith('ref_')) {
        ApiService.excluirRefeicao(refeicaoId);
      }
    }
  }

  void excluirRefeicao(int pacienteId, String refeicaoId) => removerRefeicao(pacienteId, refeicaoId);
}
