import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/dieta_model.dart';
import '../models/metas_model.dart';
import '../models/paciente_model.dart';
import '../models/postagem_comunidade_model.dart';
import '../models/registro_diario_model.dart';
import 'api_service.dart';

class DadosService extends ChangeNotifier {
  // Singleton para manter o estado persistente durante a execução do app
  static final DadosService _instancia = DadosService._interno();
  factory DadosService() => _instancia;
  DadosService._interno();

  final List<PacienteModel> _pacientes = [];
  final List<PostagemComunidadeModel> _postagensComunidade = [];
  final List<CategoriaComunidadeModel> _categoriasComunidade = [];
  String _tipoUsuarioLogado = 'NUTRI'; // 'NUTRI' ou 'CLIENTE'
  String? _usernameLogado;
  String _nomeNutri = 'Dra. Juliana Braz';
  String _emailNutri = 'juliana.braz@nutri.com';
  bool _isSincronizando = false;

  String get tipoUsuarioLogado => _tipoUsuarioLogado;
  bool get isNutri => _tipoUsuarioLogado == 'NUTRI';
  String get nomeNutri => _nomeNutri;
  String get emailNutri => _emailNutri;
  bool get isSincronizando => _isSincronizando;

  void setTipoUsuarioLogado(String tipo) {
    _tipoUsuarioLogado = tipo;
    notifyListeners();
  }

  void atualizarPerfilNutri({required String nome, required String email}) {
    _nomeNutri = nome;
    _emailNutri = email;
    notifyListeners();
  }

