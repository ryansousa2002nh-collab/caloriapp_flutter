import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';
import '../services/dados_service.dart';
import '../models/paciente_model.dart';

class HistoricoPage extends StatefulWidget {
  final PacienteModel? paciente;
  final bool isNutri;

  const HistoricoPage({
    super.key,
    this.paciente,
    this.isNutri = false,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final DadosService _dadosService = DadosService();
  late PacienteModel _paciente;

  @override
  void initState() {
    super.initState();
    _paciente = widget.paciente ?? _dadosService.getPacientes().first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNutri ? 'Histórico de ${_paciente.nome}' : 'Histórico & Metas', style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            const AppleThemeToggle(size: 28),
            if (widget.isNutri)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editarMetas,
              ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'HISTÓRICO'),
              Tab(text: 'METAS'),
            ],
            labelColor: AppColors.verde,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.verde,
          ),
        ),
        drawer: widget.isNutri ? null : const AppDrawer(paginaAtual: 'historico'),
        body: TabBarView(
          children: [
            _buildAbaHistorico(),
            _buildAbaMetas(isDark),
          ],
        ),
      ),
    );
  }



  Widget _buildAbaHistorico() {
    final registros = _paciente.registrosDiarios;
    if (registros.isEmpty) {
      return Center(
        child: Text('Nenhum histórico de refeição.', style: TextStyle(color: AppColors.getTextoSecundario(context))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: registros.length,
      itemBuilder: (context, index) {
        final registro = registros[index];
        String dataStr = 'Sem data';
        if (registro.data != null && registro.data!.isNotEmpty) {
          final p = registro.data!.split('-');
          if (p.length == 3) dataStr = '${p[2]}/${p[1]}/${p[0]}';
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              'Dia $dataStr',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextoPrincipal(context)),
            ),
            subtitle: Text(
              '${registro.totalCalorias} kcal consumidas',
              style: const TextStyle(color: AppColors.verde, fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: registro.itens.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${(item.refeicaoNome ?? 'Outros').toUpperCase()} - ${item.alimentoNome ?? 'Desconhecido'} (${item.gramas.toStringAsFixed(0)}g)',
                              style: TextStyle(color: AppColors.getTextoPrincipal(context), fontSize: 13),
                            ),
                          ),
                          Text(
                            '${item.calorias} kcal',
                            style: TextStyle(color: AppColors.getTextoSecundario(context), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _editarMetas() {
    final metas = _paciente.metas;
    final txtPesoAtual = TextEditingController(text: metas.pesoAtual.toString());
    final txtMetaPeso = TextEditingController(text: metas.metaPeso.toString());
    final txtCinturaA = TextEditingController(text: metas.cinturaAntes.toString());
    final txtCinturaD = TextEditingController(text: metas.cinturaDepois.toString());
    final txtQuadrilA = TextEditingController(text: metas.quadrilAntes.toString());
    final txtQuadrilD = TextEditingController(text: metas.quadrilDepois.toString());
    final txtCoxaA = TextEditingController(text: metas.coxaAntes.toString());
    final txtCoxaD = TextEditingController(text: metas.coxaDepois.toString());
    final txtBracoA = TextEditingController(text: metas.bracoAntes.toString());
    final txtBracoD = TextEditingController(text: metas.bracoDepois.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getFundoPagina(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Editar Metas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.getTextoPrincipal(context))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCampoEdicao('Peso Atual (kg)', txtPesoAtual),
                _buildCampoEdicao('Meta de Peso (kg)', txtMetaPeso),
                const Divider(height: 32),
                Text('Medidas (Antes / Depois)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextoPrincipal(context))),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _buildCampoEdicao('Cintura Antes', txtCinturaA)), const SizedBox(width: 8), Expanded(child: _buildCampoEdicao('Cintura Depois', txtCinturaD))]),
                Row(children: [Expanded(child: _buildCampoEdicao('Quadril Antes', txtQuadrilA)), const SizedBox(width: 8), Expanded(child: _buildCampoEdicao('Quadril Depois', txtQuadrilD))]),
                Row(children: [Expanded(child: _buildCampoEdicao('Coxa Antes', txtCoxaA)), const SizedBox(width: 8), Expanded(child: _buildCampoEdicao('Coxa Depois', txtCoxaD))]),
                Row(children: [Expanded(child: _buildCampoEdicao('Braço Antes', txtBracoA)), const SizedBox(width: 8), Expanded(child: _buildCampoEdicao('Braço Depois', txtBracoD))]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.verde, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      setState(() {

                        metas.pesoAtual = double.tryParse(txtPesoAtual.text.replaceAll(',', '.')) ?? metas.pesoAtual;
                        metas.metaPeso = double.tryParse(txtMetaPeso.text.replaceAll(',', '.')) ?? metas.metaPeso;
                        metas.cinturaAntes = double.tryParse(txtCinturaA.text.replaceAll(',', '.')) ?? metas.cinturaAntes;
                        metas.cinturaDepois = double.tryParse(txtCinturaD.text.replaceAll(',', '.')) ?? metas.cinturaDepois;
                        metas.quadrilAntes = double.tryParse(txtQuadrilA.text.replaceAll(',', '.')) ?? metas.quadrilAntes;
                        metas.quadrilDepois = double.tryParse(txtQuadrilD.text.replaceAll(',', '.')) ?? metas.quadrilDepois;
                        metas.coxaAntes = double.tryParse(txtCoxaA.text.replaceAll(',', '.')) ?? metas.coxaAntes;
                        metas.coxaDepois = double.tryParse(txtCoxaD.text.replaceAll(',', '.')) ?? metas.coxaDepois;
                        metas.bracoAntes = double.tryParse(txtBracoA.text.replaceAll(',', '.')) ?? metas.bracoAntes;
                        metas.bracoDepois = double.tryParse(txtBracoD.text.replaceAll(',', '.')) ?? metas.bracoDepois;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metas atualizadas com sucesso!')));
                    },
                    child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampoEdicao(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildAbaMetas(bool isDark) {
    final metas = _paciente.metas;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acompanhamento de Evolução',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextoPrincipal(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Veja os resultados alcançados e as metas ativas.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextoSecundario(context),
            ),
          ),
          const SizedBox(height: 24),
          
          // Cards de Metas
          Row(
            children: [
              Expanded(child: _buildMetaCard('Peso Atual', '${metas.pesoAtual} kg', Icons.speed, isDark ? const Color(0xFF6EE7B7) : AppColors.verde)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetaCard('Meta de Peso', '${metas.metaPeso} kg', Icons.flag_outlined, Colors.orange)),
            ],
          ),
          
          const SizedBox(height: 32),
          Text(
            'Progresso da Meta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextoPrincipal(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            titulo: 'Dias na Dieta (Este Mês)',
            valorAtual: 22,
            valorTotal: 30,
            sufixo: 'dias',
            cor: Colors.blueAccent,
          ),
          
          const SizedBox(height: 32),
          Text(
            'Histórico de Medidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextoPrincipal(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildMedidaRow('Cintura', '${metas.cinturaAntes} cm', '${metas.cinturaDepois} cm', _formatDiff(metas.cinturaDepois - metas.cinturaAntes)),
          _buildMedidaRow('Quadril', '${metas.quadrilAntes} cm', '${metas.quadrilDepois} cm', _formatDiff(metas.quadrilDepois - metas.quadrilAntes)),
          _buildMedidaRow('Coxa', '${metas.coxaAntes} cm', '${metas.coxaDepois} cm', _formatDiff(metas.coxaDepois - metas.coxaAntes)),
          _buildMedidaRow('Braço', '${metas.bracoAntes} cm', '${metas.bracoDepois} cm', _formatDiff(metas.bracoDepois - metas.bracoAntes)),
        ],
      ),
    );
  }

  String _formatDiff(double diff) {
    if (diff > 0) return '+${diff.toStringAsFixed(1)} cm';
    return '${diff.toStringAsFixed(1)} cm';
  }

  Widget _buildMetaCard(String titulo, String valor, IconData icone, Color corIcone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorda(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: corIcone, size: 28),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextoPrincipal(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextoSecundario(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String titulo,
    required double valorAtual,
    required double valorTotal,
    required String sufixo,
    required Color cor,
  }) {
    final progresso = (valorAtual / valorTotal).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context)),
            ),
            Text(
              '${valorAtual.toStringAsFixed(1)} / ${valorTotal.toStringAsFixed(1)} $sufixo',
              style: TextStyle(fontWeight: FontWeight.bold, color: cor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 12,
            backgroundColor: AppColors.getBorda(context),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }

  Widget _buildMedidaRow(String medida, String antes, String depois, String diff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorda(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              medida,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextoPrincipal(context)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Antes', style: TextStyle(fontSize: 10, color: AppColors.getTextoSecundario(context))),
                Text(antes, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Depois', style: TextStyle(fontSize: 10, color: AppColors.getTextoSecundario(context))),
                Text(depois, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getVerdeDestaque(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              diff,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.isDark(context) ? const Color(0xFF4ADE80) : AppColors.verdeEscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
