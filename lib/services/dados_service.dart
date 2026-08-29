import '../models/dieta_model.dart';
import '../models/paciente_model.dart';

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
    _pacientes.addAll([
      PacienteModel(
        id: 1,
        nome: 'Ana Souza',
        usuario: 'ana.souza',
        email: 'ana.souza@email.com',
        fotoUrl: null,
        statusFinanceiro: StatusFinanceiro.pago,
        valorMensalidade: 400.0,
        metaCalorica: 1900.0,
        planoAlimentar: [
          RefeicaoModel(
            id: 'ref_1',
            tipo: 'Café da manhã',
            horarioSugerido: '07:30',
            itens: [
              ItemRefeicaoModel(alimentoNome: 'Pão francês', gramas: 50),
              ItemRefeicaoModel(alimentoNome: 'Ovo cozido', gramas: 100),
              ItemRefeicaoModel(alimentoNome: 'Banana prata', gramas: 70),
            ],
          ),
          RefeicaoModel(
            id: 'ref_2',
            tipo: 'Almoço',
            horarioSugerido: '12:30',
            itens: [
              ItemRefeicaoModel(alimentoNome: 'Arroz branco cozido', gramas: 120),
              ItemRefeicaoModel(alimentoNome: 'Feijão carioca cozido', gramas: 100),
              ItemRefeicaoModel(alimentoNome: 'Frango grelhado (peito)', gramas: 150),
              ItemRefeicaoModel(alimentoNome: 'Azeite de oliva extravirgem', gramas: 8),
            ],
          ),
        ],
      ),
      PacienteModel(
        id: 2,
        nome: 'Carlos Lima',
        usuario: 'carlos.lima',
        email: 'carlos.lima@email.com',
        fotoUrl: null,
        statusFinanceiro: StatusFinanceiro.debito,
        valorMensalidade: 400.0,
        metaCalorica: 2400.0,
        planoAlimentar: [
          RefeicaoModel(
            id: 'ref_3',
            tipo: 'Café da manhã',
            horarioSugerido: '08:00',
            itens: [
              ItemRefeicaoModel(alimentoNome: 'Aveia em flocos', gramas: 60),
              ItemRefeicaoModel(alimentoNome: 'Banana prata', gramas: 100),
              ItemRefeicaoModel(alimentoNome: 'Whey Protein (concentrado/isolado)', gramas: 30),
              ItemRefeicaoModel(alimentoNome: 'Leite desnatado', gramas: 200),
            ],
          ),
        ],
      ),
      PacienteModel(
        id: 3,
        nome: 'Beatriz Alves',
        usuario: 'beatriz.alves',
        email: 'bia.alves@email.com',
        fotoUrl: null,
        statusFinanceiro: StatusFinanceiro.pago,
        valorMensalidade: 400.0,
        metaCalorica: 1750.0,
        planoAlimentar: [
          RefeicaoModel(
            id: 'ref_4',
            tipo: 'Café da manhã',
            horarioSugerido: '07:00',
            itens: [
              ItemRefeicaoModel(alimentoNome: 'Goma de tapioca hidratada', gramas: 50),
              ItemRefeicaoModel(alimentoNome: 'Ovo cozido', gramas: 100),
              ItemRefeicaoModel(alimentoNome: 'Queijo minas frescal', gramas: 30),
            ],
          ),
        ],
      ),
      PacienteModel(
        id: 4,
        nome: 'Lucas Mendes',
        usuario: 'lucas.mendes',
        email: 'lucas.m@email.com',
        fotoUrl: null,
        statusFinanceiro: StatusFinanceiro.debito,
        valorMensalidade: 400.0,
        metaCalorica: 2800.0,
        planoAlimentar: [],
      ),
      PacienteModel(
        id: 5,
        nome: 'Juliana Fernandes',
        usuario: 'ju.fernandes',
        email: 'juliana.f@email.com',
        fotoUrl: null,
        statusFinanceiro: StatusFinanceiro.pago,
        valorMensalidade: 400.0,
        metaCalorica: 2100.0,
        planoAlimentar: [
          RefeicaoModel(
            id: 'ref_5',
            tipo: 'Almoço',
            horarioSugerido: '13:00',
            itens: [
              ItemRefeicaoModel(alimentoNome: 'Arroz integral cozido', gramas: 150),
              ItemRefeicaoModel(alimentoNome: 'Filé de tilápia grelhado', gramas: 150),
              ItemRefeicaoModel(alimentoNome: 'Batata doce cozida', gramas: 100),
            ],
          ),
        ],
      ),
    ]);
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
    }
  }

  void alternarStatusFinanceiro(int pacienteId) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      paciente.statusFinanceiro = paciente.statusFinanceiro == StatusFinanceiro.pago
          ? StatusFinanceiro.debito
          : StatusFinanceiro.pago;
    }
  }

  void salvarRefeicao(int pacienteId, RefeicaoModel refeicao) {
    final paciente = getPacientePorId(pacienteId);
    if (paciente != null) {
      final index = paciente.planoAlimentar.indexWhere((r) => r.id == refeicao.id);
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
    }
  }

  void excluirRefeicao(int pacienteId, String refeicaoId) => removerRefeicao(pacienteId, refeicaoId);
}
