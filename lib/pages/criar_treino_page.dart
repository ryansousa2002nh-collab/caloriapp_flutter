import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CriarTreinoPage extends StatefulWidget {
  final PacienteModel paciente;

  const CriarTreinoPage({super.key, required this.paciente});

  @override
  State<CriarTreinoPage> createState() => _CriarTreinoPageState();
}

class _CriarTreinoPageState extends State<CriarTreinoPage> {
  final _nomeTreinoController = TextEditingController();
  
  bool _carregandoExercicios = true;
  bool _salvando = false;
  
  List<dynamic> _todosExercicios = []; // from backend
  
  // Represents the items the personal adds to this workout plan
  // structure: {'exercicio_id': int, 'exercicio_nome': string, 'series': int, 'repeticoes': int, 'observacoes': string}
  final List<Map<String, dynamic>> _itensTreino = [];

  @override
  void initState() {
    super.initState();
    _fetchExercicios();
  }

  Future<void> _fetchExercicios() async {
    try {
      final data = await ApiService.getExercicios();
      setState(() {
        _todosExercicios = data;
        _carregandoExercicios = false;
      });
    } catch (e) {
      print('Erro ao carregar exercícios: $e');
      setState(() => _carregandoExercicios = false);
    }
  }

  void _abrirModalAdicionarExercicio() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        int? exercicioSelecionado;
        final seriesController = TextEditingController(text: '3');
        final repeticoesController = TextEditingController(text: '12');
        final obsController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Adicionar Exercício',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Exercício',
                        border: OutlineInputBorder(),
                      ),
                      value: exercicioSelecionado,
                      items: _todosExercicios.map<DropdownMenuItem<int>>((ex) {
                        return DropdownMenuItem<int>(
                          value: ex['id'],
                          child: Text(ex['nome']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          exercicioSelecionado = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: seriesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Séries',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: repeticoesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Repetições',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsController,
                      decoration: const InputDecoration(
                        labelText: 'Observações (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.verde),
                        onPressed: () {
                          if (exercicioSelecionado == null) return;
                          
                          final exModel = _todosExercicios.firstWhere((e) => e['id'] == exercicioSelecionado);
                          
                          setState(() {
                            _itensTreino.add({
                              'exercicio': exercicioSelecionado,
                              'exercicio_nome': exModel['nome'],
                              'series': int.tryParse(seriesController.text) ?? 0,
                              'repeticoes': int.tryParse(repeticoesController.text) ?? 0,
                              'observacoes': obsController.text,
                            });
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _salvarTreino() async {
    if (_nomeTreinoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dê um nome ao treino.')));
      return;
    }
    if (_itensTreino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos um exercício.')));
      return;
    }

    setState(() => _salvando = true);

    try {
      final dados = {
        'cliente': widget.paciente.id,
        'nome': _nomeTreinoController.text.trim(),
        'itens': _itensTreino,
      };

      final sucesso = await ApiService.salvarTreino(dados);
      
      if (sucesso) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino criado com sucesso!')));
          Navigator.pop(context);
        }
      } else {
        throw Exception('Erro na API');
      }
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar treino: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treino de ${widget.paciente.nome}'),
      ),
      body: _carregandoExercicios
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nomeTreinoController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Treino (ex: Treino A - Peito)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Exercícios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _abrirModalAdicionarExercicio,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.verde),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _itensTreino.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum exercício adicionado.\nClique em "Adicionar" para começar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _itensTreino.length,
                            itemBuilder: (context, index) {
                              final item = _itensTreino[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.fitness_center),
                                  title: Text(item['exercicio_nome']),
                                  subtitle: Text('${item['series']} séries de ${item['repeticoes']} repetições\nObs: ${item['observacoes']}'),
                                  isThreeLine: item['observacoes'].toString().isNotEmpty,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _itensTreino.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.verde),
                      onPressed: _salvando ? null : _salvarTreino,
                      child: _salvando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
