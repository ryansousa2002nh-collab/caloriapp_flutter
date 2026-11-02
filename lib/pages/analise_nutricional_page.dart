import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/alimento_model.dart';
import '../models/dieta_model.dart';
import '../models/paciente_model.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_theme_toggle.dart';

class AnaliseNutricionalPage extends StatefulWidget {
  final PacienteModel paciente;
  final List<RefeicaoModel> refeicoes;
  final double metaCalorica;
  final int abaInicial; // 0 = Macros, 1 = Micros, 2 = Origem/Fontes

  const AnaliseNutricionalPage({
    super.key,
    required this.paciente,
    required this.refeicoes,
    required this.metaCalorica,
    this.abaInicial = 0,
  });

  @override
  State<AnaliseNutricionalPage> createState() => _AnaliseNutricionalPageState();
}

class _AnaliseNutricionalPageState extends State<AnaliseNutricionalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroMicros = 'Todos'; // pode ser 'Todos', 'Mineral' ou 'Vitamina'
  String _nutrienteAnaliseSelecionado = 'calorias';

  // Cores fixas pros macros ficarem fáceis de bater o olho nos gráficos
  static const Color _corProteina = Color(0xFF2563EB);
  static const Color _corCarboidrato = Color(0xFFD97706);
  static const Color _corGordura = Color(0xFFE11D48);
  static const Color _corFibra = Color(0xFF059669);

  // Opções que aparecem nos chips da 3ª aba pra filtrar de onde vem cada nutriente
  static const List<Map<String, String>> _opcoesNutrientesAnalise = [
    {'chave': 'calorias', 'nome': 'Calorias (VET)', 'unidade': 'kcal'},
    {'chave': 'proteinas', 'nome': 'Proteínas', 'unidade': 'g'},
    {'chave': 'carboidratos', 'nome': 'Carboidratos', 'unidade': 'g'},
    {'chave': 'gorduras', 'nome': 'Lipídios', 'unidade': 'g'},
    {'chave': 'fibras', 'nome': 'Fibras', 'unidade': 'g'},
    {'chave': 'ferro', 'nome': 'Ferro (Fe)', 'unidade': 'mg'},
    {'chave': 'calcio', 'nome': 'Cálcio (Ca)', 'unidade': 'mg'},
    {'chave': 'zinco', 'nome': 'Zinco (Zn)', 'unidade': 'mg'},
    {'chave': 'magnesio', 'nome': 'Magnésio (Mg)', 'unidade': 'mg'},
    {'chave': 'potassio', 'nome': 'Potássio (K)', 'unidade': 'mg'},
    {'chave': 'sodio', 'nome': 'Sódio (Na)', 'unidade': 'mg'},
    {'chave': 'vitamina_c', 'nome': 'Vitamina C', 'unidade': 'mg'},
    {'chave': 'vitamina_a', 'nome': 'Vitamina A', 'unidade': 'mcg'},
    {'chave': 'vitamina_d', 'nome': 'Vitamina D', 'unidade': 'mcg'},
    {'chave': 'vitamina_b12', 'nome': 'Vitamina B12', 'unidade': 'mcg'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.abaInicial.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Pega o peso atual cadastrado nas metas do paciente (ou usa 70kg se ainda não tiver)
  ComposicaoNutricionalDieta get _composicao => ComposicaoNutricionalDieta(
        refeicoes: widget.refeicoes,
        pesoPacienteKg: widget.paciente.metas.pesoAtual > 0
            ? widget.paciente.metas.pesoAtual
            : 70.0,
        metaCalorica: widget.metaCalorica,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final comp = _composicao;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análise Nutricional da Dieta',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.paciente.nome} • VET: ${comp.totalCalorias} kcal',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextoSecundario(context),
              ),
            ),
          ],
        ),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getCard(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorda(context)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? AppColors.verdeFundoEscuro : AppColors.verde,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.getTextoSecundario(context),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Macros & VET'),
                Tab(text: 'Micronutrientes'),
                Tab(text: 'Origem & Fontes'),
              ],
            ),
          ),
        ),
      ),
      body: widget.refeicoes.isEmpty
          ? _buildEstadoVazio(context)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAbaMacronutrientes(context, comp),
                _buildAbaMicronutrientes(context, comp),
                _buildAbaOrigemNutrientes(context, comp),
              ],
            ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 56,
                  color: AppColors.getTextoSecundario(context),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum alimento prescrito ainda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextoPrincipal(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Adicione refeições e alimentos ao plano alimentar para visualizar gráficos de macronutrientes, vitaminas, minerais e a contribuição de cada refeição.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextoSecundario(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Aba 1: Gráfico de rosca do VET + cards de Proteína, Carboidrato, Lipídio e Fibras
  Widget _buildAbaMacronutrientes(
    BuildContext context,
    ComposicaoNutricionalDieta comp,
  ) {
    final isDark = AppColors.isDark(context);
    final diferencaMeta = comp.totalCalorias - widget.metaCalorica;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card principal com o gráfico de rosca e a divisão do VET
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distribuição do VET',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            Text(
                              'Proporção calórica entre Proteínas, Carboidratos e Lipídios',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.getTextoSecundario(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getVerdeDestaque(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.getVerdeDestaqueBorda(context)),
                        ),
                        child: Text(
                          'Peso ref: ${comp.pesoPacienteKg.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gráfico de rosca na esquerda e legenda na direita
                  Row(
                    children: [
                      SizedBox(
                        width: 145,
                        height: 145,
                        child: CustomPaint(
                          painter: _MacroDonutChartPainter(
                            pctProteina: comp.percentualProteinasVET,
                            pctCarboidrato: comp.percentualCarboidratosVET,
                            pctGordura: comp.percentualGordurasVET,
                            corProteina: _corProteina,
                            corCarboidrato: _corCarboidrato,
                            corGordura: _corGordura,
                            corFundoTrilha: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${comp.totalCalorias}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.getTextoPrincipal(context),
                                  ),
                                ),
                                Text(
                                  'kcal no VET',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextoSecundario(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Meta: ${widget.metaCalorica.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: diferencaMeta.abs() <= 150
                                        ? (isDark ? const Color(0xFF4ADE80) : AppColors.verde)
                                        : _corCarboidrato,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _buildLegendaDonutItem(
                              context,
                              cor: _corCarboidrato,
                              nome: 'Carboidratos',
                              gramas: comp.totalCarboidratos,
                              percentual: comp.percentualCarboidratosVET,
                              kcal: comp.kcalCarboidratos,
                            ),
                            const SizedBox(height: 10),
                            _buildLegendaDonutItem(
                              context,
                              cor: _corProteina,
                              nome: 'Proteínas',
                              gramas: comp.totalProteinas,
                              percentual: comp.percentualProteinasVET,
                              kcal: comp.kcalProteinas,
                            ),
                            const SizedBox(height: 10),
                            _buildLegendaDonutItem(
                              context,
                              cor: _corGordura,
                              nome: 'Lipídios (Gorduras)',
                              gramas: comp.totalGorduras,
                              percentual: comp.percentualGordurasVET,
                              kcal: comp.kcalGorduras,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Barrinha horizontal mostrando as 3 cores juntas
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (comp.percentualCarboidratosVET * 10).round().clamp(1, 1000),
                            child: Container(color: _corCarboidrato),
                          ),
                          Expanded(
                            flex: (comp.percentualProteinasVET * 10).round().clamp(1, 1000),
                            child: Container(color: _corProteina),
                          ),
                          Expanded(
                            flex: (comp.percentualGordurasVET * 10).round().clamp(1, 1000),
                            child: Container(color: _corGordura),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cards separados pra cada macro com gramas totais, g/kg e calorias
          _buildCardMacroDetalhado(
            context,
            titulo: 'Proteínas (PTN)',
            cor: _corProteina,
            icone: Icons.fitness_center,
            gramas: comp.totalProteinas,
            percentualVET: comp.percentualProteinasVET,
            kcal: comp.kcalProteinas,
            gramasPorKg: comp.proteinasPorKg,
            faixaIdealTexto: 'Recomendação habitual: 15% a 35% do VET (1,2 a 2,2 g/kg)',
          ),
          const SizedBox(height: 10),
          _buildCardMacroDetalhado(
            context,
            titulo: 'Carboidratos (CHO)',
            cor: _corCarboidrato,
            icone: Icons.bolt,
            gramas: comp.totalCarboidratos,
            percentualVET: comp.percentualCarboidratosVET,
            kcal: comp.kcalCarboidratos,
            gramasPorKg: comp.carboidratosPorKg,
            faixaIdealTexto: 'Recomendação habitual: 40% a 60% do VET (3,0 a 6,0 g/kg)',
          ),
          const SizedBox(height: 10),
          _buildCardMacroDetalhado(
            context,
            titulo: 'Lipídios / Gorduras Totais (LIP)',
            cor: _corGordura,
            icone: Icons.water_drop_outlined,
            gramas: comp.totalGorduras,
            percentualVET: comp.percentualGordurasVET,
            kcal: comp.kcalGorduras,
            gramasPorKg: comp.gordurasPorKg,
            faixaIdealTexto: 'Recomendação habitual: 20% a 35% do VET (0,6 a 1,2 g/kg)',
          ),
          const SizedBox(height: 10),

          // Card de Fibras
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _corFibra.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.eco_outlined, color: _corFibra, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fibras Alimentares',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.getTextoPrincipal(context),
                                ),
                              ),
                              Text(
                                'Meta diária recomendada: 25g a 30g',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getTextoSecundario(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${comp.totalFibras.toStringAsFixed(1)} g',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _corFibra,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (comp.totalFibras / 25.0).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: isDark ? AppColors.bordaEscuro : AppColors.bordaCinza,
                      valueColor: const AlwaysStoppedAnimation<Color>(_corFibra),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((comp.totalFibras / 25.0) * 100).clamp(0, 200).toStringAsFixed(0)}% da meta mínima de 25g atingida',
                    style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaDonutItem(
    BuildContext context, {
    required Color cor,
    required String nome,
    required double gramas,
    required double percentual,
    required double kcal,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 28,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                  Text(
                    '${percentual.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cor,
                    ),
                  ),
                ],
              ),
              Text(
                '${gramas.toStringAsFixed(1)}g (${kcal.toStringAsFixed(0)} kcal)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextoSecundario(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardMacroDetalhado(
    BuildContext context, {
    required String titulo,
    required Color cor,
    required IconData icone,
    required double gramas,
    required double percentualVET,
    required double kcal,
    required double gramasPorKg,
    required String faixaIdealTexto,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: cor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      Text(
                        faixaIdealTexto,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentualVET.toStringAsFixed(1)}% VET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaMacroBox(
                    context,
                    label: 'Total em Gramas',
                    valor: '${gramas.toStringAsFixed(1)} g',
                    corDestaque: cor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricaMacroBox(
                    context,
                    label: 'Por kg de Peso',
                    valor: '${gramasPorKg.toStringAsFixed(2)} g/kg',
                    corDestaque: AppColors.getTextoPrincipal(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricaMacroBox(
                    context,
                    label: 'Energia Gerada',
                    valor: '${kcal.toStringAsFixed(0)} kcal',
                    corDestaque: AppColors.getTextoPrincipal(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaMacroBox(
    BuildContext context, {
    required String label,
    required String valor,
    required Color corDestaque,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.fundoPaginaEscuro : const Color(0xFFF4F6EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorda(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.getTextoSecundario(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: corDestaque,
            ),
          ),
        ],
      ),
    );
  }

  // Aba 2: Lista de Vitaminas e Minerais com barra de meta diária e principais alimentos fontes
  Widget _buildAbaMicronutrientes(
    BuildContext context,
    ComposicaoNutricionalDieta comp,
  ) {
    final isDark = AppColors.isDark(context);
    final catalogo = BancoAlimentos.catalogoMicronutrientes.where((m) {
      if (_filtroMicros == 'Todos') return true;
      return m.grupo == _filtroMicros;
    }).toList();

    final adequadosCount = BancoAlimentos.catalogoMicronutrientes.where((m) {
      final pct = comp.percentualMetaMicronutriente(m);
      return m.isLimiteMaximo ? pct <= 100.0 : pct >= 70.0;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo lá no topo dizendo quantos micros estão em dia
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getVerdeDestaque(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getVerdeDestaqueBorda(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Painel de Vitaminas & Minerais',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$adequadosCount de ${BancoAlimentos.catalogoMicronutrientes.length} micronutrientes monitorados estão em boa faixa nesta dieta.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botões pra filtrar entre Todos, Minerais ou Vitaminas
          Row(
            children: [
              _buildChipFiltroMicro(context, 'Todos', 'Todos (10)'),
              const SizedBox(width: 8),
              _buildChipFiltroMicro(context, 'Mineral', 'Minerais (6)'),
              const SizedBox(width: 8),
              _buildChipFiltroMicro(context, 'Vitamina', 'Vitaminas (4)'),
            ],
          ),

          const SizedBox(height: 12),

          // Cards de cada vitamina/mineral
          ...catalogo.map((info) => _buildCardMicronutriente(context, comp, info)),
        ],
      ),
    );
  }

  Widget _buildChipFiltroMicro(BuildContext context, String valor, String rotulo) {
    final selecionado = _filtroMicros == valor;
    final isDark = AppColors.isDark(context);

    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => setState(() => _filtroMicros = valor),
      selectedColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verde,
      backgroundColor: AppColors.getCard(context),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selecionado ? Colors.white : AppColors.getTextoPrincipal(context),
      ),
    );
  }

  Widget _buildCardMicronutriente(
    BuildContext context,
    ComposicaoNutricionalDieta comp,
    MicronutrienteInfo info,
  ) {
    final isDark = AppColors.isDark(context);
    final valorTotal = comp.totalNutriente(info.chave);
    final percentual = comp.percentualMetaMicronutriente(info);
    // Pega os 2 alimentos que mais dão esse micronutriente pra mostrar embaixo da barra
    final topFontes = comp
        .rankingAlimentosPorNutriente(info.chave)
        .where((f) => f.valorNutriente > 0)
        .take(2)
        .toList();

    // Escolhe a cor e o aviso conforme a porcentagem da meta (sódio é invertido porque tem teto)
    Color corStatus;
    String textoStatus;
    if (info.isLimiteMaximo) {
      if (percentual > 100) {
        corStatus = AppColors.vermelho;
        textoStatus = 'Acima do limite';
      } else if (percentual > 80) {
        corStatus = _corCarboidrato;
        textoStatus = 'Próximo ao limite';
      } else {
        corStatus = isDark ? const Color(0xFF4ADE80) : AppColors.verde;
        textoStatus = 'Controlado';
      }
    } else {
      if (percentual >= 80) {
        corStatus = isDark ? const Color(0xFF4ADE80) : AppColors.verde;
        textoStatus = 'Adequado';
      } else if (percentual >= 45) {
        corStatus = _corCarboidrato;
        textoStatus = 'Parcial';
      } else {
        corStatus = AppColors.vermelho;
        textoStatus = 'Atenção (Baixo)';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.simbolo,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: corStatus,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            info.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.getTextoPrincipal(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: corStatus.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              textoStatus,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: corStatus,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        info.funcaoClinica,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatarValorNutriente(valorTotal)} ${info.unidade}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    Text(
                      'Meta: ${_formatarValorNutriente(info.metaDiaria)} ${info.unidade}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.getTextoSecundario(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (percentual / 100.0).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: isDark ? AppColors.bordaEscuro : AppColors.bordaCinza,
                valueColor: AlwaysStoppedAnimation<Color>(corStatus),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topFontes.isEmpty
                        ? 'Sem fontes expressivas na dieta atual'
                        : 'Principais fontes: ${topFontes.map((f) => "${f.alimentoNome} (${_formatarValorNutriente(f.valorNutriente)}${info.unidade})").join(", ")}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getTextoSecundario(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentual.toStringAsFixed(0)}% da meta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: corStatus,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Aba 3: Mostra de onde estão vindo as calorias e cada nutriente (por refeição e por alimento)
  Widget _buildAbaOrigemNutrientes(
    BuildContext context,
    ComposicaoNutricionalDieta comp,
  ) {
    final isDark = AppColors.isDark(context);
    final infoSelecionada = _opcoesNutrientesAnalise.firstWhere(
      (o) => o['chave'] == _nutrienteAnaliseSelecionado,
      orElse: () => _opcoesNutrientesAnalise.first,
    );
    final nomeNutriente = infoSelecionada['nome']!;
    final unidadeNutriente = infoSelecionada['unidade']!;
    final totalNutriente = comp.totalNutriente(_nutrienteAnaliseSelecionado);
    final rankingAlimentos =
        comp.rankingAlimentosPorNutriente(_nutrienteAnaliseSelecionado);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista horizontal pra nutri escolher qual nutriente quer investigar
          Text(
            'Selecione o nutriente para ver de onde ele vem:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.getTextoPrincipal(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _opcoesNutrientesAnalise.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final op = _opcoesNutrientesAnalise[index];
                final ativo = op['chave'] == _nutrienteAnaliseSelecionado;
                return ChoiceChip(
                  label: Text(op['nome']!),
                  selected: ativo,
                  onSelected: (_) {
                    setState(() {
                      _nutrienteAnaliseSelecionado = op['chave']!;
                    });
                  },
                  selectedColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verde,
                  backgroundColor: AppColors.getCard(context),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ativo ? Colors.white : AppColors.getTextoPrincipal(context),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Parte 1: Quanto cada refeição entrega no total do dia
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contribuição por Refeição',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            Text(
                              'Quanto cada refeição entrega de $nomeNutriente',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.getTextoSecundario(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getVerdeDestaque(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: ${_formatarValorNutriente(totalNutriente)} $unidadeNutriente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...widget.refeicoes.map((ref) {
                    final valorRef = ref.totalNutriente(_nutrienteAnaliseSelecionado);
                    final pctRef =
                        totalNutriente > 0 ? (valorRef / totalNutriente) * 100.0 : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${ref.tipo}${ref.horarioSugerido != null ? " (${ref.horarioSugerido})" : ""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.getTextoPrincipal(context),
                                  ),
                                ),
                              ),
                              Text(
                                '${_formatarValorNutriente(valorRef)} $unidadeNutriente (${pctRef.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (pctRef / 100.0).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor:
                                  isDark ? AppColors.bordaEscuro : AppColors.bordaCinza,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? const Color(0xFF4ADE80) : AppColors.verde,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Macros da refeição: P: ${ref.totalProteinas.toStringAsFixed(1)}g • C: ${ref.totalCarboidratos.toStringAsFixed(1)}g • L: ${ref.totalGorduras.toStringAsFixed(1)}g • ${ref.totalCalorias} kcal',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.getTextoSecundario(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Parte 2: Ranking de cada alimento da dieta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ranking por Alimento ($nomeNutriente)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                  Text(
                    'Quanto cada alimento sozinho representa no total da dieta',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextoSecundario(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(rankingAlimentos.length, (index) {
                    final item = rankingAlimentos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.fundoPaginaEscuro : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.getBorda(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.getVerdeDestaque(context),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${index + 1}º',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? const Color(0xFF6EE7B7)
                                              : AppColors.verdeEscuro,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.alimentoNome,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppColors.getTextoPrincipal(context),
                                            ),
                                          ),
                                          Text(
                                            '${item.gramasTotais.toStringAsFixed(0)}g no dia • ${item.refeicoesOrigem}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.getTextoSecundario(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_formatarValorNutriente(item.valorNutriente)} $unidadeNutriente',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF6EE7B7)
                                          : AppColors.verdeEscuro,
                                    ),
                                  ),
                                  Text(
                                    '${item.percentualNoTotal.toStringAsFixed(1)}% do total',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextoSecundario(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (item.percentualNoTotal / 100.0).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor:
                                  isDark ? AppColors.bordaEscuro : AppColors.bordaCinza,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? const Color(0xFF6EE7B7) : AppColors.verde,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Composição na porção (${item.gramasTotais.toStringAsFixed(0)}${BancoAlimentos.obterUnidade(item.alimentoNome)}): ${item.calorias} kcal | P: ${item.proteinas.toStringAsFixed(1)}g | C: ${item.carboidratos.toStringAsFixed(1)}g | L: ${item.gorduras.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.getTextoSecundario(context),
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Formata casas decimais pra não ficar cheio de zeros quando o número é grande
  String _formatarValorNutriente(double valor) {
    if (valor == 0) return '0';
    if (valor >= 100) return valor.toStringAsFixed(0);
    if (valor >= 10) return valor.toStringAsFixed(1);
    return valor.toStringAsFixed(2);
  }
}

// Desenha o gráfico de rosca (donut) dos macronutrientes no Canvas
class _MacroDonutChartPainter extends CustomPainter {
  final double pctProteina;
  final double pctCarboidrato;
  final double pctGordura;
  final Color corProteina;
  final Color corCarboidrato;
  final Color corGordura;
  final Color corFundoTrilha;

  _MacroDonutChartPainter({
    required this.pctProteina,
    required this.pctCarboidrato,
    required this.pctGordura,
    required this.corProteina,
    required this.corCarboidrato,
    required this.corGordura,
    required this.corFundoTrilha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = corFundoTrilha
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final totalPct = pctProteina + pctCarboidrato + pctGordura;
    if (totalPct <= 0) return;

    double startAngle = -math.pi / 2;
    final segments = [
      MapEntry(pctCarboidrato, corCarboidrato),
      MapEntry(pctProteina, corProteina),
      MapEntry(pctGordura, corGordura),
    ];

    for (final seg in segments) {
      if (seg.key <= 0) continue;
      final sweepAngle = (seg.key / totalPct) * 2 * math.pi;
      final segPaint = Paint()
        ..color = seg.value
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, segPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutChartPainter oldDelegate) {
    return oldDelegate.pctProteina != pctProteina ||
        oldDelegate.pctCarboidrato != pctCarboidrato ||
        oldDelegate.pctGordura != pctGordura;
  }
}
