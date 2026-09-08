import 'package:flutter/material.dart';
import '../models/treino_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';

class TreinosPage extends StatefulWidget {
  const TreinosPage({super.key});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  List<TreinoModel> _treinos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTreinos();
  }

  Future<void> _loadTreinos() async {
    setState(() => _isLoading = true);
    try {
      final jsonList = await ApiService.getMeusTreinos();
      setState(() {
        _treinos = jsonList.map((e) => TreinoModel.fromJson(e)).toList();
      });
    } catch (e) {
      // Handle error implicitly
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarConcluido(TreinoModel treino) async {
    if (treino.concluidoHoje) return;

    final success = await ApiService.marcarTreinoConcluido(treino.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino marcado como concluído! 💪'),
          backgroundColor: AppColors.verde,
        ),
      );
      _loadTreinos(); // Reload to get updated state
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao registrar conclusão. Tente novamente.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'treinos'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.verde))
          : _treinos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center, size: 64, color: AppColors.bordaCinza),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma ficha de treino encontrada.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.getTextoSecundario(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.verde,
                  onRefresh: _loadTreinos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _treinos.length,
                    itemBuilder: (context, index) {
                      final treino = _treinos[index];
                      return _buildTreinoCard(treino, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildTreinoCard(TreinoModel treino, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Card
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getVerdeDestaque(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    treino.nome,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            
            // Lista de Exercícios
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Ver Exercícios (${treino.itens.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextoSecundario(context),
                  ),
                ),
                children: treino.itens.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.verde),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.exercicioNome,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextoPrincipal(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.series} séries x ${item.repeticoes} repetições',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.observacoes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Obs: ${item.observacoes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.getTextoSecundario(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Botão de Conclusão
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: treino.concluidoHoje ? null : () => _marcarConcluido(treino),
                icon: Icon(
                  treino.concluidoHoje ? Icons.check_circle : Icons.check_circle_outline,
                  color: treino.concluidoHoje ? AppColors.verde : Colors.white,
                ),
                label: Text(
                  treino.concluidoHoje ? 'Concluído Hoje' : 'Marcar como Concluído',
                  style: TextStyle(
                    color: treino.concluidoHoje ? AppColors.verde : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: treino.concluidoHoje
                      ? (isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro)
                      : AppColors.verde,
                  elevation: 0,
                  disabledBackgroundColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
                  disabledForegroundColor: AppColors.verde,
                  side: treino.concluidoHoje
                      ? BorderSide(color: AppColors.getVerdeDestaqueBorda(context))
                      : BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
