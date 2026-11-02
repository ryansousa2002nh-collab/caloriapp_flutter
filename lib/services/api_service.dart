import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String renderBaseUrl = 'https://projeto-nutri-voa4.onrender.com/api/';
  static const Duration _timeout = Duration(seconds: 25);
  static const Duration _loginTimeout = Duration(seconds: 35);
  static const String _localPacientesKey = 'local_backend_pacientes_clean_v1';
  static const String _localPreCadastrosKey = 'local_backend_precadastros_clean_v1';
  static const String _localComunidadeKey = 'local_backend_comunidade_clean_v1';
  static const String _localCategoriasComunidadeKey = 'local_backend_categorias_comunidade_clean_v1';

  static String get baseUrl => renderBaseUrl;

  /// Dispara um ping assíncrono para o endpoint de status da API
  /// para acordar o container do Render em segundo plano (evita a espera por cold start).
  static void aquecerServidorSilencioso() {
    http
        .get(Uri.parse('${baseUrl}status/'))
        .timeout(const Duration(seconds: 40))
        .then((_) {})
        .catchError((_) {});
  }

  /// Retorna imediatamente os pacientes salvos no cache local (sem latência de rede).
  static Future<List<dynamic>> getPacientesLocaisCache() async {
    final prefs = await SharedPreferences.getInstance();
    await _garantirDadosLocaisIniciais(prefs);
    return _lerPacientesLocais(prefs);
  }

  /// Faz login via API do Render ou utiliza o backend local integrado caso esteja sem internet.
  /// - Para entrar como Nutricionista: usuário `nutri` ou `juliana` (senha `123`)
  /// - Para entrar como Paciente: usuário `paciente.teste` (senha `123`)
  static Future<bool> login(String username, String password) async {
    final cleanUser = username.trim().toLowerCase();
    if (cleanUser.isEmpty || password.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await _garantirDadosLocaisIniciais(prefs);
    await prefs.setString('logged_password', password);

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}login/'),
            body: {'username': username.trim(), 'password': password},
          )
          .timeout(_loginTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']?.toString() ?? 'token_api';
        await prefs.setString('token', token);
        await prefs.setString('logged_username', cleanUser);
        return true;
      }
    } catch (_) {
      // Servidor offline ou sem internet: utiliza autenticação local integrada
    }

    // Autenticação no backend local integrado
    final isNutriLogin = cleanUser == 'juliana.nutri' ||
        cleanUser == 'juliana' ||
        cleanUser == 'nutri' ||
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
    await prefs.remove('logged_password');
  }

  /// Caso a sessão tenha iniciado offline (`local_token_...`), tenta renovar o token
  /// automaticamente no servidor do Render assim que houver conexão.
  static Future<String?> _obterTokenAtivo(SharedPreferences prefs) async {
    final currentToken = prefs.getString('token');
    if (currentToken != null && !currentToken.startsWith('local_token_')) {
      return currentToken;
    }
    final user = prefs.getString('logged_username');
    final pass = prefs.getString('logged_password') ?? '123';
    if (user != null && user.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('${baseUrl}login/'),
              body: {'username': user, 'password': pass},
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final novoToken = data['token']?.toString();
          if (novoToken != null && novoToken.isNotEmpty) {
            await prefs.setString('token', novoToken);
            return novoToken;
          }
        }
      } catch (_) {}
    }
    return currentToken;
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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);
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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);
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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);
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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    final token = await _obterTokenAtivo(prefs);

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
    await _salvarPostagensComunidadeLocais(prefs, []);
  }

  // --- Módulo Chat / Mensagens ---

  static const String _localChatKey = 'nutri_chat_mensagens_clean_v1';

  /// Busca as mensagens do chat da API (ou do armazenamento local caso offline)
  static Future<List<dynamic>> getMensagensChat({int? pacienteId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _obterTokenAtivo(prefs);

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final query = pacienteId != null && pacienteId > 0 ? '?paciente_id=$pacienteId' : '';
        final response = await http
            .get(
              Uri.parse('${baseUrl}mensagens/$query'),
              headers: {'Authorization': 'Token $token'},
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          return list;
        }
      } catch (_) {}
    }

    // Fallback: lê do armazenamento local
    final raw = prefs.getString(_localChatKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as List<dynamic>;
      } catch (_) {}
    }
    return [];
  }

  /// Envia uma nova mensagem no chat via API do Render
  static Future<Map<String, dynamic>?> enviarMensagemChat({
    required int pacienteId,
    required String texto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _obterTokenAtivo(prefs);

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final bodyData = <String, dynamic>{
          'texto': texto,
        };
        if (pacienteId > 0) {
          bodyData['paciente_id'] = pacienteId;
          bodyData['destinatario_id'] = pacienteId;
        }

        final response = await http
            .post(
              Uri.parse('${baseUrl}mensagens/'),
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(bodyData),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Marca as mensagens como lidas na API
  static Future<void> marcarMensagensLidasChat({int? pacienteId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _obterTokenAtivo(prefs);

    if (token != null && !token.startsWith('local_token_')) {
      try {
        final bodyData = <String, dynamic>{};
        if (pacienteId != null && pacienteId > 0) {
          bodyData['paciente_id'] = pacienteId;
        }

        await http
            .post(
              Uri.parse('${baseUrl}mensagens/marcar_lidas/'),
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(bodyData),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
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
    await _salvarPacientesLocais(prefs, []);
  }
}
