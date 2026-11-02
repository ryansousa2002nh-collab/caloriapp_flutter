import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/biometria_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import 'pacientes_page.dart';
import 'refeicoes_page.dart';
import 'cadastro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');

  String _erro = '';
  bool _carregando = false;
  bool _senhaOculta = true;
  bool _podeBiometria = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Dispara o pré-aquecimento invisível no Render enquanto o usuário digita
    ApiService.aquecerServidorSilencioso();

    BiometriaService.isBiometriaAtiva().then((ativa) {
      if (ativa && mounted) {
        setState(() => _podeBiometria = true);
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _fazerLoginComBiometria() async {
    final autenticou = await BiometriaService.autenticar(
      motivo: 'Toque no sensor para entrar rapidamente no Nutri+',
    );
    if (autenticou) {
      await _fazerLogin();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Autenticação biométrica não confirmada. Digite sua senha.',
          ),
        ),
      );
    }
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
        final dadosService = DadosService();
        dadosService.setTipoUsuarioLogado(tipoStr);

        // 1. Carrega dados salvos em cache imediatamente (milissegundos)
        await dadosService.carregarDadosLocaisCache();

        // 2. Dispara a sincronização com o Render em segundo plano (não trava a tela de login)
        unawaited(dadosService.sincronizarComBackend());

        if (!mounted) return;
        setState(() => _carregando = false);

        if (tipoStr == 'NUTRI') {
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
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFAF9F5),
                      border: Border.all(
                        color: const Color(0xFFDCE3CE),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo_nutri.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  //O NOME DO APP POSSIVELMENTE FICARÁ AQUI...
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cuidado que nutre, saúde que floresce.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
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
                        icon: Icon(
                          _senhaOculta
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _senhaOculta = !_senhaOculta),
                      ),
                    ),
                  ),

                  if (_erro.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _erro,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                  if (_podeBiometria) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _carregando ? null : _fazerLoginComBiometria,
                        icon: const Icon(
                          Icons.fingerprint,
                          size: 22,
                          color: AppColors.verde,
                        ),
                        label: const Text(
                          'Entrar com Biometria',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.verde,
                          side: const BorderSide(
                            color: AppColors.verde,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CadastroPage(),
                      ),
                    ),
                    child: Text(
                      'Não tem conta? Cadastre-se',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
