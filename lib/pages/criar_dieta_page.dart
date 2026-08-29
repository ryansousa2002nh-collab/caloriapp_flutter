import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pacientes_page.dart'; // pra usar a classe Paciente

// Banco de alimentos mock (igual ao do seu HTML)
const Map<String, int> _bancoAlimentos = {
  'Arroz branco': 130,
  'Feijão carioca': 76,
  'Frango grelhado': 165,
  'Pão francês': 270,
  'Ovo': 143,
  'Banana': 89,
  'Batata': 77,
  'Macarrão': 158,
  'Carne bovina': 250,
  'Peito de frango': 165,
  'Aveia': 389,
  'Leite': 61,
};

// Representa um alimento dentro de uma refeição sendo montada
class IngredienteForm {
  String? alimento;
  double gramas;
  IngredienteForm({this.alimento, this.gramas = 0});

  int get calorias {
    if (alimento == null) return 0;
    final calPor100g = _bancoAlimentos[alimento] ?? 0;
    return ((calPor100g * gramas) / 100).round();
  }
}

// Representa uma refeição já salva no plano
class RefeicaoCriada {
  String tipo;
  List<IngredienteForm> ingredientes;
  RefeicaoCriada({required this.tipo, required this.ingredientes});

  int get totalCalorias => ingredientes.fold(0, (soma, item) => soma + item.calorias);
}

class CriarDietaPage extends StatefulWidget {
  final Paciente paciente;
  const CriarDietaPage({super.key, required this.paciente});

  @override
  State<CriarDietaPage> createState() => _CriarDietaPageState();
}

class _CriarDietaPageState extends State<CriarDietaPage> {
  double _metaCalorica = 2000; // depois vem da API (meta_calorica do paciente)
  final List<RefeicaoCriada> _refeicoes = []; // refeições já criadas nesse plano

  String? _tipoSelecionado;
  List<IngredienteForm> _ingredientesForm = [IngredienteForm()];
  int? _indiceEmEdicao; // null = criando nova refeição; caso contrário, editando a de índice X

  final List<String> _tiposRefeicao = [
    'Café da manhã', 'Lanche da manhã', 'Almoço', 'Lanche da tarde', 'Jantar', 'Ceia'
  ];

  int get _totalConsumido => _refeicoes.fold(0, (soma, r) => soma + r.totalCalorias);
  int get _totalFormAtual => _ingredientesForm.fold(0, (soma, i) => soma + i.calorias);

  void _adicionarIngrediente() {
    setState(() => _ingredientesForm.add(IngredienteForm()));
  }

  void _removerIngrediente(int index) {
    setState(() {
      _ingredientesForm.removeAt(index);
      if (_ingredientesForm.isEmpty) _ingredientesForm.add(IngredienteForm());
    });
  }

  void _limparFormulario() {
    setState(() {
      _tipoSelecionado = null;
      _ingredientesForm = [IngredienteForm()];
      _indiceEmEdicao = null;
    });
  }

  void _salvarRefeicao() {
    if (_tipoSelecionado == null) {
      _mostrarAviso('Selecione o tipo de refeição.');
      return;
    }
    final ingredientesValidos = _ingredientesForm.where((i) => i.alimento != null && i.gramas > 0).toList();
    if (ingredientesValidos.isEmpty) {
      _mostrarAviso('Adicione pelo menos um alimento.');
      return;
    }

    setState(() {
      final novaRefeicao = RefeicaoCriada(tipo: _tipoSelecionado!, ingredientes: ingredientesValidos);
      if (_indiceEmEdicao != null) {
        _refeicoes[_indiceEmEdicao!] = novaRefeicao; // atualiza a existente
      } else {
        _refeicoes.add(novaRefeicao); // cria nova
      }
    });

    _limparFormulario();
  }

  void _editarRefeicao(int index) {
    final refeicao = _refeicoes[index];
    setState(() {
      _tipoSelecionado = refeicao.tipo;
      _ingredientesForm = refeicao.ingredientes.map((i) => IngredienteForm(alimento: i.alimento, gramas: i.gramas)).toList();
      _indiceEmEdicao = index;
    });
  }

