import 'package:flutter/material.dart';
import '../models/alimento_model.dart';
import '../models/dieta_model.dart';
import '../models/paciente_model.dart';
import '../models/registro_diario_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';

class _IngredienteForm {
  String alimentoNome = BancoAlimentos.lista.first.nome;
  int quantidadeGramas = 100;
  String observacoes = '';

  int get caloriasCalculadas {
    if (alimentoNome.trim().isEmpty || quantidadeGramas <= 0) return 0;
    final cal100 = BancoAlimentos.buscarCaloriasPor100g(alimentoNome);
    return ((cal100 * quantidadeGramas) / 100).round();
  }
}

class RefeicoesPage extends StatefulWidget {
  const RefeicoesPage({super.key});

  @override
  State<RefeicoesPage> createState() => _RefeicoesPageState();
}

class _RefeicoesPageState extends State<RefeicoesPage> {
  final DadosService _dadosService = DadosService();
  late PacienteModel _paciente;
  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarPaciente();
    if (_dadosService.getPacientes().length <= 1 && _paciente.planoAlimentar.isEmpty) {
      _dadosService.carregarDadosDoBackend().then((_) {
        if (mounted) {
          setState(() {
            _carregarPaciente();
          });
        }
      });
    }
  }

  void _carregarPaciente() {
    _paciente = _dadosService.getPacienteAtivo();
  }

  String get _dataSelecionadaStr => _dataSelecionada.toIso8601String().split('T').first;

  List<ItemRegistroDiarioModel> get _itensDoDia {
    final regs = _paciente.registrosDiarios.where(
      (r) => r.data == null || r.data == _dataSelecionadaStr,
    ).toList();
    if (regs.isNotEmpty) {
      return regs.expand((r) => r.itens).toList();
    }
    return [];
  }

  /// Total de calorias já consumidas no dia selecionado
  int get _totalConsumido => _itensDoDia.fold(0, (soma, item) => soma + item.calorias);

  /// Calorias restantes = Meta diária menos a quantidade calórica já consumida
  double get _caloriasRestantes => _paciente.metaCalorica - _totalConsumido;

  Future<void> _mudarData(BuildContext context) async {
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (novaData != null && novaData != _dataSelecionada) {
      setState(() {
        _dataSelecionada = novaData;
      });

      await _dadosService.carregarRegistrosDiarios(_dataSelecionadaStr);
      _carregarPaciente();

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _tentarEditarMeta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: AppColors.verdeEscuro, size: 36),
        title: const Text('Meta Diária Fixa'),
        content: const Text(
          'Apenas a sua nutricionista tem permissão para ajustar a meta diária de calorias.',
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
  }

  @override
  Widget build(BuildContext context) {
    final double metaDiaria = _paciente.metaCalorica;
    final int consumido = _totalConsumido;
    final double restante = _caloriasRestantes; // Meta - Consumidas
    final double progresso = (consumido / (metaDiaria > 0 ? metaDiaria : 1)).clamp(0.0, 1.0);
    final isDark = AppColors.isDark(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () => _mudarData(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dataSelecionada.day == DateTime.now().day && _dataSelecionada.month == DateTime.now().month
                      ? 'Hoje'
                      : '${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          actions: const [
            AppleThemeToggle(size: 28),
            SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.verde,
            labelColor: AppColors.verde,
            unselectedLabelColor: AppColors.getTextoSecundario(context),
            tabs: const [
              Tab(text: 'Plano Prescrito', icon: Icon(Icons.assignment)),
              Tab(text: 'Registro Diário', icon: Icon(Icons.restaurant_menu)),
            ],
          ),
        ),
        drawer: const AppDrawer(paginaAtual: 'refeicoes'),
        body: Column(
          children: [
            // Cabeçalho de Resumo Calórico
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getCard(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.getBorda(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin, color: AppColors.verde, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Registre suas refeições para descontar automaticamente das calorias restantes do dia.',
                            style: TextStyle(color: AppColors.getTextoPrincipal(context), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Consumidas',
                          '$consumido kcal',
                          destaque: true,
                          subtitulo: 'Já ingerido hoje',
                          cor: isDark ? const Color(0xFF4ADE80) : AppColors.verde,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _tentarEditarMeta,
                          child: _summaryCard(
                            'Meta diária',
                            '${metaDiaria.toStringAsFixed(0)} kcal',
                            icone: Icons.lock_outline,
                            subtitulo: 'Fixado pela nutri',
                            cor: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          'Restante',
                          '${restante.toStringAsFixed(0)} kcal',
                          subtitulo: restante >= 0 ? 'Meta - Consumidas' : 'Acima da meta',
                          cor: restante < 0
                              ? (isDark ? const Color(0xFFF87171) : AppColors.vermelho)
                              : AppColors.getTextoPrincipal(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                        '${(progresso * 100).toStringAsFixed(0)}% da meta consumida',
                        style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context)),
                      ),
                      Text(
                        'Faltam ${restante > 0 ? restante.toStringAsFixed(0) : 0} kcal (Consumido: $consumido / ${metaDiaria.toStringAsFixed(0)} kcal)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Abas
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlanoPrescritoTab(),
                  _buildRegistroDiarioTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanoPrescritoTab() {
    if (_paciente.planoAlimentar.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma refeição prescrita ainda.',
          style: TextStyle(color: AppColors.getTextoSecundario(context)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        ..._paciente.planoAlimentar.map((refeicao) => _buildMealCard(refeicao, isRegistro: false)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRegistroDiarioTab() {
    final itensHoje = _itensDoDia;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _showAddRegistroDialog,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Consumo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verde,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (itensHoje.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Você ainda não registrou nada neste dia.',
                style: TextStyle(color: AppColors.getTextoSecundario(context)),
              ),
            ),
          )
        else
          ..._agruparRegistros(itensHoje).map((refeicao) => _buildMealCard(refeicao, isRegistro: true)),
        const SizedBox(height: 16),
      ],
    );
  }

  List<dynamic> _agruparRegistros(List<ItemRegistroDiarioModel> itens) {
    final Map<String, List<ItemRegistroDiarioModel>> grupos = {};
    for (var item in itens) {
      final key = item.refeicaoNome ?? 'Outros';
      if (!grupos.containsKey(key)) grupos[key] = [];
      grupos[key]!.add(item);
    }

    return grupos.entries.map((e) {
      return _FakeRefeicao(
        tipo: e.key,
        itens: e.value,
        totalCalorias: e.value.fold(0, (s, i) => s + i.calorias),
      );
    }).toList();
  }

  Future<void> _registrarRefeicaoPrescritaCompleta(RefeicaoModel refeicao) async {
    final ingredientes = refeicao.itens.map((item) {
      final form = _IngredienteForm();
      form.alimentoNome = item.alimentoNome ?? BancoAlimentos.lista.first.nome;
      form.quantidadeGramas = item.gramas.round();
      return form;
    }).toList();

    if (ingredientes.isEmpty) return;
    await _salvarConsumoEmMassa(refeicao.id, ingredientes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${refeicao.tipo} (+${refeicao.totalCalorias} kcal) registrada! Restam ${_caloriasRestantes.toStringAsFixed(0)} kcal.',
        ),
        backgroundColor: AppColors.verde,
      ),
    );
  }

  Future<void> _removerItemConsumido(ItemRegistroDiarioModel itemParaRemover) async {
    final itensAtuais = List<ItemRegistroDiarioModel>.from(_itensDoDia);
    itensAtuais.remove(itemParaRemover);

    final regExistente = _paciente.registrosDiarios.where(
      (r) => r.data == null || r.data == _dataSelecionadaStr,
    );
    final regId = regExistente.isNotEmpty ? regExistente.first.id : 'reg_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'id': regId,
      'usuario_id': _paciente.id,
      'data': _dataSelecionadaStr,
      'itens': itensAtuais.map((i) => i.toJson()).toList(),
    };

    await _dadosService.salvarRegistroDiario(_paciente.id, data);
    if (mounted) {
      setState(() {});
    }
  }

  void _showAddRegistroDialog() {
    String refeicaoSelecionada =
        _paciente.planoAlimentar.isNotEmpty ? _paciente.planoAlimentar.first.id : 'outros';
    List<_IngredienteForm> ingredientes = [_IngredienteForm()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final totalAdicionado = ingredientes.fold<int>(0, (s, i) => s + i.caloriasCalculadas);
            final novoRestantePrevisto = _caloriasRestantes - totalAdicionado;

            return AlertDialog(
              title: const Text('Registrar Consumo'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Refeição'),
                        initialValue: refeicaoSelecionada,
                        items: [
                          ..._paciente.planoAlimentar.map((e) {
                            return DropdownMenuItem(
                              value: e.id,
                              child: Text(e.tipo),
                            );
                          }),
                          const DropdownMenuItem(
                            value: 'outros',
                            child: Text('Outros (Refeição Adicional)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => refeicaoSelecionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(ingredientes.length, (index) {
                        final ing = ingredientes[index];
                        return Card(
                          key: ObjectKey(ing),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Alimento ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (ingredientes.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setStateDialog(() => ingredientes.removeAt(index));
                                        },
                                      ),
                                  ],
                                ),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: BancoAlimentos.lista.any((a) => a.nome == ing.alimentoNome)
                                      ? ing.alimentoNome
                                      : BancoAlimentos.lista.first.nome,
                                  decoration: const InputDecoration(
                                    labelText: 'Selecione o Alimento',
                                  ),
                                  items: BancoAlimentos.lista.map((alimento) {
                                    return DropdownMenuItem(
                                      value: alimento.nome,
                                      child: Text(
                                        '${alimento.nome} (${alimento.caloriasPor100g} kcal/100g)',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setStateDialog(() => ing.alimentoNome = val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantidade consumida:',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${ing.caloriasCalculadas} kcal',
                                      style: const TextStyle(
                                        color: AppColors.verde,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                                      color: Colors.red,
                                      onPressed: () {
                                        setStateDialog(() {
                                          if (ing.quantidadeGramas > 10) ing.quantidadeGramas -= 10;
                                        });
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        '${ing.quantidadeGramas}g',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 28),
                                      color: Colors.green,
                                      onPressed: () {
                                        setStateDialog(() {
                                          ing.quantidadeGramas += 10;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Observações (Opcional)'),
                                  onChanged: (val) => ing.observacoes = val,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () {
                          setStateDialog(() => ingredientes.add(_IngredienteForm()));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar mais um alimento'),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a descontar: -$totalAdicionado kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Restará: ${novoRestantePrevisto.toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: novoRestantePrevisto < 0 ? AppColors.vermelho : AppColors.verde,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final validos =
                        ingredientes.where((i) => i.alimentoNome.trim().isNotEmpty && i.quantidadeGramas > 0).toList();
                    if (validos.isNotEmpty) {
                      Navigator.pop(context);
                      await _salvarConsumoEmMassa(refeicaoSelecionada, validos);
                    }
                  },
                  child: const Text('Salvar Consumo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarConsumoEmMassa(String refeicaoId, List<_IngredienteForm> ingredientes) async {
    final String dataHoje = _dataSelecionadaStr;
    final refPrescrita = _paciente.planoAlimentar.where((r) => r.id == refeicaoId);
    final nomeRefeicao = refPrescrita.isNotEmpty ? refPrescrita.first.tipo : 'Outros';

    final novosItens = ingredientes.map((ing) {
      return {
        'refeicao_nome': nomeRefeicao,
        'refeicao_planejada': int.tryParse(refeicaoId),
        'alimento_nome': ing.alimentoNome,
        'quantidade_gramas': ing.quantidadeGramas,
        'calorias_manual': ing.caloriasCalculadas,
        'observacoes': ing.observacoes.isEmpty ? null : ing.observacoes,
      };
    }).toList();

    final itensExistentes = _itensDoDia.map((i) => i.toJson()).toList();
    itensExistentes.addAll(novosItens);

    final regExistente = _paciente.registrosDiarios.where(
      (r) => r.data == null || r.data == dataHoje,
    );
    final regId = regExistente.isNotEmpty ? regExistente.first.id : 'reg_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> data = {
      'id': regId,
      'usuario_id': _paciente.id,
      'data': dataHoje,
      'itens': itensExistentes,
    };

    await _dadosService.salvarRegistroDiario(_paciente.id, data);
    _carregarPaciente();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _summaryCard(
    String label,
    String value, {
    bool destaque = false,
    IconData? icone,
    String? subtitulo,
    Color? cor,
  }) {
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
                  Icon(
                    icone,
                    size: 14,
                    color: AppColors.isDark(context) ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
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
                  color: AppColors.getTextoSecundario(context),
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

  Widget _buildMealCard(dynamic refeicao, {required bool isRegistro}) {
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
                        isRegistro ? Icons.check_circle : Icons.restaurant,
                        size: 16,
                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      refeicao.tipo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                  ],
                ),
                if (!isRegistro && refeicao is RefeicaoModel)
                  Row(
                    children: [
                      if (refeicao.horarioSugerido != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            refeicao.horarioSugerido!,
                            style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 12),
                          ),
                        ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.getVerdeDestaque(context),
                          foregroundColor: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _registrarRefeicaoPrescritaCompleta(refeicao),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Consumir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 18),
            ...refeicao.itens.map<Widget>(
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
                            '${item.alimentoNome} — ${item.gramas.toStringAsFixed(0)}g',
                            style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                          ),
                          if (isRegistro &&
                              (item as dynamic).observacoes != null &&
                              ((item as dynamic).observacoes as String).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Obs: ${(item as dynamic).observacoes}',
                                style: TextStyle(
                                  color: AppColors.getTextoSecundario(context),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.calorias} kcal',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isRegistro && item is ItemRegistroDiarioModel)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.vermelho),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Remover item consumido',
                            onPressed: () => _removerItemConsumido(item),
                          ),
                      ],
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
                  'Total',
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

class _FakeRefeicao {
  final String tipo;
  final List<ItemRegistroDiarioModel> itens;
  final int totalCalorias;

  _FakeRefeicao({required this.tipo, required this.itens, required this.totalCalorias});
}
