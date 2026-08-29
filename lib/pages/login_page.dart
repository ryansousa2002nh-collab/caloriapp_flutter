import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_theme_toggle.dart';
import 'pacientes_page.dart';
import 'refeicoes_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'juliana.nutri');
  final _passwordController = TextEditingController(text: '123456');

  String _erro = '';
  bool _carregando = false;

  Future<void> _fazerLogin() async {
    setState(() {
      _erro = '';
      _carregando = true;
    });

    try {
      final sucesso = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (sucesso) {
        final tipo = await ApiService.getTipoUsuario() ?? 'NUTRI';
        DadosService().setTipoUsuarioLogado(tipo);

        if (!mounted) return;
        setState(() => _carregando = false);

        if (tipo == 'NUTRI' || tipo == 'PERSONAL') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PacientesPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RefeicoesPage()),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback para modo offline / demonstração
    }

    // Se o backend não estiver respondendo na porta 8001, permite login direto com o mock
    final username = _usernameController.text.trim().toLowerCase();
    final tipo = username.contains('paciente') || username.contains('ana') || username.contains('cliente')
        ? 'CLIENTE'
        : 'NUTRI';

    DadosService().setTipoUsuarioLogado(tipo);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (tipo == 'NUTRI') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PacientesPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RefeicoesPage()),
      );
    }
  }

  void _entrarComoNutri() {
    DadosService().setTipoUsuarioLogado('NUTRI');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PacientesPage()),
    );
  }

  void _entrarComoPaciente() {
    DadosService().setTipoUsuarioLogado('CLIENTE');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RefeicoesPage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textoPrincipal = AppColors.getTextoPrincipal(context);
    final textoSecundario = AppColors.getTextoSecundario(context);
    final fundoDestaque = AppColors.getVerdeDestaque(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: AppleThemeToggle(size: 30, showBackground: true),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Título
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fundoDestaque,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 44,
                    color: AppColors.verde,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CaloriApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestão Nutricional & Controle Calórico',
                  style: TextStyle(color: textoSecundario, fontSize: 13),
                ),

                const SizedBox(height: 28),

                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                if (_erro.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro,
                    style: const TextStyle(color: AppColors.vermelho, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Botões de Acesso Rápido de Demonstração
                Text(
                  'Acesso Rápido para Testes:',
                  style: TextStyle(fontSize: 11, color: textoSecundario, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppColors.verde),
                        ),
                        onPressed: _entrarComoNutri,
                        icon: const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.verde),
                        label: const Text('Nutri', style: TextStyle(color: AppColors.verde, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: textoSecundario),
                        ),
                        onPressed: _entrarComoPaciente,
                        icon: Icon(Icons.person_outline, size: 16, color: textoSecundario),
                        label: Text('Paciente', style: TextStyle(color: textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