  void _excluirRefeicao(int index) {
    setState(() => _refeicoes.removeAt(index));
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editarMeta() async {
    final controller = TextEditingController(text: _metaCalorica.toStringAsFixed(0));
    final novoValor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meta diária'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'kcal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (novoValor != null && novoValor > 0) {
      setState(() => _metaCalorica = novoValor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restante = _metaCalorica - _totalConsumido;

    return Scaffold(
      appBar: AppBar(title: Text(widget.paciente.nome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monte o plano alimentar diário do paciente.',
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 14)),
            const SizedBox(height: 20),

            // RESUMO
            Row(
              children: [
                Expanded(child: _summaryCard('Consumidas', '$_totalConsumido kcal', destaque: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _editarMeta,
                    child: _summaryCard('Meta diária', '${_metaCalorica.toStringAsFixed(0)} kcal', icone: Icons.edit),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard('Restante', '${restante.toStringAsFixed(0)} kcal')),
              ],
            ),
            const SizedBox(height: 24),

            // FORMULÁRIO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_indiceEmEdicao != null ? 'Editar refeição' : 'Adicionar refeição',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (_indiceEmEdicao != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.verdeClaro, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('✏️ Editando refeição salva', style: TextStyle(color: AppColors.verdeEscuro, fontSize: 12))),
                            TextButton(onPressed: _limparFormulario, child: const Text('Cancelar')),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _tipoSelecionado,
                      decoration: const InputDecoration(labelText: 'Tipo de refeição', border: OutlineInputBorder()),
                      items: _tiposRefeicao.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                      onChanged: (valor) => setState(() => _tipoSelecionado = valor),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alimentos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        TextButton.icon(
                          onPressed: _adicionarIngrediente,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Adicionar alimento'),
                        ),
                      ],
                    ),

                    ...List.generate(_ingredientesForm.length, (index) => _buildLinhaIngrediente(index)),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.verdeClaro, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total da refeição', style: TextStyle(color: AppColors.verdeEscuro, fontSize: 13)),
                          Text('$_totalFormAtual kcal', style: const TextStyle(color: AppColors.verdeEscuro, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _salvarRefeicao,
                      child: Text(_indiceEmEdicao != null ? 'Salvar alterações' : 'Adicionar refeição ao plano'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // LISTA DE REFEIÇÕES JÁ CRIADAS
            const Text('Refeições do plano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_refeicoes.isEmpty) const Text('Nenhuma refeição criada ainda.', style: TextStyle(color: AppColors.textoSecundario)),
            ...List.generate(_refeicoes.length, (index) => _buildCardRefeicao(index)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String valor, {bool destaque = false, IconData? icone}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textoSecundario, fontSize: 11)),
                if (icone != null) Icon(icone, size: 14, color: AppColors.verdeEscuro),
              ],
            ),
            const SizedBox(height: 6),
            Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: destaque ? AppColors.verde : AppColors.textoPrincipal)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaIngrediente(int index) {
    final item = _ingredientesForm[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: item.alimento,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Alimento', isDense: true, border: OutlineInputBorder()),
              items: _bancoAlimentos.keys.map((nome) => DropdownMenuItem(value: nome, child: Text(nome, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (valor) => setState(() => item.alimento = valor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.gramas == 0 ? '' : item.gramas.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gramas', isDense: true, border: OutlineInputBorder()),
              onChanged: (valor) => setState(() => item.gramas = double.tryParse(valor) ?? 0),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removerIngrediente(index),
            icon: const Icon(Icons.close, color: AppColors.vermelho),
            style: IconButton.styleFrom(backgroundColor: AppColors.vermelhoClaro),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRefeicao(int index) {
    final refeicao = _refeicoes[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(refeicao.tipo, style: const TextStyle(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editarRefeicao(index),
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF)),
                    ),
                    IconButton(
                      onPressed: () => _excluirRefeicao(index),
                      icon: const Icon(Icons.delete, size: 18, color: AppColors.vermelho),
                      style: IconButton.styleFrom(backgroundColor: AppColors.vermelhoClaro),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            ...refeicao.ingredientes.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${i.alimento} — ${i.gramas.toStringAsFixed(0)}g', style: const TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
                      Text('${i.calorias} kcal', style: const TextStyle(color: AppColors.verdeEscuro, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${refeicao.totalCalorias} kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}