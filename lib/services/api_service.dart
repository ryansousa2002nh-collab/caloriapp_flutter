import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.103:8001/api/'; 

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
}