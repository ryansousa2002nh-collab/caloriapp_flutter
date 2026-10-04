import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8001/api/';
    if (Platform.isAndroid) return 'http://10.0.2.2:8001/api/';
    return 'http://127.0.0.1:8001/api/';
  } 

  // Faz login e salva o token se der certo
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login/'),
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return true;
    }

    return false;
  }

  // Busca o token salvo
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Busca o tipo do usuário logado (NUTRI, PERSONAL ou CLIENTE)
  static Future<String?> getTipoUsuario() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('${baseUrl}meu-perfil/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tipo'];
    }

    return null;
  }

  static Future<List<dynamic>> getPacientes() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${baseUrl}pacientes/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<bool> atualizarPaciente(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('${baseUrl}pacientes/$id/'),
      headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> salvarRefeicao(Map<String, dynamic> data, {String? id}) async {
    final token = await getToken();
    http.Response response;
    final headers = {'Authorization': 'Token $token', 'Content-Type': 'application/json'};
    
    if (id != null && !id.startsWith('ref_')) {
      response = await http.put(
        Uri.parse('${baseUrl}refeicoes/$id/'),
        headers: headers,
        body: jsonEncode(data),
      );
    } else {
      response = await http.post(
        Uri.parse('${baseUrl}refeicoes/'),
        headers: headers,
        body: jsonEncode(data),
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  static Future<bool> excluirRefeicao(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('${baseUrl}refeicoes/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  static Future<List<dynamic>> getExercicios() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${baseUrl}exercicios/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<bool> salvarTreino(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${baseUrl}treinos/'),
      headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<List<dynamic>> getMeusTreinos() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${baseUrl}treinos/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<bool> marcarTreinoConcluido(int treinoId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${baseUrl}treinos/$treinoId/concluir/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> preCadastrarPaciente(String nome, String email, String dataNascimento) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${baseUrl}precadastro/'),
      headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'data_nascimento': dataNascimento
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> validarCadastro(String nome, String email, String dataNascimento) async {
    final response = await http.post(
      Uri.parse('${baseUrl}cadastro/validar/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'data_nascimento': dataNascimento
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> finalizarCadastro(String nome, String email, String dataNascimento, String username, String senha) async {
    final response = await http.post(
      Uri.parse('${baseUrl}cadastro/finalizar/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'data_nascimento': dataNascimento,
        'username': username,
        'senha': senha
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getRegistrosDiarios(String dataStr, {int? pacienteId}) async {
    final token = await getToken();
    String url = '${baseUrl}registros_diarios/?data=$dataStr';
    if (pacienteId != null) {
      url += '&paciente=$pacienteId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<Map<String, dynamic>?> salvarRegistroDiario(Map<String, dynamic> data, {String? id}) async {
    final token = await getToken();
    http.Response response;
    if (id != null && id.isNotEmpty) {
      response = await http.put(
        Uri.parse('${baseUrl}registros_diarios/$id/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } else {
      response = await http.post(
        Uri.parse('${baseUrl}registros_diarios/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }
}