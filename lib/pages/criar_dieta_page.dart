import 'package:flutter/material.dart';
import '../models/alimento_model.dart';
import '../models/dieta_model.dart';
import '../models/paciente_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_theme_toggle.dart';

class CriarDietaPage extends StatefulWidget {
  final PacienteModel paciente;
  final bool isNutri; // Define se é a nutricionista mexendo ou se é modo visualização

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
  String? _tipoSelecionado;
  String _horario = '08:00';
  List<ItemRefeicaoModel> _ingredientesForm = [
    ItemRefeicaoModel(alimentoNome: BancoAlimentos.lista.first.nome, gramas: 100),
  ];
  int? _indiceEmEdicao; // null = nova refeição, número = editando refeição existente

  final List<String> _tiposRefeicao = [
    'Café da manhã',
    'Lanche da manhã',
    'Almoço',
    'Lanche da tarde',
    'Pré-treino',
    'Pós-treino',
    'Jantar',
    'Ceia',
  ];

  @override
  void initState() {
    super.initState();
    _metaCalorica = widget.paciente.metaCalorica;
    _refeicoes = List.from(widget.paciente.planoAlimentar);
    if (_tipoSelecionado == null && _tiposRefeicao.isNotEmpty) {
      _tipoSelecionado = _tiposRefeicao.first;
    }
  }

  int get _totalConsumido =>
      _refeicoes.fold(0, (soma, r) => soma + r.totalCalorias);

  int get _totalFormAtual =>
      _ingredientesForm.fold(0, (soma, i) => soma + i.calorias);

  void _adicionarIngrediente() {
    setState(() {
      _ingredientesForm.add(
        ItemRefeicaoModel(alimentoNome: BancoAlimentos.lista.first.nome, gramas: 100),
      );
    });
  }

  void _removerIngrediente(int index) {
    setState(() {
      _ingredientesForm.removeAt(index);
      if (_ingredientesForm.isEmpty) {
        _ingredientesForm.add(ItemRefeicaoModel(alimentoNome: BancoAlimentos.lista.first.nome, gramas: 100));
      }
    });
  }

  void _limparFormulario() {
    setState(() {
      _tipoSelecionado = _tiposRefeicao.first;
      _horario = '08:00';
      _ingredientesForm = [
        ItemRefeicaoModel(alimentoNome: BancoAlimentos.lista.first.nome, gramas: 100),
      ];
      _indiceEmEdicao = null;
    });
  }

  void _salvarRefeicao() {
    if (!widget.isNutri) {
      _mostrarAviso('Apenas a nutricionista pode cadastrar ou alterar refeições.');
      return;
    }

    if (_tipoSelecionado == null || _tipoSelecionado!.isEmpty) {
      _mostrarAviso('Selecione o tipo de refeição.');
      return;
    }

    final itensValidos = _ingredientesForm
        .where((i) => i.alimentoNome != null && i.alimentoNome!.isNotEmpty && i.gramas > 0)
        .toList();

    if (itensValidos.isEmpty) {
      _mostrarAviso('Adicione pelo menos um alimento com quantidade maior que 0g.');
      return;
    }

    setState(() {
      final refeicaoAtualizada = RefeicaoModel(
        id: _indiceEmEdicao != null
            ? _refeicoes[_indiceEmEdicao!].id
            : 'ref_${DateTime.now().millisecondsSinceEpoch}',
        tipo: _tipoSelecionado!,
        horarioSugerido: _horario,
        itens: itensValidos.map((i) => i.copyWith()).toList(),
      );

      if (_indiceEmEdicao != null) {
        _refeicoes[_indiceEmEdicao!] = refeicaoAtualizada;
        _dadosService.salvarRefeicao(widget.paciente.id, refeicaoAtualizada);
        _mostrarAviso('Refeição "$_tipoSelecionado" atualizada com sucesso!');
      } else {
        _refeicoes.add(refeicaoAtualizada);
        _dadosService.salvarRefeicao(widget.paciente.id, refeicaoAtualizada);
        _mostrarAviso('Refeição "$_tipoSelecionado" adicionada ao plano!');
      }
    });

    _limparFormulario();
  }

