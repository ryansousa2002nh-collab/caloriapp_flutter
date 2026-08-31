import 'package:flutter/material.dart'; //RESPONSÁVEL POR TODO MATERIAl DART.
import '../services/api_service.dart'; //RESPONSÁVEL POR TODO O MATERIAl DE API.
import '../services/dados_service.dart'; //RESPONSÁVEL POR TODO O MATERIAl DE DADOS.
import '../theme/app_theme.dart'; //RESPONSÁVEL POR TODO O MATERIAl DE THEME (DA PASTA TEMAS).
import '../widgets/apple_theme_toggle.dart'; //RESPONSÁVEL POR TODO O MATERIAl DE WIDGETS.

import 'pacientes_page.dart'; //RESPONSÁVEL POR TODO O MATERIAl DE PÁGINA DE PACIENTES.
import 'refeicoes_page.dart'; //RESPONSÁVEL POR TODO O MATERIA DE PÁGINA DE REFEIÇÕES.
import 'treinos_page.dart'; //RESPONSÁVEL PELO MÓDULO DE TREINOS.

class LoginPage extends StatefulWidget { //É A TELA
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> { //É O QUE ESTÁ ACONTECENDO COM A TELA
  final _usernameController = TextEditingController(text: 'juliana.nutri');
  final _passwordController = TextEditingController(text: '123456');

  String _erro = '';
  bool _carregando = false;
  String _servicoSelecionado = 'DIETA'; // Pode ser 'DIETA' ou 'TREINO'
  bool _senhaOculta = true;

  //FUTURE SIGNIFICA QUE A FUNÇÃO REALIZA ALGO QUE PODE DEMORAR (NO CASO O LOGIN).
  Future<void> _fazerLogin() async {
    setState(() {
      _erro = '';
      _carregando = true;
    });

    try {
      final sucesso = await ApiService.login(
        _usernameController.text.trim(), //o trim() remove os espaços das extremidades
        _passwordController.text,
      );

      if (!mounted) return;

      if (sucesso) {
        final tipo = await ApiService.getTipoUsuario() ?? 'NUTRI';
        
        DadosService().setTipoUsuarioLogado(tipo);
        await DadosService().carregarDadosDoBackend();

        if (!mounted) return;
        setState(() => _carregando = false);

        if (tipo == 'NUTRI' || tipo == 'PERSONAL') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PacientesPage()),
          );
        } else {
          if (_servicoSelecionado == 'TREINO') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TreinosPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RefeicoesPage()),
            );
          }
        }
      } else {
        setState(() {
          _erro = 'Usuário ou senha inválidos';
          _carregando = false;
        });
      }
    } catch (_) {
      setState(() {
        _erro = 'Usuário ou senha inválidos'; 
        _carregando = false;
      });
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
                  obscureText: _senhaOculta,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaOculta ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaOculta = !_senhaOculta;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha o serviço:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textoSecundario,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _servicoSelecionado = 'DIETA'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _servicoSelecionado == 'DIETA' ? AppColors.verde : Colors.transparent,
                            border: Border.all(color: _servicoSelecionado == 'DIETA' ? AppColors.verde : Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'DIETA',
                            style: TextStyle(
                              color: _servicoSelecionado == 'DIETA' ? Colors.white : textoSecundario,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _servicoSelecionado = 'TREINO'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _servicoSelecionado == 'TREINO' ? AppColors.verde : Colors.transparent,
                            border: Border.all(color: _servicoSelecionado == 'TREINO' ? AppColors.verde : Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'TREINO',
                            style: TextStyle(
                              color: _servicoSelecionado == 'TREINO' ? Colors.white : textoSecundario,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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


              ],
            ),
          ),
        ),
      ),
    );
  }
}
