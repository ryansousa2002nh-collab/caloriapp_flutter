import 'package:flutter/material.dart';

import '../models/alimento_model.dart';
import '../models/dieta_model.dart';
import '../models/paciente_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_theme_toggle.dart';
import 'analise_nutricional_page.dart';
import 'historico_page.dart';

class CriarDietaPage extends StatefulWidget {
  final PacienteModel paciente;
  final bool
  isNutri; // Define se é a nutricionista mexendo ou se é modo visualização

  const CriarDietaPage({
    super.key,
    required this.paciente,
    this.isNutri = true,
  });

  @override
  State<CriarDietaPage> createState() => _CriarDietaPageState();
}

class _CriarDietaPageState extends State<CriarDietaPage> {
  final DadosService _dadosService = DadosService();
  late double _metaCalorica;
  late List<RefeicaoModel> _refeicoes;

  // Estado do formulário de refeição
  String _tipo = '';
  String _horario = '08:00';
  String _observacoes = '';
  List<ItemRefeicaoModel> _ingredientesForm = [
    ItemRefeicaoModel(
      alimentoNome: null,
      gramas: 0,
    ),
  ];
  int?
  _indiceEmEdicao; // null = nova refeição, número = editando refeição existente

  // Cores usadas pros macros ficarem no mesmo padrão da tela de análise
  static const Color _corProteina = Color(0xFF2563EB);
  static const Color _corCarboidrato = Color(0xFFD97706);
  static const Color _corGordura = Color(0xFFE11D48);
  static const Color _corFibra = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _metaCalorica = widget.paciente.metaCalorica;
    _refeicoes = List.from(widget.paciente.planoAlimentar);
  }

  int get _totalPlano =>
      _refeicoes.fold(0, (soma, r) => soma + r.totalCalorias);

  int get _totalConsumido => widget.paciente.totalCaloriasConsumidasHoje > 0
      ? widget.paciente.totalCaloriasConsumidasHoje
      : _totalPlano;

  int get _totalFormAtual =>
      _ingredientesForm.fold(0, (soma, i) => soma + i.calorias);

  double get _proteinasFormAtual =>
      _ingredientesForm.fold(0.0, (soma, i) => soma + i.proteinas);

  double get _carboidratosFormAtual =>
      _ingredientesForm.fold(0.0, (soma, i) => soma + i.carboidratos);

  double get _gordurasFormAtual =>
      _ingredientesForm.fold(0.0, (soma, i) => soma + i.gorduras);

  ComposicaoNutricionalDieta get _composicaoPlano => ComposicaoNutricionalDieta(
    refeicoes: _refeicoes,
    pesoPacienteKg: widget.paciente.metas.pesoAtual > 0
        ? widget.paciente.metas.pesoAtual
        : 70.0,
    metaCalorica: _metaCalorica,
  );

  void _abrirAnaliseNutricional({int abaInicial = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnaliseNutricionalPage(
          paciente: widget.paciente,
          refeicoes: _refeicoes,
          metaCalorica: _metaCalorica,
          abaInicial: abaInicial,
        ),
      ),
    );
  }

  void _adicionarIngrediente() {
    setState(() {
      _ingredientesForm.add(
        ItemRefeicaoModel(
          alimentoNome: null,
          gramas: 0,
        ),
      );
    });
  }

  void _removerIngrediente(int index) {
    setState(() {
      _ingredientesForm.removeAt(index);
      if (_ingredientesForm.isEmpty) {
        _ingredientesForm.add(
          ItemRefeicaoModel(
            alimentoNome: null,
            gramas: 0,
          ),
        );
      }
    });
  }

  bool _salvando = false;

  void _limparFormulario() {
    setState(() {
      _tipo = '';
      _horario = '08:00';
      _observacoes = '';
      _ingredientesForm = [
        ItemRefeicaoModel(
          alimentoNome: null,
          gramas: 0,
        ),
      ];
      _indiceEmEdicao = null;
    });
  }

  Future<void> _salvarRefeicao() async {
    if (!widget.isNutri) {
      _mostrarAviso(
        'Apenas a nutricionista pode cadastrar ou alterar refeições.',
      );
      return;
    }

    if (_tipo.isEmpty) {
      _mostrarAviso('Escreva o tipo de refeição.');
      return;
    }

    final itensValidos = _ingredientesForm
        .where(
          (i) =>
              i.alimentoNome != null &&
              i.alimentoNome!.isNotEmpty &&
              i.gramas > 0,
        )
        .toList();

    if (itensValidos.isEmpty) {
      _mostrarAviso(
        'Adicione pelo menos um alimento com quantidade maior que 0g.',
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    final refeicaoAtualizada = RefeicaoModel(
      id: _indiceEmEdicao != null
          ? _refeicoes[_indiceEmEdicao!].id
          : 'ref_${DateTime.now().millisecondsSinceEpoch}',
      tipo: _tipo,
      horarioSugerido: _horario,
      observacoes: _observacoes.isNotEmpty ? _observacoes : null,
      itens: itensValidos.map((i) => i.copyWith()).toList(),
    );

    await _dadosService.salvarRefeicao(widget.paciente.id, refeicaoAtualizada);

    if (!mounted) return;

    setState(() {
      _refeicoes = List.from(widget.paciente.planoAlimentar);
      _salvando = false;
      _mostrarAviso(
        _indiceEmEdicao != null
            ? 'Refeição "$_tipo" atualizada com sucesso!'
            : 'Refeição "$_tipo" adicionada ao plano!',
      );
    });

    _limparFormulario();
  }

  void _editarRefeicao(int index) {
    final refeicao = _refeicoes[index];
    setState(() {
      _tipo = refeicao.tipo;
      _horario = refeicao.horarioSugerido ?? '08:00';
      _observacoes = refeicao.observacoes ?? '';
      _ingredientesForm = refeicao.itens.map((i) => i.copyWith()).toList();
      _indiceEmEdicao = index;
    });
  }

  void _excluirRefeicao(int index) {
    if (!widget.isNutri) return;

    final refeicao = _refeicoes[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Refeição'),
        content: Text(
          'Deseja realmente remover a refeição "${refeicao.tipo}" do plano?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelho,
            ),
            onPressed: () {
              setState(() {
                _dadosService.excluirRefeicao(widget.paciente.id, refeicao.id);
                _refeicoes.removeAt(index);
              });
              Navigator.pop(context);
              _mostrarAviso('Refeição "${refeicao.tipo}" excluída.');
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Edição da Meta Diária (Apenas Nutricionista)
  Future<void> _editarMeta() async {
    if (!widget.isNutri) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.lock_outline,
            color: AppColors.verdeEscuro,
            size: 36,
          ),
          title: const Text('Meta Diária Fixa'),
          content: const Text(
            'Apenas sua nutricionista tem permissão para ajustar a meta diária de calorias.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: _metaCalorica.toStringAsFixed(0),
    );
    final novoValor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.verde),
            SizedBox(width: 8),
            Text('Ajustar Meta Diária'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Defina a quantidade de calorias necessárias que ${widget.paciente.nome} deve bater por dia nesta dieta:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextoSecundario(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta diária',
                suffixText: 'kcal',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text);
              Navigator.pop(context, valor);
            },
            child: const Text('Salvar Meta'),
          ),
        ],
      ),
    );

    if (novoValor != null && novoValor > 0) {
      setState(() {
        _metaCalorica = novoValor;
        _dadosService.atualizarMetaCalorica(widget.paciente.id, novoValor);
      });
      _mostrarAviso(
        'Meta diária atualizada para ${novoValor.toStringAsFixed(0)} kcal.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restante = _metaCalorica - _totalConsumido;
    final progresso =
        (_totalConsumido / (_metaCalorica > 0 ? _metaCalorica : 1)).clamp(
          0.0,
          1.0,
        );
    final isDark = AppColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.paciente.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.isNutri
                  ? 'Prescrição de Dieta (Nutricionista)'
                  : 'Plano Alimentar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextoSecundario(context),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isNutri)
            IconButton(
              icon: const Icon(Icons.pie_chart_outline),
              tooltip: 'Análise Nutricional da Dieta',
              onPressed: () => _abrirAnaliseNutricional(),
            ),
          const AppleThemeToggle(size: 28),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de instruções
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.getBorda(context)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppColors.verde,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isNutri
                          ? 'Monte o plano alimentar, adicione alimentos por refeição e acompanhe calorias, macros (% VET) e micronutrientes em tempo real.'
                          : 'Acompanhe seu plano alimentar diário prescrito pela sua nutricionista.',
                      style: TextStyle(
                        color: AppColors.getTextoPrincipal(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botões de navegação: Histórico & Metas + Análise Nutricional (Nutri)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart, size: 18),
                    label: Text(
                      widget.isNutri
                          ? 'Histórico e Metas'
                          : 'Meu Histórico e Metas',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getVerdeDestaque(context),
                      foregroundColor: isDark
                          ? const Color(0xFF6EE7B7)
                          : AppColors.verdeEscuro,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoricoPage(
                            paciente: widget.paciente,
                            isNutri: widget.isNutri,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.isNutri) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.pie_chart, size: 18),
                      label: const Text(
                        'Análise Nutricional',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _abrirAnaliseNutricional(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // CARDS DE RESUMO (Consumidas / Meta Diária / Restante)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    label: widget.isNutri
                        ? 'Total Prescrito (VET)'
                        : 'Consumidas',
                    valor:
                        '${widget.isNutri ? _totalPlano : _totalConsumido} kcal',
                    destaque: true,
                    cor: isDark ? const Color(0xFF4ADE80) : AppColors.verde,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _editarMeta,
                    child: _buildSummaryCard(
                      label: 'Meta diária',
                      valor: '${_metaCalorica.toStringAsFixed(0)} kcal',
                      icone: widget.isNutri
                          ? Icons.edit_outlined
                          : Icons.lock_outline,
                      subtitulo: widget.isNutri
                          ? 'Toque para editar'
                          : 'Definido pela nutri',
                      cor: isDark
                          ? const Color(0xFF4ADE80)
                          : AppColors.verde,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    label: 'Restante',
                    valor: '${restante.toStringAsFixed(0)} kcal',
                    cor: restante < 0
                        ? (isDark
                              ? const Color(0xFFF87171)
                              : AppColors.vermelho)
                        : AppColors.getTextoPrincipal(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Barra de Progresso Calórico
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.bordaEscuro
                    : AppColors.bordaCinza,
                valueColor: AlwaysStoppedAnimation<Color>(
                  restante < 0
                      ? AppColors.vermelho
                      : (isDark ? AppColors.rosaVibranteEscuro : AppColors.rosaVibrante),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progresso * 100).toStringAsFixed(0)}% da meta atingida',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextoSecundario(context),
                  ),
                ),
                Text(
                  'Total: $_totalConsumido / ${_metaCalorica.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextoSecundario(context),
                  ),
                ),
              ],
            ),

            // PAINEL COMPACTO EM TEMPO REAL DE COMPOSIÇÃO NUTRICIONAL (Visão da Nutricionista)
            if (widget.isNutri) ...[
              const SizedBox(height: 16),
              _buildPainelResumoNutricionalNutri(context),
            ],

            const SizedBox(height: 24),

            // FORMULÁRIO DE ADIÇÃO/EDIÇÃO DE REFEIÇÃO (Visível apenas para a nutricionista)
            if (widget.isNutri) ...[
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
                            child: Row(
                              children: [
                                Icon(
                                  _indiceEmEdicao != null
                                      ? Icons.edit
                                      : Icons.restaurant_menu,
                                  color: isDark
                                      ? const Color(0xFF6EE7B7)
                                      : AppColors.verdeEscuro,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _indiceEmEdicao != null
                                        ? 'Editar Refeição'
                                        : 'Adicionar Refeição',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextoPrincipal(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_indiceEmEdicao != null)
                            TextButton.icon(
                              onPressed: _limparFormulario,
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text(
                                'Cancelar edição',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tipo de Refeição e Horário
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              key: ValueKey(
                                'tipo_${_indiceEmEdicao ?? "novo"}',
                              ),
                              initialValue: _tipo,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de refeição',
                                hintText: 'Ex: Almoço',
                                isDense: true,
                              ),
                              onChanged: (valor) => _tipo = valor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: ValueKey(
                                'horario_${_indiceEmEdicao ?? "novo"}',
                              ),
                              initialValue: _horario,
                              decoration: const InputDecoration(
                                labelText: 'Horário',
                                isDense: true,
                                suffixIcon: Icon(Icons.access_time, size: 18),
                              ),
                              onChanged: (valor) => _horario = valor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Cabeçalho da seção de alimentos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Alimentos & Quantidades',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getVerdeDestaque(
                                context,
                              ),
                              foregroundColor: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : AppColors.verdeEscuro,
                              elevation: 0,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: AppColors.getVerdeDestaqueBorda(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: _adicionarIngrediente,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              'Adicionar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Digite a quantidade em gramas. O aplicativo calcula calorias e nutrientes em tempo real:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Lista de Linhas de Alimentos no Formulário
                      ...List.generate(
                        _ingredientesForm.length,
                        (index) => _buildLinhaIngrediente(index),
                      ),

                      const SizedBox(height: 14),

                      // Card do Total Calculado da Refeição Atual (Calorias + Macros)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getVerdeDestaque(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.getVerdeDestaqueBorda(context),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total desta refeição:',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF6EE7B7)
                                              : AppColors.verdeEscuro,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'P: ${_proteinasFormAtual.toStringAsFixed(1)}g • C: ${_carboidratosFormAtual.toStringAsFixed(1)}g • L: ${_gordurasFormAtual.toStringAsFixed(1)}g',
                                        style: TextStyle(
                                          color: AppColors.getTextoSecundario(
                                            context,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$_totalFormAtual kcal',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF6EE7B7)
                                        : AppColors.verdeEscuro,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        key: ValueKey('obs_${_indiceEmEdicao ?? "novo"}'),
                        initialValue: _observacoes,
                        decoration: const InputDecoration(
                          labelText:
                              'Observações (Substituições, modo de preparo...)',
                        ),
                        maxLines: 2,
                        onChanged: (valor) => _observacoes = valor,
                      ),

                      const SizedBox(height: 14),

                      // Botão de Salvar Refeição
                      ElevatedButton(
                        onPressed: _salvando ? null : _salvarRefeicao,
                        child: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _indiceEmEdicao != null
                                    ? 'Salvar Alterações da Refeição'
                                    : 'Adicionar Refeição ao Plano',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // LISTA DE REFEIÇÕES JÁ CRIADAS NO PLANO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Refeições do Plano (${_refeicoes.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextoPrincipal(context),
                  ),
                ),
                Text(
                  'Total: $_totalPlano kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : AppColors.verdeEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_refeicoes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getCard(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorda(context)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.no_meals_outlined,
                        size: 40,
                        color: AppColors.getTextoSecundario(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma refeição adicionada ainda.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicione alimentos no formulário acima para compor a dieta.',
                        style: TextStyle(
                          color: AppColors.getTextoSecundario(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ...List.generate(
              _refeicoes.length,
              (index) => _buildCardRefeicao(index),
            ),
          ],
        ),
      ),
    );
  }

  // Resumo rápido de macros e % do VET que atualiza na hora enquanto a nutri monta a dieta
  Widget _buildPainelResumoNutricionalNutri(BuildContext context) {
    final comp = _composicaoPlano;
    final isDark = AppColors.isDark(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 19,
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : AppColors.verdeEscuro,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Composição Nutricional (VET)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.getTextoPrincipal(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _abrirAnaliseNutricional(abaInicial: 0),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      'Ver completo →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : AppColors.verdeEscuro,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Barra segmentada proporcional do VET (CHO / PTN / LIP)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: _refeicoes.isEmpty
                    ? Container(
                        color: isDark
                            ? AppColors.bordaEscuro
                            : AppColors.bordaCinza,
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: (comp.percentualCarboidratosVET * 10)
                                .round()
                                .clamp(1, 1000),
                            child: Container(color: _corCarboidrato),
                          ),
                          Expanded(
                            flex: (comp.percentualProteinasVET * 10)
                                .round()
                                .clamp(1, 1000),
                            child: Container(color: _corProteina),
                          ),
                          Expanded(
                            flex: (comp.percentualGordurasVET * 10)
                                .round()
                                .clamp(1, 1000),
                            child: Container(color: _corGordura),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Indicadores rápidos de Carboidratos, Proteínas, Lipídios e Fibras
            Row(
              children: [
                Expanded(
                  child: _buildMiniMacroPill(
                    context,
                    sigla: 'CHO',
                    nome: 'Carboidratos',
                    gramas: comp.totalCarboidratos,
                    percentual: comp.percentualCarboidratosVET,
                    cor: _corCarboidrato,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniMacroPill(
                    context,
                    sigla: 'PTN',
                    nome: 'Proteínas',
                    gramas: comp.totalProteinas,
                    percentual: comp.percentualProteinasVET,
                    cor: _corProteina,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniMacroPill(
                    context,
                    sigla: 'LIP',
                    nome: 'Lipídios',
                    gramas: comp.totalGorduras,
                    percentual: comp.percentualGordurasVET,
                    cor: _corGordura,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniMacroPill(
                    context,
                    sigla: 'FIB',
                    nome: 'Fibras',
                    gramas: comp.totalFibras,
                    percentual: null,
                    subtextoCustom: 'Meta: 25g',
                    cor: _corFibra,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Botões de atalho direto para Micronutrientes e Raio-X por Refeição/Alimento
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirAnaliseNutricional(abaInicial: 1),
                    icon: const Icon(Icons.science_outlined, size: 15),
                    label: const Text(
                      'Ver Micronutrientes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: AppColors.getBorda(context)),
                      foregroundColor: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirAnaliseNutricional(abaInicial: 2),
                    icon: const Icon(Icons.layers_outlined, size: 15),
                    label: const Text(
                      'Origem por Alimento',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: AppColors.getBorda(context)),
                      foregroundColor: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMacroPill(
    BuildContext context, {
    required String sigla,
    required String nome,
    required double gramas,
    required double? percentual,
    String? subtextoCustom,
    required Color cor,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.fundoPaginaEscuro : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Text(
            nome,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextoSecundario(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${gramas.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: cor,
            ),
          ),
          Text(
            percentual != null
                ? '${percentual.toStringAsFixed(0)}% VET'
                : (subtextoCustom ?? ''),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextoSecundario(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String valor,
    bool destaque = false,
    IconData? icone,
    String? subtitulo,
    Color? cor,
  }) {
    final isDark = AppColors.isDark(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.getTextoSecundario(context),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icone != null)
                  Icon(
                    icone,
                    size: 14,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : AppColors.verdeEscuro,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color:
                    cor ??
                    (destaque
                        ? AppColors.verde
                        : AppColors.getTextoPrincipal(context)),
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark
                      ? const Color(0xFF6EE7B7)
                      : AppColors.verdeEscuro,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Linha de cada ingrediente com recálculo automático em tempo real
  Widget _buildLinhaIngrediente(int index) {
    final item = _ingredientesForm[index];
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.fundoPaginaEscuro : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorda(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Seleção de Alimento
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  key: ObjectKey(item),
                  initialValue: item.alimentoNome,
                  hint: const Text('Selecione o alimento', style: TextStyle(fontSize: 12)),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Alimento',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: BancoAlimentos.lista.map((alimento) {
                    return DropdownMenuItem(
                      value: alimento.nome,
                      child: Text(
                        '${alimento.nome} (${alimento.caloriasPor100g} kcal/100g)',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      item.alimentoNome = valor;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),

              // Quantidade em Gramas ou ML com recálculo em tempo real
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('${item.hashCode}_${item.alimentoNome}_quantidade'),
                  initialValue: item.gramas == 0
                      ? ''
                      : item.gramas.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: item.isLiquido ? 'ml' : 'Gramas',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    suffixText: item.unidadeMedida,
                  ),
                  onChanged: (valor) {
                    setState(() {
                      item.gramas = double.tryParse(valor) ?? 0;
                    });
                  },
                ),
              ),

              const SizedBox(width: 4),

              // Botão remover linha compacto
              InkWell(
                onTap: () => _removerIngrediente(index),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppColors.vermelho,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Sub-linha indicando calorias e macros resultantes daquele alimento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'P: ${item.proteinas.toStringAsFixed(1)}g • C: ${item.carboidratos.toStringAsFixed(1)}g • L: ${item.gorduras.toStringAsFixed(1)}g${item.alimentoObj?.porcaoSugerida != null ? " (${item.alimentoObj!.porcaoSugerida})" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getTextoSecundario(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.getVerdeDestaque(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.calorias} kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : AppColors.verdeEscuro,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card de Refeição Salva
  Widget _buildCardRefeicao(int index) {
    final refeicao = _refeicoes[index];
    final isDark = AppColors.isDark(context);
    final pctVetRefeicao = _totalPlano > 0
        ? (refeicao.totalCalorias / _totalPlano) * 100.0
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.getVerdeDestaque(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF6EE7B7)
                              : AppColors.verdeEscuro,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    refeicao.tipo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.getTextoPrincipal(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.isNutri && _totalPlano > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.getVerdeDestaque(
                                        context,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${pctVetRefeicao.toStringAsFixed(0)}% do VET',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? const Color(0xFF6EE7B7)
                                            : AppColors.verdeEscuro,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (refeicao.horarioSugerido != null)
                              Text(
                                'Horário sugerido: ${refeicao.horarioSugerido}',
                                style: TextStyle(
                                  color: AppColors.getTextoSecundario(context),
                                  fontSize: 11,
                                ),
                              ),
                            if (refeicao.observacoes != null &&
                                refeicao.observacoes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Obs: ${refeicao.observacoes}',
                                  style: TextStyle(
                                    color: AppColors.getTextoSecundario(
                                      context,
                                    ),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isNutri)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _editarRefeicao(index),
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.blue,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFEFF6FF),
                          visualDensity: VisualDensity.compact,
                        ),
                        tooltip: 'Editar esta refeição',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _excluirRefeicao(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.vermelho,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.vermelhoFundoEscuro
                              : AppColors.vermelhoClaro,
                          visualDensity: VisualDensity.compact,
                        ),
                        tooltip: 'Excluir esta refeição',
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 18),

            // Lista de alimentos desta refeição
            ...refeicao.itens.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${item.alimentoNome ?? "Alimento"} (${item.gramas.toStringAsFixed(0)}${item.unidadeMedida})',
                            style: TextStyle(
                              color: AppColors.getTextoPrincipal(context),
                              fontSize: 13,
                            ),
                          ),
                          if (widget.isNutri)
                            Padding(
                              padding: const EdgeInsets.only(left: 10, top: 1),
                              child: Text(
                                'P: ${item.proteinas.toStringAsFixed(1)}g • C: ${item.carboidratos.toStringAsFixed(1)}g • L: ${item.gorduras.toStringAsFixed(1)}g',
                                style: TextStyle(
                                  color: AppColors.getTextoSecundario(context),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.calorias} kcal',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : AppColors.verdeEscuro,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total da refeição',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      if (widget.isNutri)
                        Text(
                          'PTN: ${refeicao.totalProteinas.toStringAsFixed(1)}g | CHO: ${refeicao.totalCarboidratos.toStringAsFixed(1)}g | LIP: ${refeicao.totalGorduras.toStringAsFixed(1)}g | FIB: ${refeicao.totalFibras.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextoSecundario(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${refeicao.totalCalorias} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.getTextoPrincipal(context),
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
