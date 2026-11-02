import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../services/chat_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';
import 'chat_nutri_page.dart';
import 'conversas_nutri_page.dart';
import 'criar_dieta_page.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  final DadosService _dadosService = DadosService();
  String _filtroTexto = '';

  List<PacienteModel> get _pacientesFiltrados {
    return _dadosService.getPacientes().where((paciente) {
      final matchesTexto = paciente.nome.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          paciente.usuario.toLowerCase().contains(_filtroTexto.toLowerCase());
      return matchesTexto;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _dadosService.addListener(_onDadosModificados);
  }

  @override
  void dispose() {
    _dadosService.removeListener(_onDadosModificados);
    super.dispose();
  }

  void _onDadosModificados() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _recarregarPacientes() async {
    await _dadosService.sincronizarComBackend();
  }

  @override
  Widget build(BuildContext context) {
    final todosPacientes = _dadosService.getPacientes();
    final comDietaPrescrita = todosPacientes.where((p) => p.planoAlimentar.isNotEmpty).length;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pacientes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_dadosService.isSincronizando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.verde),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: ChatService(),
            builder: (context, _) {
              final totalNaoLidas = ChatService().obterTotalNaoLidasParaNutri();
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Mensagens dos Pacientes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConversasNutriPage()),
                      );
                    },
                  ),
                  if (totalNaoLidas > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.rosaVibrante,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$totalNaoLidas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const AppleThemeToggle(size: 28),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _recarregarPacientes,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.verde,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            tooltip: 'Adicionar paciente',
            onPressed: _abrirModalAdicionarPaciente,
          ),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'pacientes'),
      body: RefreshIndicator(
        onRefresh: _recarregarPacientes,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtítulo descritivo
                    Text(
                      'Gerencie seus pacientes e prescreva planos alimentares personalizados.',
                      style: TextStyle(
                        color: AppColors.getTextoSecundario(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cards de métricas rápidas no topo
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Total de Pacientes',
                            valor: '${todosPacientes.length}',
                            cor: AppColors.getTextoPrincipal(context),
                            fundo: AppColors.getCard(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Com Dieta Ativa',
                            valor: '$comDietaPrescrita',
                            cor: isDark ? const Color(0xFF4ADE80) : AppColors.verde,
                            fundo: AppColors.getVerdeDestaque(context),
                            borda: AppColors.getVerdeDestaqueBorda(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Barra de busca
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar paciente por nome ou usuário...',
                        hintStyle: TextStyle(color: AppColors.getTextoSecundario(context)),
                        prefixIcon: Icon(Icons.search, color: AppColors.getTextoSecundario(context)),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (valor) {
                        setState(() => _filtroTexto = valor);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Lista de pacientes
            _pacientesFiltrados.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 56, color: AppColors.getTextoSecundario(context)),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum paciente encontrado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tente alterar os termos de busca ou adicione um novo paciente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final paciente = _pacientesFiltrados[index];
                          return _buildPacienteCard(paciente);
                        },
                        childCount: _pacientesFiltrados.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String valor,
    required Color cor,
    required Color fundo,
    Color? borda,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borda ?? AppColors.getBorda(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context))),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cor),
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteCard(PacienteModel paciente) {
    final isDark = AppColors.isDark(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CriarDietaPage(
                paciente: paciente,
                isNutri: true, // nutricionista tem permissão de edição
              ),
            ),
          );
          setState(() {}); // atualiza ao voltar
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar com foto ou iniciais
              Hero(
                tag: 'paciente_avatar_${paciente.id}',
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
                  backgroundImage: paciente.fotoUrl != null ? NetworkImage(paciente.fotoUrl!) : null,
                  child: paciente.fotoUrl == null
                      ? Text(
                          paciente.nome.isNotEmpty ? paciente.nome[0].toUpperCase() : 'P',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Informações do Paciente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${paciente.usuario}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextoSecundario(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 13, color: Colors.orange.shade700),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Consumido Hoje: ${paciente.totalCaloriasConsumidasHoje} / ${paciente.metaCalorica.toStringAsFixed(0)} kcal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textoSecundarioEscuro : AppColors.getTextoSecundario(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AnimatedBuilder(
                animation: ChatService(),
                builder: (context, _) {
                  final naoLidas = ChatService().obterNaoLidasDoPaciente(paciente.id);
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: naoLidas > 0,
                      label: Text('$naoLidas'),
                      backgroundColor: AppColors.rosaVibrante,
                      child: const Icon(Icons.chat_outlined, size: 20, color: AppColors.verde),
                    ),
                    tooltip: 'Conversar com ${paciente.nome}',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatNutriPage(
                            paciente: paciente,
                            isNutri: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.getTextoSecundario(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalAdicionarPaciente() {
    final nomeController = TextEditingController();
    final dataNascimentoController = TextEditingController();
    final emailController = TextEditingController();
    bool carregando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adicionar Paciente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça o pré-cadastro para o paciente criar sua conta no aplicativo.',
                    style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail do Paciente',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dataNascimentoController,
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
                      onPressed: carregando
                          ? null
                          : () async {
                              final nome = nomeController.text.trim();
                              final email = emailController.text.trim();
                              var data = dataNascimentoController.text.trim();

                              if (nome.isEmpty || email.isEmpty || data.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Preencha todos os campos')),
                                );
                                return;
                              }

                              // Converter DD/MM/AAAA para AAAA-MM-DD pro backend
                              if (data.contains('/')) {
                                final parts = data.split('/');
                                if (parts.length == 3) {
                                  data = '${parts[2]}-${parts[1]}-${parts[0]}';
                                }
                              }

                              setModalState(() => carregando = true);
                              final sucesso = await ApiService.preCadastrarPaciente(nome, email, data);
                              setModalState(() => carregando = false);

                              if (!context.mounted) return;

                              if (sucesso) {
                                Navigator.pop(context);
                                await _recarregarPacientes();
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Paciente cadastrado com sucesso!'),
                                    backgroundColor: AppColors.verde,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao cadastrar paciente. Verifique os dados.'),
                                    backgroundColor: AppColors.vermelho,
                                  ),
                                );
                              }
                            },
                      child: carregando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Cadastrar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