  void _editarRefeicao(int index) {
    final refeicao = _refeicoes[index];
    setState(() {
      _tipoSelecionado = refeicao.tipo;
      _horario = refeicao.horarioSugerido ?? '08:00';
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
        content: Text('Deseja realmente remover a refeição "${refeicao.tipo}" do plano?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vermelho),
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
          icon: const Icon(Icons.lock_outline, color: AppColors.verdeEscuro, size: 36),
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

    final controller = TextEditingController(text: _metaCalorica.toStringAsFixed(0));
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
              style: TextStyle(fontSize: 13, color: AppColors.getTextoSecundario(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta diária',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
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
      _mostrarAviso('Meta diária atualizada para ${novoValor.toStringAsFixed(0)} kcal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final restante = _metaCalorica - _totalConsumido;
    final progresso = (_totalConsumido / (_metaCalorica > 0 ? _metaCalorica : 1)).clamp(0.0, 1.0);
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
              widget.isNutri ? 'Prescrição de Dieta (Nutricionista)' : 'Plano Alimentar',
              style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context)),
            ),
          ],
        ),
        actions: [
          const AppleThemeToggle(size: 28),
          const SizedBox(width: 4),
          // Tag de status financeiro
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.paciente.isPago ? AppColors.getVerdeDestaque(context) : AppColors.getVermelhoDestaque(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.paciente.isPago ? AppColors.getVerdeDestaqueBorda(context) : AppColors.getVermelhoDestaqueBorda(context),
                  ),
                ),
                child: Text(
                  '${widget.paciente.valorFormatado} • ${widget.paciente.statusTexto}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.paciente.isPago
                        ? (isDark ? const Color(0xFF4ADE80) : AppColors.verde)
                        : (isDark ? const Color(0xFFF87171) : AppColors.vermelho),
                  ),
                ),
              ),
            ),
          ),
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
                  const Icon(Icons.tips_and_updates_outlined, color: AppColors.verde, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isNutri
                          ? 'Monte o plano alimentar, adicione alimentos por refeição e o app calculará as calorias automaticamente.'
                          : 'Acompanhe seu plano alimentar diário prescrito pela sua nutricionista.',
                      style: TextStyle(color: AppColors.getTextoPrincipal(context), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARDS DE RESUMO (Consumidas / Meta Diária / Restante)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    label: 'Consumidas',
                    valor: '$_totalConsumido kcal',
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
                      icone: widget.isNutri ? Icons.edit_outlined : Icons.lock_outline,
                      subtitulo: widget.isNutri ? 'Toque para editar' : 'Definido pela nutri',
                      cor: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    label: 'Restante',
                    valor: '${restante.toStringAsFixed(0)} kcal',
                    cor: restante < 0
                        ? (isDark ? const Color(0xFFF87171) : AppColors.vermelho)
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
                backgroundColor: isDark ? AppColors.bordaEscuro : AppColors.bordaCinza,
                valueColor: AlwaysStoppedAnimation<Color>(
                  restante < 0 ? AppColors.vermelho : AppColors.verde,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progresso * 100).toStringAsFixed(0)}% da meta atingida',
                  style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context)),
                ),
                Text(
                  'Total: $_totalConsumido / ${_metaCalorica.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextoSecundario(context)),
                ),
              ],
            ),

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
                          Row(
                            children: [
                              Icon(
                                _indiceEmEdicao != null ? Icons.edit : Icons.restaurant_menu,
                                color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _indiceEmEdicao != null ? 'Editar Refeição' : 'Adicionar Refeição',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.getTextoPrincipal(context),
                                ),
                              ),
                            ],
                          ),
                          if (_indiceEmEdicao != null)
                            TextButton.icon(
                              onPressed: _limparFormulario,
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Cancelar edição', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tipo de Refeição e Horário
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _tipoSelecionado,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de refeição',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _tiposRefeicao
                                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                                  .toList(),
                              onChanged: (valor) => setState(() => _tipoSelecionado = valor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: _horario,
                              decoration: const InputDecoration(
                                labelText: 'Horário',
                                border: OutlineInputBorder(),
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
                          Text(
                            'Alimentos & Quantidades',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.getTextoPrincipal(context),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getVerdeDestaque(context),
                              foregroundColor: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                              elevation: 0,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(color: AppColors.getVerdeDestaqueBorda(context)),
                              ),
                            ),
                            onPressed: _adicionarIngrediente,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Adicionar alimento', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Digite a quantidade em gramas. O aplicativo calcula as calorias em tempo real:',
                        style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context)),
                      ),
                      const SizedBox(height: 10),

                      // Lista de Linhas de Alimentos no Formulário
                      ...List.generate(_ingredientesForm.length, (index) => _buildLinhaIngrediente(index)),

                      const SizedBox(height: 14),

                      // Card do Total Calculado da Refeição Atual
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.getVerdeDestaque(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.getVerdeDestaqueBorda(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total desta refeição:',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Cálculo automático em tempo real',
                                  style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 10),
                                ),
                              ],
                            ),
                            Text(
                              '$_totalFormAtual kcal',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Botão de Salvar Refeição
                      ElevatedButton(
                        onPressed: _salvarRefeicao,
                        child: Text(
                          _indiceEmEdicao != null
                              ? 'Salvar Alterações da Refeição'
                              : 'Adicionar Refeição ao Plano',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                  'Total: $_totalConsumido kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
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
                      Icon(Icons.no_meals_outlined, size: 40, color: AppColors.getTextoSecundario(context)),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma refeição adicionada ainda.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextoPrincipal(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicione alimentos no formulário acima para compor a dieta.',
                        style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            ...List.generate(_refeicoes.length, (index) => _buildCardRefeicao(index)),
          ],
        ),
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
                    style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icone != null)
                  Icon(icone, size: 14, color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cor ?? (destaque ? AppColors.verde : AppColors.getTextoPrincipal(context)),
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
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
                  initialValue: item.alimentoNome,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Alimento',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
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
              const SizedBox(width: 8),

              // Quantidade em Gramas com recálculo em tempo real
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.gramas == 0 ? '' : item.gramas.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gramas (g)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                  onChanged: (valor) {
                    setState(() {
                      item.gramas = double.tryParse(valor) ?? 0;
                    });
                  },
                ),
              ),

              const SizedBox(width: 6),

              // Botão remover linha
              IconButton(
                onPressed: () => _removerIngrediente(index),
                icon: const Icon(Icons.delete_outline, color: AppColors.vermelho, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Remover alimento',
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Sub-linha indicando calorias resultantes daquele alimento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.alimentoObj?.porcaoSugerida != null
                    ? 'Sugestão: ${item.alimentoObj!.porcaoSugerida}'
                    : '',
                style: TextStyle(fontSize: 10, color: AppColors.getTextoSecundario(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.getVerdeDestaque(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Calculado: ${item.calorias} kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
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
                Row(
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
                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refeicao.tipo,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.getTextoPrincipal(context),
                          ),
                        ),
                        if (refeicao.horarioSugerido != null)
                          Text(
                            'Horário sugerido: ${refeicao.horarioSugerido}',
                            style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
                if (widget.isNutri)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _editarRefeicao(index),
                        icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                          visualDensity: VisualDensity.compact,
                        ),
                        tooltip: 'Editar esta refeição',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _excluirRefeicao(index),
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.vermelho),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppColors.vermelhoFundoEscuro : AppColors.vermelhoClaro,
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
                      child: Text(
                        '• ${item.alimentoNome ?? "Alimento"} (${item.gramas.toStringAsFixed(0)}g)',
                        style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                      ),
                    ),
                    Text(
                      '${item.calorias} kcal',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
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
                Text(
                  'Total da refeição',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.getTextoPrincipal(context),
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