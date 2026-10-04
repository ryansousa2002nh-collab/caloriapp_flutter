import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool _notificacoesDieta = true;
  bool _notificacoesAgua = false;
  bool _notificacoesPagamento = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'configuracoes'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Geral'),
            _buildSettingsContainer([
              _buildListTile(
                icone: Icons.person_outline,
                titulo: 'Editar Perfil',
                subtitulo: 'Atualize seus dados pessoais e foto',
                onTap: () {},
              ),
              _buildDivider(),
              _buildListTile(
                icone: Icons.lock_outline,
                titulo: 'Segurança',
                subtitulo: 'Mude sua senha ou habilite biometria',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Notificações'),
            _buildSettingsContainer([
              _buildSwitchTile(
                icone: Icons.restaurant_outlined,
                titulo: 'Lembretes de Dieta',
                subtitulo: 'Seja avisado sobre suas próximas refeições',
                valor: _notificacoesDieta,
                onChanged: (val) => setState(() => _notificacoesDieta = val),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icone: Icons.water_drop_outlined,
                titulo: 'Lembrete de Água',
                subtitulo: 'Avise-me para beber água de hora em hora',
                valor: _notificacoesAgua,
                onChanged: (val) => setState(() => _notificacoesAgua = val),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icone: Icons.attach_money_outlined,
                titulo: 'Alertas Financeiros',
                subtitulo: 'Notificações de pacientes em débito',
                valor: _notificacoesPagamento,
                onChanged: (val) => setState(() => _notificacoesPagamento = val),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Sobre o App'),
            _buildSettingsContainer([
              _buildListTile(
                icone: Icons.help_outline,
                titulo: 'Ajuda e Suporte',
                onTap: () {},
              ),
              _buildDivider(),
              _buildListTile(
                icone: Icons.info_outline,
                titulo: 'Termos de Uso',
                onTap: () {},
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Versão do Aplicativo', style: TextStyle(color: AppColors.getTextoPrincipal(context))),
                    Text('1.0.5', style: TextStyle(color: AppColors.getTextoSecundario(context), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]),
            
            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Excluir minha conta', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextoPrincipal(context),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Material(
      color: AppColors.getCard(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.getBorda(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icone,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icone, color: AppColors.verde),
      title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
      subtitle: subtitulo != null ? Text(subtitulo, style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context))) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icone, color: AppColors.verde),
      title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
      subtitle: Text(subtitulo, style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context))),
      value: valor,
      activeColor: AppColors.verde,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.getBorda(context));
  }
}
