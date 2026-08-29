import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  'JulianaNutri',
                  style: TextStyle(
                    color: AppColors.verde,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _drawerItem(context, '🏠', 'Início', ativo: false),
              _drawerItem(context, '🍽️', 'Refeições', ativo: true), // tela atual
              _drawerItem(context, '📊', 'Histórico de Refeições', ativo: false),
              _drawerItem(context, '👥', 'Comunidade', ativo: false),
              _drawerItem(context, '💰', 'Financeiro', ativo: false),
              _drawerItem(context, '⚙️', 'Configurações', ativo: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String icone, String texto, {required bool ativo}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: ativo ? AppColors.verdeClaro : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => Navigator.pop(context), // fecha o drawer (troque depois pra navegar de verdade)
        leading: Text(icone, style: const TextStyle(fontSize: 18)),
        title: Text(
          texto,
          style: TextStyle(
            color: ativo ? AppColors.verdeEscuro : AppColors.textoSecundario,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}