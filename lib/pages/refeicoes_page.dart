import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../models/registro_diario_model.dart';
import '../models/alimento_model.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';

class RefeicoesPage extends StatefulWidget {
  const RefeicoesPage({super.key});

  @override
  State<RefeicoesPage> createState() => _RefeicoesPageState();
}

class _RefeicoesPageState extends State<RefeicoesPage> {
  final DadosService _dadosService = DadosService();
  late PacienteModel _paciente;
  DateTime _dataSelecionada = DateTime.now();
  bool _carregandoData = false;

  @override
  void initState() {
    super.initState();
    _carregarPaciente();
  }

  void _carregarPaciente() {
    final pacientes = _dadosService.getPacientes();
    if (pacientes.isNotEmpty) {
      _paciente = pacientes.first;
    } else {
      _paciente = PacienteModel(
        id: 0,
        nome: 'Sem dados (Erro)',
        usuario: 'erro',
        statusFinanceiro: StatusFinanceiro.debito,
      );
    }
  }

  int get _totalConsumido => _paciente.registrosDiarios.isNotEmpty ? _paciente.registrosDiarios.first.totalCalorias : 0;

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
        _carregandoData = true;
      });

      await _dadosService.carregarRegistrosDiarios(novaData.toIso8601String().split('T').first);
      _carregarPaciente();
      
      if (mounted) {
        setState(() {
          _carregandoData = false;
        });
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
    final metaDiaria = _paciente.metaCalorica;
    final restante = metaDiaria - _totalConsumido;
    final progresso = (_totalConsumido / (metaDiaria > 0 ? metaDiaria : 1)).clamp(0.0, 1.0);
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
          bottom: const TabBar(
            indicatorColor: AppColors.verde,
            labelColor: AppColors.verde,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Plano Prescrito', icon: Icon(Icons.assignment)),
              Tab(text: 'Registro Diário', icon: Icon(Icons.restaurant_menu)),
            ],
          ),
        ),
        drawer: const AppDrawer(paginaAtual: 'refeicoes'),
        body: Column(
          children: [
            // Cabecalho de Resumo
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
                            'Acompanhe o que você comeu hoje no "Registro Diário".',
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
                          '$_totalConsumido kcal',
                          destaque: true,
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
                        '${(progresso * 100).toStringAsFixed(0)}% concluído',
                        style: TextStyle(fontSize: 11, color: AppColors.getTextoSecundario(context)),
                      ),
                      Text(
                        '$_totalConsumido / ${metaDiaria.toStringAsFixed(0)} kcal',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextoSecundario(context)),
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
    final registrosDeHoje = _paciente.registrosDiarios;
    final RegistroDiarioModel registroAtual = registrosDeHoje.isNotEmpty 
        ? registrosDeHoje.first 
        : RegistroDiarioModel(id: '', itens: []);

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
        if (registroAtual.itens.isEmpty)
          Center(
            child: Text(
              'Você ainda não registrou nada hoje.',
              style: TextStyle(color: AppColors.getTextoSecundario(context)),
            ),
          )
        else
          ..._agruparRegistros(registroAtual.itens).map((refeicao) => _buildMealCard(refeicao, isRegistro: true)),
        const SizedBox(height: 16),
      ],
    );
  }

  List<dynamic> _agruparRegistros(List<ItemRegistroDiarioModel> itens) {
    // Agrupa itens por refeição planejada
    final Map<String, List<ItemRegistroDiarioModel>> grupos = {};
    for (var item in itens) {
      final key = item.refeicaoNome ?? 'Outros';
      if (!grupos.containsKey(key)) grupos[key] = [];
      grupos[key]!.add(item);
    }

    // Cria objetos fake simulando RefeicaoModel para reutilizar o card
    return grupos.entries.map((e) {
      return _FakeRefeicao(
        tipo: e.key,
        itens: e.value,
        totalCalorias: e.value.fold(0, (s, i) => s + i.calorias),
      );
    }).toList();
  }

  void _showAddRegistroDialog() {
    String? refeicaoSelecionada;
    String alimentoNome = '';
    String quantidade = '100';
    int quantidadeGramas = 100;
    String observacoes = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar Consumo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Refeição (Prescrita)'),
                      value: refeicaoSelecionada,
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
                      onChanged: (val) => setStateDialog(() => refeicaoSelecionada = val),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return BancoAlimentos.lista.map((e) => e.nome);
                        }
                        return BancoAlimentos.lista
                            .where((e) => e.nome.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                            .map((e) => e.nome);
                      },
                      onSelected: (String val) => alimentoNome = val,
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            labelText: 'Alimento consumido',
                            hintText: 'Digite para buscar ou insira novo',
                          ),
                          onChanged: (val) => alimentoNome = val,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    (refeicaoSelecionada == 'outros' || refeicaoSelecionada == null)
                        ? TextField(
                            decoration: const InputDecoration(labelText: 'Quantidade (g)'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => quantidade = val,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                'Quantidade consumida:',
                                style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 28),
                                    color: Colors.red,
                                    onPressed: () {
                                      setStateDialog(() {
                                        if (quantidadeGramas > 10) quantidadeGramas -= 10;
                                        quantidade = quantidadeGramas.toString();
                                      });
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '${quantidadeGramas}g',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextoPrincipal(context),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 28),
                                    color: Colors.green,
                                    onPressed: () {
                                      setStateDialog(() {
                                        quantidadeGramas += 10;
                                        quantidade = quantidadeGramas.toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Observações (Opcional)'),
                      onChanged: (val) => observacoes = val,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (refeicaoSelecionada != null && alimentoNome.isNotEmpty && quantidade.isNotEmpty) {
                      _salvarConsumo(refeicaoSelecionada!, alimentoNome, double.tryParse(quantidade) ?? 0, observacoes);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _salvarConsumo(String refeicaoId, String alimentoNome, double gramas, String observacoes) async {
    // Obter ou criar o registro de hoje
    String dataHoje = _dataSelecionada.toIso8601String().split('T').first;
    
    Map<String, dynamic> data = {
      'usuario_id': _paciente.id,
      'data': dataHoje,
      'itens': [
        {
          'refeicao_planejada': int.tryParse(refeicaoId),
          'alimento_nome': alimentoNome,
          'quantidade_gramas': gramas,
          'observacoes': observacoes.isEmpty ? null : observacoes,
        }
      ]
    };

    // Para adicionar ao invés de sobrescrever o dia inteiro
    if (_paciente.registrosDiarios.isNotEmpty && _paciente.registrosDiarios.first.data == dataHoje) {
      final r = _paciente.registrosDiarios.first;
      List<Map<String, dynamic>> itensData = r.itens.map((i) => i.toJson()).toList();
      itensData.add({
        'refeicao_planejada': int.tryParse(refeicaoId),
        'alimento_nome': alimentoNome,
        'quantidade_gramas': gramas,
        'observacoes': observacoes.isEmpty ? null : observacoes,
      });
      data['itens'] = itensData;
    }

    await _dadosService.salvarRegistroDiario(_paciente.id, data);
    setState(() {}); // Atualizar a tela
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
                  Icon(icone, size: 14, color: AppColors.isDark(context) ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro),
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
                style: TextStyle(fontSize: 9, color: AppColors.getTextoSecundario(context), fontWeight: FontWeight.w600),
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
                if (!isRegistro && refeicao.horarioSugerido != null)
                  Text(
                    refeicao.horarioSugerido!,
                    style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 12),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.alimentoNome} — ${item.gramas.toStringAsFixed(0)}g',
                          style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
                        ),
                        if (isRegistro && (item as dynamic).observacoes != null && ((item as dynamic).observacoes as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Obs: ${(item as dynamic).observacoes}',
                              style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
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