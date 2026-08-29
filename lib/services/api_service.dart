import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8001/api/'; // endereço do backend Django

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
}