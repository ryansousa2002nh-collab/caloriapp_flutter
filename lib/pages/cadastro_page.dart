import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  int _etapa = 1;
  bool _carregando = false;

  // Controladores Etapa 1
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  // Controladores Etapa 2
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaOculta = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _dataNascimentoController.dispose();
    _usernameController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _validarConvite() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    var data = _dataNascimentoController.text.trim();

    if (nome.isEmpty || email.isEmpty || data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (data.contains('/')) {
      final parts = data.split('/');
      if (parts.length == 3) {
        data = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    setState(() => _carregando = true);
    final sucesso = await ApiService.validarCadastro(nome, email, data);
    setState(() => _carregando = false);

    if (!mounted) return;

    if (sucesso) {
      setState(() => _etapa = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email não cadastrado ou dados incorretos.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  Future<void> _finalizarCadastro() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    var data = _dataNascimentoController.text.trim();
    final username = _usernameController.text.trim();
    final senha = _senhaController.text;

    if (username.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (data.contains('/')) {
      final parts = data.split('/');
      if (parts.length == 3) {
        data = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    if (senha.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter no mínimo 8 caracteres.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    setState(() => _carregando = true);
    final sucesso = await ApiService.finalizarCadastro(nome, email, data, username, senha);
    setState(() => _carregando = false);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário criado com sucesso! Faça seu login.'),
          backgroundColor: AppColors.verde,
        ),
      );
      Navigator.pop(context); // Volta para a tela de Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao finalizar o cadastro. O usuário já pode existir.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 340,
            child: _etapa == 1 ? _buildEtapa1() : _buildEtapa2(),
          ),
        ),
      ),
    );
  }

  Widget _buildEtapa1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validação',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextoPrincipal(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha os mesmos dados informados à sua nutricionista para liberar seu acesso.',
          style: TextStyle(color: AppColors.getTextoSecundario(context)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome Completo',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dataNascimentoController,
          keyboardType: TextInputType.datetime,
          inputFormatters: [DateInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento (DD/MM/AAAA)',
            prefixIcon: Icon(Icons.calendar_today),
            hintText: 'Ex: 24/05/1990',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _carregando ? null : _validarConvite,
            child: _carregando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildEtapa2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quase lá!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextoPrincipal(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie seu nome de usuário e uma senha segura.',
          style: TextStyle(color: AppColors.getTextoSecundario(context)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Nome de Usuário (Login)',
            prefixIcon: Icon(Icons.account_circle),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _senhaController,
          obscureText: _senhaOculta,
          decoration: InputDecoration(
            labelText: 'Criar Senha',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_senhaOculta ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() => _senhaOculta = !_senhaOculta);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _carregando ? null : _finalizarCadastro,
            child: _carregando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Finalizar Cadastro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
