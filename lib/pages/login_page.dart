import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import 'pacientes_page.dart';
import 'pacientes_treino_page.dart';
import 'refeicoes_page.dart';
import 'treinos_page.dart';
import 'cadastro_page.dart';

enum UserRole { personal, nutri, paciente }
enum ServiceType { dieta, treino }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController(text: 'paciente.teste');
  final _passwordController = TextEditingController(text: '123'); 

  String _erro = '';
  bool _carregando = false;
  ServiceType _servicoSelecionado = ServiceType.dieta;
  bool _senhaOculta = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

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
        final tipoStr = await ApiService.getTipoUsuario() ?? 'NUTRI';
        DadosService().setTipoUsuarioLogado(tipoStr);
        await DadosService().carregarDadosDoBackend();

        if (!mounted) return;
        setState(() => _carregando = false);

        if (tipoStr == 'PERSONAL') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PacientesTreinoPage()));
        } else if (tipoStr == 'NUTRI') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PacientesPage()));
        } else {
          if (_servicoSelecionado == ServiceType.treino) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TreinosPage()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RefeicoesPage()));
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
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildServiceOption(ServiceType type, String label, IconData icon) {
    final isSelected = _servicoSelecionado == type;
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _servicoSelecionado = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            border: Border.all(color: isSelected ? theme.primaryColor : theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_rounded, size: 56, color: theme.primaryColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('CaloriApp', style: theme.textTheme.titleLarge?.copyWith(fontSize: 32)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Alcance seus resultados.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: _senhaOculta,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_senhaOculta ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Qual o seu foco hoje?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildServiceOption(ServiceType.dieta, 'DIETA', Icons.restaurant),
                      const SizedBox(width: AppSpacing.md),
                      _buildServiceOption(ServiceType.treino, 'TREINO', Icons.fitness_center),
                    ],
                  ),

                  if (_erro.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_erro, style: TextStyle(color: theme.colorScheme.error, fontSize: 14), textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroPage())),
                    child: Text('Não tem conta? Cadastre-se', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
