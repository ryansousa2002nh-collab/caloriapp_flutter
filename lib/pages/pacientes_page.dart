import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';
import 'criar_dieta_page.dart';

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  final DadosService _dadosService = DadosService();
  String _filtroTexto = '';
  String _filtroStatus = 'todos'; // 'todos', 'pago', 'debito'

  List<PacienteModel> get _pacientesFiltrados {
    return _dadosService.getPacientes().where((paciente) {
      final matchesTexto = paciente.nome.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          paciente.usuario.toLowerCase().contains(_filtroTexto.toLowerCase());
      if (!matchesTexto) return false;

      if (_filtroStatus == 'pago') return paciente.isPago;
      if (_filtroStatus == 'debito') return paciente.isDebito;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todosPacientes = _dadosService.getPacientes();
    final totalPagos = todosPacientes.where((p) => p.isPago).length;
    final totalDebitos = todosPacientes.where((p) => p.isDebito).length;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pacientes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          const AppleThemeToggle(size: 28),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'pacientes'),
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
                    // Subtítulo descritivo
                    Text(
                      'Gerencie seus pacientes, planos alimentares e situação financeira.',
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
                            label: 'Total',
                            valor: '${todosPacientes.length}',
                            cor: AppColors.getTextoPrincipal(context),
                            fundo: AppColors.getCard(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Em dia',
                            valor: '$totalPagos',
                            cor: isDark ? const Color(0xFF4ADE80) : AppColors.verde,
                            fundo: AppColors.getVerdeDestaque(context),
                            borda: AppColors.getVerdeDestaqueBorda(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Em débito',
                            valor: '$totalDebitos',
                            cor: isDark ? const Color(0xFFF87171) : AppColors.vermelho,
                            fundo: AppColors.getVermelhoDestaque(context),
                            borda: AppColors.getVermelhoDestaqueBorda(context),
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

                    // Filtros de Status (Chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Todos (${todosPacientes.length})', 'todos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Em dia ($totalPagos)', 'pago', corAtiva: AppColors.verde),
                          const SizedBox(width: 8),
                          _buildFilterChip('Em débito ($totalDebitos)', 'debito', corAtiva: AppColors.vermelho),
                        ],
                      ),
                    ),
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
                              'Nenhum paciente encontrado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tente alterar os termos de busca ou o filtro de status.',
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

  Widget _buildFilterChip(String label, String valor, {Color corAtiva = AppColors.verde}) {
    final selecionado = _filtroStatus == valor;
    final isDark = AppColors.isDark(context);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selecionado ? FontWeight.w700 : FontWeight.normal,
          color: selecionado ? Colors.white : AppColors.getTextoPrincipal(context),
        ),
      ),
      selected: selecionado,
      selectedColor: corAtiva,
      backgroundColor: isDark ? AppColors.cardEscuro : Colors.white,
      side: BorderSide(
        color: selecionado ? corAtiva : AppColors.getBorda(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _filtroStatus = valor);
        }
      },
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
                        Text(
                          'Meta: ${paciente.metaCalorica.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textoSecundarioEscuro : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Situação Financeira (Verde se pago, Vermelho se débito)
              _buildStatusFinanceiroBadge(paciente),

              const SizedBox(width: 4),
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

  Widget _buildStatusFinanceiroBadge(PacienteModel paciente) {
    final isPago = paciente.isPago;
    final isDark = AppColors.isDark(context);
    final corDestaque = isPago
        ? (isDark ? const Color(0xFF4ADE80) : AppColors.verde)
        : (isDark ? const Color(0xFFF87171) : AppColors.vermelho);
    final corFundo = isPago ? AppColors.getVerdeDestaque(context) : AppColors.getVermelhoDestaque(context);
    final corBorda = isPago ? AppColors.getVerdeDestaqueBorda(context) : AppColors.getVermelhoDestaqueBorda(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.getCard(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Situação Financeira — ${paciente.nome}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mensalidade atual: ${paciente.valorFormatado}',
                      style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.verde),
                      title: Text(
                        'Marcar como Pago (Em dia)',
                        style: TextStyle(color: AppColors.getTextoPrincipal(context)),
                      ),
                      subtitle: Text(
                        'O valor aparecerá verde no aplicativo',
                        style: TextStyle(color: AppColors.getTextoSecundario(context)),
                      ),
                      trailing: isPago ? const Icon(Icons.done, color: AppColors.verde) : null,
                      onTap: () {
                        setState(() {
                          paciente.statusFinanceiro = StatusFinanceiro.pago;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.error, color: AppColors.vermelho),
                      title: Text(
                        'Marcar como Em Débito',
                        style: TextStyle(color: AppColors.getTextoPrincipal(context)),
                      ),
                      subtitle: Text(
                        'O valor aparecerá vermelho no aplicativo',
                        style: TextStyle(color: AppColors.getTextoSecundario(context)),
                      ),
                      trailing: !isPago ? const Icon(Icons.done, color: AppColors.vermelho) : null,
                      onTap: () {
                        setState(() {
                          paciente.statusFinanceiro = StatusFinanceiro.debito;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: corBorda, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Valor destacado (em vermelho se débito, em verde se pago)
            Text(
              paciente.valorFormatado,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: corDestaque,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPago ? Icons.check_circle : Icons.error_rounded,
                  size: 11,
                  color: corDestaque,
                ),
                const SizedBox(width: 3),
                Text(
                  isPago ? 'Pago' : 'Em débito',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: corDestaque,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}