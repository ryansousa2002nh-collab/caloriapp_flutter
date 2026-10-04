import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';
import '../services/dados_service.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  final DadosService _dadosService = DadosService();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final pacientes = _dadosService.getPacientes();
    
    final totalRecebido = pacientes.where((p) => p.isPago).length * 150.0; // Simulando R$ 150 por consulta
    final totalPendente = pacientes.where((p) => p.isDebito).length * 150.0;
    
    final pacientesEmDebito = pacientes.where((p) => p.isDebito).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'financeiro'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visão Geral Mensal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextoPrincipal(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Acompanhe seus recebimentos e pendências.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextoSecundario(context),
              ),
            ),
            const SizedBox(height: 24),

            // Main Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [AppColors.verde, AppColors.verdeEscuro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.verde.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Previsto',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${(totalRecebido + totalPendente).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniFinanceCard('Recebido', totalRecebido, Icons.arrow_downward, Colors.white),
                      _buildMiniFinanceCard('Pendente', totalPendente, Icons.arrow_upward, const Color(0xFFFCA5A5)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pacientes Pendentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextoPrincipal(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getVermelhoDestaque(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pacientesEmDebito.length} abertos',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF87171) : AppColors.vermelho,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (pacientesEmDebito.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.verde.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Todos os pacientes estão em dia!',
                        style: TextStyle(color: AppColors.getTextoSecundario(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...pacientesEmDebito.map((p) => _buildPendenteCard(p.nome, 150.0, p.fotoUrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFinanceCard(String label, double valor, IconData icone, Color corTexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icone, size: 14, color: corTexto),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(color: corTexto, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPendenteCard(String nome, double valor, String? fotoUrl) {
    final isDark = AppColors.isDark(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorda(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
            child: fotoUrl == null
                ? Text(
                    nome[0].toUpperCase(),
                    style: TextStyle(color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextoPrincipal(context)),
                ),
                Text(
                  'Vencido há 5 dias',
                  style: TextStyle(color: isDark ? const Color(0xFFF87171) : AppColors.vermelho, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextoPrincipal(context)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            color: AppColors.verde,
            tooltip: 'Enviar cobrança',
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
