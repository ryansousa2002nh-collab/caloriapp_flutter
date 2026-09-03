import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_theme_toggle.dart';
import 'criar_treino_page.dart';
import 'login_page.dart';

class PacientesTreinoPage extends StatefulWidget {
  const PacientesTreinoPage({super.key});

  @override
  State<PacientesTreinoPage> createState() => _PacientesTreinoPageState();
}

class _PacientesTreinoPageState extends State<PacientesTreinoPage> {
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
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Alunos (Treinos)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          const AppleThemeToggle(size: 28),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecione um aluno para gerenciar seus treinos.',
                      style: TextStyle(
                        color: AppColors.getTextoSecundario(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Barra de busca
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar aluno...',
                        hintStyle: TextStyle(color: AppColors.getTextoSecundario(context)),
                        prefixIcon: Icon(Icons.search, color: AppColors.getTextoSecundario(context)),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.getBorda(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.getBorda(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
                        ),
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
                            Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum aluno encontrado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextoPrincipal(context),
                              ),
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
                          return _buildPacienteCard(paciente, isDark);
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

  Widget _buildPacienteCard(PacienteModel paciente, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CriarTreinoPage(paciente: paciente),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
                child: Text(
                  paciente.nome.isNotEmpty ? paciente.nome[0].toUpperCase() : 'P',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                  ],
                ),
              ),

              const SizedBox(width: 8),
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
}
