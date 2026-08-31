import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
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

  @override
  void initState() {
    super.initState();
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

  int get _totalConsumido => _paciente.totalCaloriasPlano;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Refeições', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'refeicoes'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner explicativo do paciente
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
                      'Plano alimentar prescrito pela Dra. Juliana. Acompanhe suas metas de hoje.',
                      style: TextStyle(color: AppColors.getTextoPrincipal(context), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARDS DE RESUMO
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

            // Barra de Progresso
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

            const SizedBox(height: 24),

            Text(
              'Refeições prescritas para hoje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextoPrincipal(context),
              ),
            ),
            const SizedBox(height: 12),

            if (_paciente.planoAlimentar.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Nenhuma refeição prescrita ainda.',
                    style: TextStyle(color: AppColors.getTextoSecundario(context)),
                  ),
                ),
              ),

            ..._paciente.planoAlimentar.map((refeicao) => _buildMealCard(refeicao)),
          ],
        ),
      ),
    );
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

  Widget _buildMealCard(dynamic refeicao) {
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
                if (refeicao.horarioSugerido != null)
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
                    Text(
                      '${item.alimentoNome} — ${item.gramas.toStringAsFixed(0)}g',
                      style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13),
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