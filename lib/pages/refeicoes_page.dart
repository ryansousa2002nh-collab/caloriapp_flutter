import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class RefeicoesPage extends StatefulWidget {
  const RefeicoesPage({super.key});

  @override
  State<RefeicoesPage> createState() => _RefeicoesPageState();
}

class _RefeicoesPageState extends State<RefeicoesPage> {
  List<dynamic> _refeicoes = [];
  bool _carregando = true;
  String _erro = '';

  static const double metaDiaria = 2000; // TODO: trazer da API futuramente

  @override
  void initState() {
    super.initState();
    _buscarRefeicoes();
  }

  Future<void> _buscarRefeicoes() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}refeicoes/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _refeicoes = jsonDecode(response.body);
        _carregando = false;
      });
    } else {
      setState(() {
        _erro = 'Não foi possível carregar as refeições.';
        _carregando = false;
      });
    }
  }

  double get _totalConsumido {
    double total = 0;
    for (var r in _refeicoes) {
      total += double.tryParse(r['total_calorias'].toString()) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas refeições')),
      drawer: const AppDrawer(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro.isNotEmpty
              ? Center(child: Text(_erro, style: const TextStyle(color: AppColors.vermelho)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registre o que você come e acompanhe suas calorias.',
                        style: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      _buildResumo(),
                      const SizedBox(height: 28),
                      const Text(
                        'Refeições de hoje',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (_refeicoes.isEmpty)
                        const Text('Nenhuma refeição registrada ainda.', style: TextStyle(color: AppColors.textoSecundario)),
                      ..._refeicoes.map((r) => _buildMealCard(r)),
                    ],
                  ),
                ),
    );
  }

  // Linha com os 3 cards de resumo (Consumidas / Meta / Restante)
  Widget _buildResumo() {
    final restante = metaDiaria - _totalConsumido;
    return Row(
      children: [
        Expanded(child: _summaryCard('Calorias consumidas', '${_totalConsumido.toStringAsFixed(0)} kcal', destaque: true)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Meta diária', '${metaDiaria.toStringAsFixed(0)} kcal')),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Restante', '${restante.toStringAsFixed(0)} kcal')),
      ],
    );
  }

  Widget _summaryCard(String label, String value, {bool destaque = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textoSecundario, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: destaque ? AppColors.verde : AppColors.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de uma refeição, com lista de alimentos e total (igual ao seu HTML)
  Widget _buildMealCard(dynamic refeicao) {
    final itens = refeicao['itemrefeicao_set'] as List<dynamic>;
    final dataHora = DateTime.parse(refeicao['data_hora']);
    final horario = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(refeicao['tipo'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(horario, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ...itens.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['alimento_nome']} — ${item['quantidade_gramas']}g',
                        style: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
                      ),
                      Text(
                        '${item['calorias_totais']} kcal',
                        style: const TextStyle(color: AppColors.verdeEscuro, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${refeicao['total_calorias']} kcal', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}