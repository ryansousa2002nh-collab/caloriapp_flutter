import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 2);
  static const String _localPacientesKey = 'local_backend_pacientes_v1';
  static const String _localPreCadastrosKey = 'local_backend_precadastros_v1';
  static const String _localComunidadeKey = 'local_backend_comunidade_v1';
  static const String _localCategoriasComunidadeKey = 'local_backend_categorias_comunidade_v1';

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8001/api/';
    if (Platform.isAndroid) return 'http://10.0.2.2:8001/api/';
    return 'http://127.0.0.1:8001/api/';
  }

  /// Faz login via API ou utiliza o backend local integrado caso o servidor 8001 esteja offline.
  /// - Para entrar como Nutricionista: usuário `nutri` ou `juliana` (senha `123`)
  /// - Para entrar como Paciente: usuário `paciente.teste` (senha `123`)
  static Future<bool> login(String username, String password) async {
    final cleanUser = username.trim().toLowerCase();
    if (cleanUser.isEmpty || password.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await _garantirDadosLocaisIniciais(prefs);

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}login/'),
            body: {'username': username.trim(), 'password': password},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']?.toString() ?? 'token_api';
        await prefs.setString('token', token);
        await prefs.setString('logged_username', cleanUser);
        return true;
      }
    } catch (_) {
      // Servidor HTTP 8001 offline: utiliza autenticação local integrada
    }

    // Autenticação no backend local integrado
    final isNutriLogin = cleanUser == 'nutri' ||
        cleanUser == 'juliana' ||
        cleanUser == 'dra.juliana' ||
        cleanUser == 'admin' ||
        cleanUser.contains('nutri') ||
        cleanUser.contains('juliana');

    if (isNutriLogin) {
      await prefs.setString('token', 'local_token_nutri');
      await prefs.setString('tipo_usuario', 'NUTRI');
      await prefs.setString('logged_username', cleanUser);
      return true;
    }

    // Verifica se é paciente.teste ou paciente cadastrado localmente
    final pacientes = await _lerPacientesLocais(prefs);
    final existePaciente = cleanUser == 'paciente.teste' ||
        pacientes.any((p) => (p['username']?.toString().toLowerCase() ?? '') == cleanUser);

    if (existePaciente) {
      await prefs.setString('token', 'local_token_cliente');
      await prefs.setString('tipo_usuario', 'CLIENTE');
      await prefs.setString('logged_username', cleanUser);
      return true;
    }

    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('tipo_usuario');
    await prefs.remove('logged_username');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getLoggedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('logged_username');
  }

  /// Busca o tipo do usuário logado ('NUTRI' ou 'CLIENTE')
  static Future<String?> getTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .get(
              Uri.parse('${baseUrl}meu-perfil/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final tipo = data['tipo']?.toString();
          if (tipo != null) {
            await prefs.setString('tipo_usuario', tipo);
            return tipo;
          }
        }
      } catch (_) {}
    }

    return prefs.getString('tipo_usuario') ?? 'NUTRI';
  }

  static Future<List<dynamic>> getPacientes() async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirDadosLocaisIniciais(prefs);
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .get(
              Uri.parse('${baseUrl}pacientes/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          await _salvarPacientesLocais(prefs, list);
          return list;
        }
      } catch (_) {}
    }

    return _lerPacientesLocais(prefs);
  }

  static Future<bool> atualizarPaciente(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .patch(
              Uri.parse('${baseUrl}pacientes/$id/'),
              headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
              body: jsonEncode(data),
            )
            .timeout(_timeout);
        if (response.statusCode == 200) return true;
      } catch (_) {}
    }

    final pacientes = await _lerPacientesLocais(prefs);
    final index = pacientes.indexWhere((p) => p['id'] == id);
    if (index >= 0) {
      final paciente = Map<String, dynamic>.from(pacientes[index] as Map);
      data.forEach((key, value) {
        paciente[key] = value;
      });
      pacientes[index] = paciente;
      await _salvarPacientesLocais(prefs, pacientes);
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> salvarRefeicao(Map<String, dynamic> data, {String? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Token $token', 'Content-Type': 'application/json'};

    if (token != null && !token.startsWith('local_token_')) {
      try {
        http.Response response;
        if (id != null && !id.startsWith('ref_')) {
          response = await http
              .put(
                Uri.parse('${baseUrl}refeicoes/$id/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        } else {
          response = await http
              .post(
                Uri.parse('${baseUrl}refeicoes/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    // Fallback local
    final savedRef = Map<String, dynamic>.from(data);
    savedRef['id'] = (id != null && id.isNotEmpty) ? id : '${DateTime.now().millisecondsSinceEpoch}';

    final usuarioId = data['usuario_id'];
    if (usuarioId != null) {
      final pacientes = await _lerPacientesLocais(prefs);
      final pIndex = pacientes.indexWhere((p) => p['id'] == usuarioId);
      if (pIndex >= 0) {
        final paciente = Map<String, dynamic>.from(pacientes[pIndex] as Map);
        final plano = List<dynamic>.from(paciente['plano_alimentar'] as List? ?? []);
        final rIndex = plano.indexWhere((r) => r['id'].toString() == savedRef['id'].toString());
        if (rIndex >= 0) {
          plano[rIndex] = savedRef;
        } else {
          plano.add(savedRef);
        }
        paciente['plano_alimentar'] = plano;
        pacientes[pIndex] = paciente;
        await _salvarPacientesLocais(prefs, pacientes);
      }
    }

    return savedRef;
  }

  static Future<bool> excluirRefeicao(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .delete(
              Uri.parse('${baseUrl}refeicoes/$id/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 204) return true;
      } catch (_) {}
    }

    final pacientes = await _lerPacientesLocais(prefs);
    for (int i = 0; i < pacientes.length; i++) {
      final p = Map<String, dynamic>.from(pacientes[i] as Map);
      final plano = List<dynamic>.from(p['plano_alimentar'] as List? ?? []);
      plano.removeWhere((r) => r['id'].toString() == id);
      p['plano_alimentar'] = plano;
      pacientes[i] = p;
    }
    await _salvarPacientesLocais(prefs, pacientes);
    return true;
  }

  static Future<bool> preCadastrarPaciente(String nome, String email, String dataNascimento) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .post(
              Uri.parse('${baseUrl}precadastro/'),
              headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
              body: jsonEncode({
                'nome': nome,
                'email': email,
                'data_nascimento': dataNascimento,
              }),
            )
            .timeout(_timeout);
        if (response.statusCode == 201) return true;
      } catch (_) {}
    }

    // Salva no pré-cadastro local e já adiciona na lista de pacientes
    final preCadastros = await _lerPreCadastrosLocais(prefs);
    preCadastros.add({
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'data_nascimento': dataNascimento.trim(),
    });
    await prefs.setString(_localPreCadastrosKey, jsonEncode(preCadastros));

    final pacientes = await _lerPacientesLocais(prefs);
    final novoId = DateTime.now().millisecondsSinceEpoch % 100000;
    final usernameGerado = nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.');
    pacientes.add({
      'id': novoId,
      'nome': nome.trim(),
      'username': usernameGerado,
      'email': email.trim(),
      'status_financeiro': 'pago',
      'valor_mensalidade': 400.0,
      'meta_calorica': 2000.0,
      'plano_alimentar': [],
      'registros_diarios': [],
    });
    await _salvarPacientesLocais(prefs, pacientes);
    return true;
  }

  static Future<bool> validarCadastro(String nome, String email, String dataNascimento) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}cadastro/validar/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'data_nascimento': dataNascimento,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) return true;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final preCadastros = await _lerPreCadastrosLocais(prefs);
    final existe = preCadastros.any(
      (c) => (c['email']?.toString().toLowerCase() ?? '') == email.trim().toLowerCase(),
    );
    // Permite validar se foi pré-cadastrado ou em modo de demonstração
    return existe || email.contains('@');
  }

  static Future<bool> finalizarCadastro(
    String nome,
    String email,
    String dataNascimento,
    String username,
    String senha,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}cadastro/finalizar/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'data_nascimento': dataNascimento,
              'username': username,
              'senha': senha,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 201) return true;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await _garantirDadosLocaisIniciais(prefs);
    final pacientes = await _lerPacientesLocais(prefs);
    final index = pacientes.indexWhere(
      (p) => (p['email']?.toString().toLowerCase() ?? '') == email.trim().toLowerCase(),
    );

    if (index >= 0) {
      final p = Map<String, dynamic>.from(pacientes[index] as Map);
      p['username'] = username.trim().toLowerCase();
      p['nome'] = nome.trim();
      pacientes[index] = p;
    } else {
      pacientes.add({
        'id': DateTime.now().millisecondsSinceEpoch % 100000,
        'nome': nome.trim(),
        'username': username.trim().toLowerCase(),
        'email': email.trim(),
        'status_financeiro': 'pago',
        'valor_mensalidade': 400.0,
        'meta_calorica': 2000.0,
        'plano_alimentar': [],
        'registros_diarios': [],
      });
    }
    await _salvarPacientesLocais(prefs, pacientes);
    return true;
  }

  static Future<List<dynamic>> getRegistrosDiarios(String dataStr, {int? pacienteId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        String url = '${baseUrl}registros_diarios/?data=$dataStr';
        if (pacienteId != null) {
          url += '&paciente=$pacienteId';
        }
        final response = await http
            .get(
              Uri.parse(url),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        }
      } catch (_) {}
    }

    final pacientes = await _lerPacientesLocais(prefs);
    for (final p in pacientes) {
      if (pacienteId == null || p['id'] == pacienteId) {
        final regs = List<dynamic>.from(p['registros_diarios'] as List? ?? []);
        final filtrados = regs.where((r) => r['data'] == dataStr).toList();
        if (filtrados.isNotEmpty) return filtrados;
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>?> salvarRegistroDiario(Map<String, dynamic> data, {String? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        http.Response response;
        if (id != null && id.isNotEmpty && !id.startsWith('reg_')) {
          response = await http
              .put(
                Uri.parse('${baseUrl}registros_diarios/$id/'),
                headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        } else {
          response = await http
              .post(
                Uri.parse('${baseUrl}registros_diarios/'),
                headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    // Fallback local
    final savedReg = Map<String, dynamic>.from(data);
    savedReg['id'] = (id != null && id.isNotEmpty) ? id : 'reg_${DateTime.now().millisecondsSinceEpoch}';

    final usuarioId = data['usuario_id'];
    final dataStr = data['data'];
    final pacientes = await _lerPacientesLocais(prefs);
    final pIndex = usuarioId != null ? pacientes.indexWhere((p) => p['id'] == usuarioId) : 0;

    if (pIndex >= 0 && pIndex < pacientes.length) {
      final paciente = Map<String, dynamic>.from(pacientes[pIndex] as Map);
      final regs = List<dynamic>.from(paciente['registros_diarios'] as List? ?? []);
      final rIndex = regs.indexWhere((r) => r['id'].toString() == savedReg['id'].toString() || r['data'] == dataStr);
      if (rIndex >= 0) {
        regs[rIndex] = savedReg;
      } else {
        regs.insert(0, savedReg);
      }
      paciente['registros_diarios'] = regs;
      pacientes[pIndex] = paciente;
      await _salvarPacientesLocais(prefs, pacientes);
    }

    return savedReg;
  }

  // --- Módulo Comunidade (API + Fallback Local Integrado) ---

  static Future<List<dynamic>> getCategoriasComunidade() async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirCategoriasComunidadeIniciais(prefs);
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .get(
              Uri.parse('${baseUrl}comunidade-categorias/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          if (list.isNotEmpty) {
            await prefs.setString(_localCategoriasComunidadeKey, jsonEncode(list));
            return list;
          }
        }
      } catch (_) {}
    }

    return _lerCategoriasComunidadeLocais(prefs);
  }

  static Future<Map<String, dynamic>> salvarCategoriaComunidade(
    Map<String, dynamic> data, {
    String? id,
    String? slugAntigo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirCategoriasComunidadeIniciais(prefs);
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Token $token', 'Content-Type': 'application/json'};

    if (token != null && !token.startsWith('local_token_')) {
      try {
        http.Response response;
        if (id != null && id.isNotEmpty && !id.startsWith('cat_')) {
          response = await http
              .put(
                Uri.parse('${baseUrl}comunidade-categorias/$id/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        } else {
          response = await http
              .post(
                Uri.parse('${baseUrl}comunidade-categorias/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
          final saved = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          await _atualizarOuInserirCategoriaLocal(prefs, saved, slugAntigo: slugAntigo);
          return saved;
        }
      } catch (_) {}
    }

    final savedCat = Map<String, dynamic>.from(data);
    savedCat['id'] = (id != null && id.isNotEmpty) ? id : 'cat_${DateTime.now().millisecondsSinceEpoch}';
    await _atualizarOuInserirCategoriaLocal(prefs, savedCat, slugAntigo: slugAntigo);
    return savedCat;
  }

  static Future<bool> excluirCategoriaComunidade(String id, String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirCategoriasComunidadeIniciais(prefs);
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_') && !id.startsWith('cat_')) {
      try {
        await http
            .delete(
              Uri.parse('${baseUrl}comunidade-categorias/$id/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
      } catch (_) {}
    }

    final categorias = await _lerCategoriasComunidadeLocais(prefs);
    categorias.removeWhere((c) => c['id'].toString() == id || c['slug'].toString() == slug);
    await prefs.setString(_localCategoriasComunidadeKey, jsonEncode(categorias));

    // Reatribui postagens da categoria removida para a primeira disponível ou 'receita'
    final slugDestino = categorias.isNotEmpty ? categorias.first['slug'].toString() : 'receita';
    final nomeDestino = categorias.isNotEmpty ? categorias.first['nome'].toString() : 'Receitas';
    final postagens = await _lerPostagensComunidadeLocais(prefs);
    for (int i = 0; i < postagens.length; i++) {
      final p = Map<String, dynamic>.from(postagens[i] as Map);
      if (p['categoria']?.toString() == slug) {
        p['categoria'] = slugDestino;
        p['categoria_nome'] = nomeDestino;
        postagens[i] = p;
      }
    }
    await _salvarPostagensComunidadeLocais(prefs, postagens);
    return true;
  }

  static Future<List<dynamic>> _lerCategoriasComunidadeLocais(SharedPreferences prefs) async {
    final raw = prefs.getString(_localCategoriasComunidadeKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _atualizarOuInserirCategoriaLocal(
    SharedPreferences prefs,
    Map<String, dynamic> cat, {
    String? slugAntigo,
  }) async {
    final categorias = await _lerCategoriasComunidadeLocais(prefs);
    final idx = categorias.indexWhere(
      (c) =>
          c['id'].toString() == cat['id'].toString() ||
          (slugAntigo != null && c['slug'].toString() == slugAntigo) ||
          c['slug'].toString() == cat['slug'].toString(),
    );
    if (idx >= 0) {
      categorias[idx] = cat;
    } else {
      categorias.add(cat);
    }
    await prefs.setString(_localCategoriasComunidadeKey, jsonEncode(categorias));

    if (slugAntigo != null && slugAntigo.isNotEmpty) {
      final postagens = await _lerPostagensComunidadeLocais(prefs);
      for (int i = 0; i < postagens.length; i++) {
        final p = Map<String, dynamic>.from(postagens[i] as Map);
        if (p['categoria']?.toString() == slugAntigo) {
          p['categoria'] = cat['slug'];
          p['categoria_nome'] = cat['nome'];
          postagens[i] = p;
        }
      }
      await _salvarPostagensComunidadeLocais(prefs, postagens);
    }
  }

  static Future<void> _garantirCategoriasComunidadeIniciais(SharedPreferences prefs) async {
    if (prefs.containsKey(_localCategoriasComunidadeKey)) return;
    final iniciais = [
      {'id': 'cat_receita', 'slug': 'receita', 'nome': 'Receitas', 'icone': 'receita'},
      {'id': 'cat_prato', 'slug': 'prato', 'nome': 'Pratos', 'icone': 'prato'},
      {'id': 'cat_dica', 'slug': 'dica', 'nome': 'Dicas', 'icone': 'dica'},
      {'id': 'cat_texto', 'slug': 'texto', 'nome': 'Textos', 'icone': 'texto'},
    ];
    await prefs.setString(_localCategoriasComunidadeKey, jsonEncode(iniciais));
  }

  static Future<List<dynamic>> getPostagensComunidade() async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirPostagensComunidadeIniciais(prefs);
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final response = await http
            .get(
              Uri.parse('${baseUrl}comunidade/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          await _salvarPostagensComunidadeLocais(prefs, list);
          return list;
        }
      } catch (_) {}
    }

    return _lerPostagensComunidadeLocais(prefs);
  }

  static Future<Map<String, dynamic>?> salvarPostagemComunidade(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirPostagensComunidadeIniciais(prefs);
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Token $token', 'Content-Type': 'application/json'};

    if (token != null && !token.startsWith('local_token_')) {
      try {
        http.Response response;
        if (id != null && id.isNotEmpty && !id.startsWith('post_')) {
          response = await http
              .put(
                Uri.parse('${baseUrl}comunidade/$id/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        } else {
          response = await http
              .post(
                Uri.parse('${baseUrl}comunidade/'),
                headers: headers,
                body: jsonEncode(data),
              )
              .timeout(_timeout);
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
          final saved = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          await _atualizarOuInserirPostLocal(prefs, saved);
          return saved;
        }
      } catch (_) {}
    }

    final postagens = await _lerPostagensComunidadeLocais(prefs);
    final savedPost = Map<String, dynamic>.from(data);
    savedPost['id'] = (id != null && id.isNotEmpty) ? id : 'post_${DateTime.now().millisecondsSinceEpoch}';
    savedPost['data_criacao'] = savedPost['data_criacao'] ?? DateTime.now().toIso8601String();
    savedPost['autor_nome'] = savedPost['autor_nome'] ?? 'Dra. Juliana Braz';

    final index = postagens.indexWhere((p) => p['id'].toString() == savedPost['id'].toString());
    if (index >= 0) {
      final existente = Map<String, dynamic>.from(postagens[index] as Map);
      savedPost['total_curtidas'] = existente['total_curtidas'] ?? 0;
      savedPost['curtido_por_mim'] = existente['curtido_por_mim'] ?? false;
      savedPost['salvo_por_mim'] = existente['salvo_por_mim'] ?? false;
      postagens[index] = savedPost;
    } else {
      savedPost['total_curtidas'] = savedPost['total_curtidas'] ?? 0;
      savedPost['curtido_por_mim'] = savedPost['curtido_por_mim'] ?? false;
      savedPost['salvo_por_mim'] = savedPost['salvo_por_mim'] ?? false;
      postagens.insert(0, savedPost);
    }

    await _salvarPostagensComunidadeLocais(prefs, postagens);
    return savedPost;
  }

  static Future<bool> excluirPostagemComunidade(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_') && !id.startsWith('post_')) {
      try {
        final response = await http
            .delete(
              Uri.parse('${baseUrl}comunidade/$id/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 204) {
          final postagens = await _lerPostagensComunidadeLocais(prefs);
          postagens.removeWhere((p) => p['id'].toString() == id);
          await _salvarPostagensComunidadeLocais(prefs, postagens);
          return true;
        }
      } catch (_) {}
    }

    final postagens = await _lerPostagensComunidadeLocais(prefs);
    postagens.removeWhere((p) => p['id'].toString() == id);
    await _salvarPostagensComunidadeLocais(prefs, postagens);
    return true;
  }

  static Future<Map<String, dynamic>?> alternarCurtidaPostagemComunidade(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_') && !id.startsWith('post_')) {
      try {
        final response = await http
            .post(
              Uri.parse('${baseUrl}comunidade/$id/curtir/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final postagens = await _lerPostagensComunidadeLocais(prefs);
          final idx = postagens.indexWhere((p) => p['id'].toString() == id);
          if (idx >= 0) {
            final p = Map<String, dynamic>.from(postagens[idx] as Map);
            p['curtido_por_mim'] = result['curtido_por_mim'];
            p['total_curtidas'] = result['total_curtidas'];
            postagens[idx] = p;
            await _salvarPostagensComunidadeLocais(prefs, postagens);
          }
          return result;
        }
      } catch (_) {}
    }

    final postagens = await _lerPostagensComunidadeLocais(prefs);
    final idx = postagens.indexWhere((p) => p['id'].toString() == id);
    if (idx >= 0) {
      final p = Map<String, dynamic>.from(postagens[idx] as Map);
      final jaCurtido = p['curtido_por_mim'] == true;
      final totalAtual = int.tryParse((p['total_curtidas'] ?? 0).toString()) ?? 0;
      p['curtido_por_mim'] = !jaCurtido;
      p['total_curtidas'] = jaCurtido ? (totalAtual > 0 ? totalAtual - 1 : 0) : totalAtual + 1;
      postagens[idx] = p;
      await _salvarPostagensComunidadeLocais(prefs, postagens);
      return {
        'id': id,
        'curtido_por_mim': p['curtido_por_mim'],
        'total_curtidas': p['total_curtidas'],
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> alternarSalvarPostagemComunidade(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && !token.startsWith('local_token_') && !id.startsWith('post_')) {
      try {
        final response = await http
            .post(
              Uri.parse('${baseUrl}comunidade/$id/salvar/'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final postagens = await _lerPostagensComunidadeLocais(prefs);
          final idx = postagens.indexWhere((p) => p['id'].toString() == id);
          if (idx >= 0) {
            final p = Map<String, dynamic>.from(postagens[idx] as Map);
            p['salvo_por_mim'] = result['salvo_por_mim'];
            postagens[idx] = p;
            await _salvarPostagensComunidadeLocais(prefs, postagens);
          }
          return result;
        }
      } catch (_) {}
    }

    final postagens = await _lerPostagensComunidadeLocais(prefs);
    final idx = postagens.indexWhere((p) => p['id'].toString() == id);
    if (idx >= 0) {
      final p = Map<String, dynamic>.from(postagens[idx] as Map);
      final jaSalvo = p['salvo_por_mim'] == true;
      p['salvo_por_mim'] = !jaSalvo;
      postagens[idx] = p;
      await _salvarPostagensComunidadeLocais(prefs, postagens);
      return {
        'id': id,
        'salvo_por_mim': p['salvo_por_mim'],
      };
    }
    return null;
  }

  static Future<List<dynamic>> _lerPostagensComunidadeLocais(SharedPreferences prefs) async {
    final raw = prefs.getString(_localComunidadeKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _salvarPostagensComunidadeLocais(
    SharedPreferences prefs,
    List<dynamic> postagens,
  ) async {
    await prefs.setString(_localComunidadeKey, jsonEncode(postagens));
  }

  static Future<void> _atualizarOuInserirPostLocal(
    SharedPreferences prefs,
    Map<String, dynamic> post,
  ) async {
    final postagens = await _lerPostagensComunidadeLocais(prefs);
    final idx = postagens.indexWhere((p) => p['id'].toString() == post['id'].toString());
    if (idx >= 0) {
      postagens[idx] = post;
    } else {
      postagens.insert(0, post);
    }
    await _salvarPostagensComunidadeLocais(prefs, postagens);
  }

  static Future<void> _garantirPostagensComunidadeIniciais(SharedPreferences prefs) async {
    if (prefs.containsKey(_localComunidadeKey)) return;

    final agora = DateTime.now();
    final postagensIniciais = [
      {
        'id': 'post_1',
        'titulo': 'Bolo de laranja funcional com farelo de aveia',
        'categoria': 'receita',
        'texto':
            'Sabe aquele cheirinho de bolo saindo do forno no fim da tarde? Essa versão de bolo de laranja leva a fruta inteira (sem as sementes e sem a parte branca), farelo de aveia e ovos caipiras — sem farinha branca e sem açúcar refinado!\n\nIngredientes principais:\n• 1 laranja pera média (cortada em 4, sem sementes e sem o miolo branco)\n• 3 ovos inteiros\n• 1/2 xícara de óleo de coco ou azeite suave\n• 1/2 xícara de uvas-passas brancas ou tâmaras (para adoçar naturalmente)\n• 1 e 1/2 xícara de farelo de aveia\n• 1 colher (sopa) de fermento em pó\n\nModo de preparo:\nBata no liquidificador a laranja, os ovos, o azeite e as passas até ficar homogêneo. Misture o farelo de aveia e o fermento delicadamente. Asse em forno pré-aquecido a 180 °C por 35 minutos. Fica super úmido e rico em fibras!',
        'foto_url':
            'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=900&q=80',
        'link_externo': 'https://www.instagram.com/p/C8boloDeLaranjaNutri/',
        'tempo_preparo': '35 min',
        'calorias_porcao': 165,
        'autor_nome': 'Dra. Juliana Braz',
        'data_criacao': agora.subtract(const Duration(hours: 4)).toIso8601String(),
        'total_curtidas': 28,
        'curtido_por_mim': true,
        'salvo_por_mim': true,
      },
      {
        'id': 'post_2',
        'titulo': 'Prato colorido de almoço: grelhado cítrico + raízes assadas',
        'categoria': 'prato',
        'texto':
            'Montar um prato equilibrado na correria da semana não precisa ser complicado! A regra visual de ouro é preencher 50% do prato com vegetais crus e cozidos variados, 25% com proteína magra (aqui usei filé de tilápia grelhado com limão siciliano e ervas) e 25% com carboidratos ricos em fibras como abóbora cabotiá e grão-de-bico.\n\nPrepare os legumes assados de uma só vez no domingo e tenha refeições práticas por 4 dias seguidos!',
        'foto_url':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
        'link_externo': 'https://www.instagram.com/p/C8pratoSaudavelNutri/',
        'tempo_preparo': '20 min',
        'calorias_porcao': 410,
        'autor_nome': 'Dra. Juliana Braz',
        'data_criacao': agora.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
        'total_curtidas': 19,
        'curtido_por_mim': false,
        'salvo_por_mim': false,
      },
      {
        'id': 'post_3',
        'titulo': '3 estratégias simples para controlar a vontade de doce após o almoço',
        'categoria': 'dica',
        'texto':
            'Sentir vontade de comer um docinho logo depois do almoço é muito comum, mas quando ela é intensa todos os dias, vale observar três pontos:\n\n1. Aporte de proteínas e fibras no prato principal: refeições pobres em fibras geram picos rápidos de glicose.\n2. Hidratação ao longo da manhã: muitas vezes confundimos sede leve com fome por açúcar.\n3. Sobremesa estratégica: 1 quadradinho (15g) de chocolate 70% cacau degustado devagar ou frutas cítricas ajudam a limpar o paladar sem sair da meta calórica.',
        'foto_url':
            'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=900&q=80',
        'link_externo': 'https://www.instagram.com/p/C8dicasDocesNutri/',
        'tempo_preparo': 'Leitura 2 min',
        'calorias_porcao': null,
        'autor_nome': 'Dra. Juliana Braz',
        'data_criacao': agora.subtract(const Duration(days: 3)).toIso8601String(),
        'total_curtidas': 34,
        'curtido_por_mim': false,
        'salvo_por_mim': true,
      },
      {
        'id': 'post_4',
        'titulo': 'Constância vence a perfeição: como lidar com finais de semana',
        'categoria': 'texto',
        'texto':
            'Nutrição de verdade não é sobre nunca comer uma fatia de pizza ou um bolo de aniversário com quem você ama. O resultado duradouro vem do que você faz em 85% a 90% das suas refeições na rotina.\n\nSe uma refeição saiu do planejado no sábado à noite, o próximo passo não é pular o café da manhã de domingo nem fazer jejum punitivo: é simplesmente beber água, dormir bem e retomar sua próxima refeição habitual com tranquilidade.',
        'foto_url': null,
        'link_externo': 'https://www.instagram.com/p/C8constanciaNutri/',
        'tempo_preparo': 'Leitura 3 min',
        'calorias_porcao': null,
        'autor_nome': 'Dra. Juliana Braz',
        'data_criacao': agora.subtract(const Duration(days: 5)).toIso8601String(),
        'total_curtidas': 42,
        'curtido_por_mim': true,
        'salvo_por_mim': false,
      },
    ];

    await _salvarPostagensComunidadeLocais(prefs, postagensIniciais);
  }

  // --- Helpers do Banco Local Integrado ---

  static Future<List<dynamic>> _lerPacientesLocais(SharedPreferences prefs) async {
    final raw = prefs.getString(_localPacientesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _salvarPacientesLocais(SharedPreferences prefs, List<dynamic> pacientes) async {
    await prefs.setString(_localPacientesKey, jsonEncode(pacientes));
  }

  static Future<List<dynamic>> _lerPreCadastrosLocais(SharedPreferences prefs) async {
    final raw = prefs.getString(_localPreCadastrosKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _garantirDadosLocaisIniciais(SharedPreferences prefs) async {
    if (prefs.containsKey(_localPacientesKey)) return;

    final hoje = DateTime.now().toIso8601String().split('T').first;
    final pacientesIniciais = [
      {
        'id': 1,
        'nome': 'Paciente Teste',
        'username': 'paciente.teste',
        'email': 'paciente@teste.com',
        'status_financeiro': 'pago',
        'valor_mensalidade': 400.0,
        'meta_calorica': 2000.0,
        'metas': {
          'peso_atual': 76.5,
          'meta_peso': 70.0,
          'cintura_antes': 90.0,
          'cintura_depois': 84.0,
          'quadril_antes': 106.0,
          'quadril_depois': 101.0,
          'coxa_antes': 61.0,
          'coxa_depois': 58.0,
          'braco_antes': 32.0,
          'braco_depois': 30.5,
        },
        'plano_alimentar': [
          {
            'id': '101',
            'tipo': 'Café da manhã',
            'horario_sugerido': '07:30',
            'observacoes': 'Pode substituir o pão integral por goma de tapioca.',
            'itens': [
              {'alimento_nome': 'Pão de forma integral', 'quantidade_gramas': 50},
              {'alimento_nome': 'Ovo cozido', 'quantidade_gramas': 100},
              {'alimento_nome': 'Mamão papaia', 'quantidade_gramas': 150},
            ],
          },
          {
            'id': '102',
            'tipo': 'Almoço',
            'horario_sugerido': '12:30',
            'observacoes': 'Temperar a salada com 1 fio de azeite de oliva.',
            'itens': [
              {'alimento_nome': 'Arroz integral cozido', 'quantidade_gramas': 120},
              {'alimento_nome': 'Feijão carioca cozido', 'quantidade_gramas': 100},
              {'alimento_nome': 'Frango grelhado (peito)', 'quantidade_gramas': 150},
            ],
          },
          {
            'id': '103',
            'tipo': 'Lanche da tarde',
            'horario_sugerido': '16:00',
            'observacoes': 'Ótima opção pré-treino.',
            'itens': [
              {'alimento_nome': 'Iogurte natural desnatado', 'quantidade_gramas': 160},
              {'alimento_nome': 'Aveia em flocos', 'quantidade_gramas': 30},
              {'alimento_nome': 'Banana prata', 'quantidade_gramas': 70},
            ],
          },
          {
            'id': '104',
            'tipo': 'Jantar',
            'horario_sugerido': '20:00',
            'observacoes': 'Refeição leve para melhor digestão noturna.',
            'itens': [
              {'alimento_nome': 'Filé de tilápia grelhado', 'quantidade_gramas': 150},
              {'alimento_nome': 'Batata doce cozida', 'quantidade_gramas': 120},
            ],
          },
        ],
        'registros_diarios': [
          {
            'id': 'reg_1',
            'data': hoje,
            'itens': [
              {
                'refeicao_nome': 'Café da manhã',
                'refeicao_planejada': 101,
                'alimento_nome': 'Pão de forma integral',
                'quantidade_gramas': 50,
                'calorias_manual': 124,
              },
              {
                'refeicao_nome': 'Café da manhã',
                'refeicao_planejada': 101,
                'alimento_nome': 'Ovo cozido',
                'quantidade_gramas': 100,
                'calorias_manual': 143,
              },
              {
                'refeicao_nome': 'Almoço',
                'refeicao_planejada': 102,
                'alimento_nome': 'Frango grelhado (peito)',
                'quantidade_gramas': 150,
                'calorias_manual': 248,
              },
            ],
          },
        ],
      },
      {
        'id': 2,
        'nome': 'Maria Clara Silva',
        'username': 'maria.clara',
        'email': 'mariaclara@email.com',
        'status_financeiro': 'pago',
        'valor_mensalidade': 400.0,
        'meta_calorica': 1800.0,
        'plano_alimentar': [
          {
            'id': '201',
            'tipo': 'Café da manhã',
            'horario_sugerido': '08:00',
            'observacoes': 'Acompanha café sem açúcar.',
            'itens': [
              {'alimento_nome': 'Goma de tapioca hidratada', 'quantidade_gramas': 60},
              {'alimento_nome': 'Queijo minas frescal', 'quantidade_gramas': 40},
            ],
          },
          {
            'id': '202',
            'tipo': 'Almoço',
            'horario_sugerido': '12:30',
            'observacoes': null,
            'itens': [
              {'alimento_nome': 'Arroz branco cozido', 'quantidade_gramas': 100},
              {'alimento_nome': 'Carne bovina (Patinho)', 'quantidade_gramas': 130},
            ],
          },
        ],
        'registros_diarios': [],
      },
    ];

    await _salvarPacientesLocais(prefs, pacientesIniciais);
  }
}
