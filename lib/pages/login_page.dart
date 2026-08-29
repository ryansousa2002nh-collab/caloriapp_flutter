import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'refeicoes_page.dart';
import 'pacientes_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _erro = '';
  bool _carregando = false;

  Future<void> _fazerLogin() async {
    setState(() {
      _erro = '';
      _carregando = true;
    });

    final sucesso = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!sucesso) {
      setState(() {
        _erro = 'Usuário ou senha inválidos.';
        _carregando = false;
      });
      return;
    }

    final tipo = await ApiService.getTipoUsuario();

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    if (tipo == 'NUTRI' || tipo == 'PERSONAL') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PacientesPage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RefeicoesPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 16),

                if (_erro.isNotEmpty)
                  Text(
                    _erro,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),

                if (_erro.isNotEmpty)
                  const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