  /// 1. Carrega imediatamente o cache local salvo no dispositivo (0s de espera).
  Future<void> carregarDadosLocaisCache() async {
    try {
      _usernameLogado = await ApiService.getLoggedUsername();
      final jsonList = await ApiService.getPacientesLocaisCache();
      if (jsonList.isNotEmpty) {
        _pacientes
          ..clear()
          ..addAll(
            jsonList.map((e) => PacienteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          );
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 2. Sincroniza em segundo plano com a API do Render (não bloqueia a navegação da UI).
  Future<void> sincronizarComBackend() async {
    _isSincronizando = true;
    notifyListeners();

    try {
      _usernameLogado = await ApiService.getLoggedUsername();
      final jsonList = await ApiService.getPacientes();
      if (jsonList.isNotEmpty) {
        _pacientes
          ..clear()
          ..addAll(
            jsonList.map((e) => PacienteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          );
      }

      // Carregar registros de hoje em paralelo para todos os pacientes (evita loop sequencial)
      await carregarRegistrosDiarios(DateTime.now().toIso8601String().split('T').first);

      // Comunidade é sincronizada sem bloquear os dados clínicos
      unawaited(carregarPostagensComunidade());
    } catch (_) {
    } finally {
      _isSincronizando = false;
      notifyListeners();
    }
  }

  /// Método de compatibilidade que carrega o cache local e inicia a sincronização em nuvem.
  Future<void> carregarDadosDoBackend() async {
    await carregarDadosLocaisCache();
    await sincronizarComBackend();
  }

  Future<void> carregarPostagensComunidade() async {
    try {
      final catsJson = await ApiService.getCategoriasComunidade();
      _categoriasComunidade
        ..clear()
        ..addAll(
          catsJson
              .map((e) => CategoriaComunidadeModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      if (_categoriasComunidade.isEmpty) {
        _categoriasComunidade.addAll(CategoriaComunidadeModel.padroesIniciais);
      }

      final jsonList = await ApiService.getPostagensComunidade();
      _postagensComunidade
        ..clear()
        ..addAll(
          jsonList
              .map((e) => PostagemComunidadeModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
    } catch (_) {}
  }

  List<CategoriaComunidadeModel> getCategoriasComunidade() {
    if (_categoriasComunidade.isEmpty) {
      return CategoriaComunidadeModel.padroesIniciais;
    }
    return List.unmodifiable(_categoriasComunidade);
  }

  Future<CategoriaComunidadeModel> adicionarCategoriaComunidade({
    required String nome,
    String iconeKey = 'receita',
  }) async {
    final slug = CategoriaComunidadeModel.gerarSlug(nome);
    final saved = await ApiService.salvarCategoriaComunidade({
      'slug': slug,
      'nome': nome.trim(),
      'icone': iconeKey,
    });
    final novaCat = CategoriaComunidadeModel.fromJson(saved);
    final idx = _categoriasComunidade.indexWhere((c) => c.slug == novaCat.slug);
    if (idx >= 0) {
      _categoriasComunidade[idx] = novaCat;
    } else {
      _categoriasComunidade.add(novaCat);
    }
    return novaCat;
  }

  Future<CategoriaComunidadeModel> renomearCategoriaComunidade(
    CategoriaComunidadeModel categoriaAtual, {
    required String novoNome,
    String? novoIconeKey,
  }) async {
    final novoSlug = CategoriaComunidadeModel.gerarSlug(novoNome);
    final saved = await ApiService.salvarCategoriaComunidade(
      {
        'id': categoriaAtual.id,
        'slug': novoSlug,
        'nome': novoNome.trim(),
        'icone': novoIconeKey ?? categoriaAtual.iconeKey,
      },
      id: categoriaAtual.id,
      slugAntigo: categoriaAtual.slug,
    );
    final catAtualizada = CategoriaComunidadeModel.fromJson(saved);
    final idx = _categoriasComunidade.indexWhere(
      (c) => c.id == categoriaAtual.id || c.slug == categoriaAtual.slug,
    );
    if (idx >= 0) {
      _categoriasComunidade[idx] = catAtualizada;
    }
    for (int i = 0; i < _postagensComunidade.length; i++) {
      if (_postagensComunidade[i].categoriaSlug == categoriaAtual.slug) {
        _postagensComunidade[i] = _postagensComunidade[i].copyWith(
          categoriaSlug: catAtualizada.slug,
          categoriaNomeCustom: catAtualizada.nome,
        );
      }
    }
    return catAtualizada;
  }

  Future<void> excluirCategoriaComunidade(CategoriaComunidadeModel categoria) async {
    _categoriasComunidade.removeWhere(
      (c) => c.id == categoria.id || c.slug == categoria.slug,
    );
    await ApiService.excluirCategoriaComunidade(categoria.id, categoria.slug);

    final destino = _categoriasComunidade.isNotEmpty
        ? _categoriasComunidade.first
        : CategoriaComunidadeModel.padroesIniciais.first;
    for (int i = 0; i < _postagensComunidade.length; i++) {
      if (_postagensComunidade[i].categoriaSlug == categoria.slug) {
        _postagensComunidade[i] = _postagensComunidade[i].copyWith(
          categoriaSlug: destino.slug,
          categoriaNomeCustom: destino.nome,
        );
      }
    }
  }

  List<PostagemComunidadeModel> getPostagensComunidade() {
    return List.unmodifiable(_postagensComunidade);
  }

  Future<PostagemComunidadeModel> salvarPostagemComunidade(
    PostagemComunidadeModel postagem, {
    bool isEdicao = false,
  }) async {
    final data = postagem.toJson();
    final savedMap = await ApiService.salvarPostagemComunidade(
      data,
      id: isEdicao ? postagem.id : null,
    );
    final novaPostagem = savedMap != null
        ? PostagemComunidadeModel.fromJson(savedMap)
        : postagem;

    final idx = _postagensComunidade.indexWhere((p) => p.id == novaPostagem.id);
    if (idx >= 0) {
      _postagensComunidade[idx] = novaPostagem;
    } else {
      _postagensComunidade.insert(0, novaPostagem);
    }
    return novaPostagem;
  }

  Future<void> excluirPostagemComunidade(String id) async {
    _postagensComunidade.removeWhere((p) => p.id == id);
    await ApiService.excluirPostagemComunidade(id);
  }

  Future<void> alternarCurtidaPostagemComunidade(String id) async {
    final idx = _postagensComunidade.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final post = _postagensComunidade[idx];
      final novoCurtido = !post.curtidoPorMim;
      final novoTotal = post.totalCurtidas + (novoCurtido ? 1 : -1);
      _postagensComunidade[idx] = post.copyWith(
        curtidoPorMim: novoCurtido,
        totalCurtidas: novoTotal < 0 ? 0 : novoTotal,
      );
    }
    final result = await ApiService.alternarCurtidaPostagemComunidade(id);
    if (result != null && idx >= 0 && idx < _postagensComunidade.length) {
      final post = _postagensComunidade[idx];
      _postagensComunidade[idx] = post.copyWith(
        curtidoPorMim: result['curtido_por_mim'] == true,
        totalCurtidas:
            int.tryParse((result['total_curtidas'] ?? 0).toString()) ?? post.totalCurtidas,
      );
    }
  }

  Future<void> alternarSalvarPostagemComunidade(String id) async {
    final idx = _postagensComunidade.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final post = _postagensComunidade[idx];
      _postagensComunidade[idx] = post.copyWith(salvoPorMim: !post.salvoPorMim);
    }
    final result = await ApiService.alternarSalvarPostagemComunidade(id);
    if (result != null && idx >= 0 && idx < _postagensComunidade.length) {
      final post = _postagensComunidade[idx];
      _postagensComunidade[idx] = post.copyWith(
        salvoPorMim: result['salvo_por_mim'] == true,
      );
    }
  }

  Future<void> carregarRegistrosDiarios(String data) async {
    await Future.wait(_pacientes.map((p) async {
      try {
        final regs = await ApiService.getRegistrosDiarios(data, pacienteId: p.id);
        p.registrosDiarios = regs
            .map((e) => RegistroDiarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }));
  }

  Future<void> salvarRegistroDiario(int pacienteId, Map<String, dynamic> data) async {
    final savedData = await ApiService.salvarRegistroDiario(data, id: data['id']?.toString());
    final payload = savedData ?? data;
    final newReg = RegistroDiarioModel.fromJson(payload);

    final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();

    final index = paciente.registrosDiarios.indexWhere(
      (r) => (r.id.isNotEmpty && r.id == newReg.id) || (r.data != null && r.data == newReg.data),
    );
    if (index >= 0) {
      paciente.registrosDiarios[index] = newReg;
    } else {
      paciente.registrosDiarios.insert(0, newReg);
    }
  }

  List<PacienteModel> get pacientes => List.unmodifiable(_pacientes);

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

    return PacienteModel(
      id: 0,
      nome: 'Sem Paciente',
      usuario: 'paciente',
      email: '',
      statusFinanceiro: StatusFinanceiro.pago,
    );
  }

  PacienteModel? getPacientePorId(int id) {
    try {
      return _pacientes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> excluirPaciente(int pacienteId, {String? email}) async {
    _pacientes.removeWhere((p) => p.id == pacienteId || (email != null && p.email?.toLowerCase() == email.toLowerCase()));
    notifyListeners();
    return await ApiService.excluirPaciente(pacienteId, email: email);
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
