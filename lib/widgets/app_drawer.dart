import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/pacientes_page.dart';
import '../pages/refeicoes_page.dart';
import '../pages/historico_page.dart';
import '../pages/comunidade_page.dart';
import '../pages/configuracoes_page.dart';
import '../pages/chat_nutri_page.dart';
import '../pages/conversas_nutri_page.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/dados_service.dart';
import '../services/lembretes_service.dart';
import '../theme/app_theme.dart';
import 'apple_theme_toggle.dart';

class AppDrawer extends StatelessWidget {
  final String paginaAtual; // 'pacientes', 'refeicoes', 'historico', etc.

  const AppDrawer({
    super.key,
    this.paginaAtual = 'pacientes',
  });

  @override
  Widget build(BuildContext context) {
    final dadosService = DadosService();
    final isNutri = dadosService.isNutri;

    return Drawer(
      backgroundColor: AppColors.getCard(context),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                children: [
                  // Cabeçalho da Clínica / App
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.getVerdeDestaque(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getVerdeDestaqueBorda(context)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.verde,
                          backgroundImage: isNutri ? const AssetImage('assets/images/logo_nutri.jpg') : null,
                          child: isNutri
                              ? null
                              : const Text(
                                  'CL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNutri ? dadosService.nomeNutri : dadosService.getPacienteAtivo().nome,
                                style: TextStyle(
                                  color: AppColors.getTextoPrincipal(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isNutri ? AppColors.verde : Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isNutri ? 'Nutricionista' : 'Paciente',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Menu Items
                  if (isNutri)
                    _drawerItem(
                      context,
                      icone: Icons.people_alt_outlined,
                      texto: 'Pacientes',
                      ativo: paginaAtual == 'pacientes',
                      onTap: () {
                        Navigator.pop(context);
                        if (paginaAtual != 'pacientes') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PacientesPage()),
                          );
                        }
                      },
                    ),

                  _drawerItem(
                    context,
                    icone: Icons.restaurant_outlined,
                    texto: 'Refeições',
                    ativo: paginaAtual == 'refeicoes',
                    onTap: () {
                      Navigator.pop(context);
                      if (paginaAtual != 'refeicoes') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const RefeicoesPage()),
                        );
                      }
                    },
                  ),

                  _drawerItem(
                    context,
                    icone: Icons.bar_chart_outlined,
                    texto: 'Histórico & Metas',
                    ativo: paginaAtual == 'historico',
                    onTap: () {
                      Navigator.pop(context);
                      if (paginaAtual != 'historico') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoricoPage()),
                        );
                      }
                    },
                  ),

                  _drawerItem(
                    context,
                    icone: Icons.auto_awesome_mosaic_outlined,
                    texto: 'Comunidade',
                    ativo: paginaAtual == 'comunidade',
                    onTap: () {
                      Navigator.pop(context);
                      if (paginaAtual != 'comunidade') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ComunidadePage()),
                        );
                      }
                    },
                  ),

                  _drawerItem(
                    context,
                    icone: Icons.chat_bubble_outline,
                    texto: isNutri ? 'Mensagens dos Pacientes' : 'Falar com a Nutri',
                    ativo: paginaAtual == 'chat',
                    corIcone: AppColors.verde,
                    trailing: AnimatedBuilder(
                      animation: ChatService(),
                      builder: (context, _) {
                        final chatService = ChatService();
                        final naoLidas = isNutri
                            ? chatService.obterTotalNaoLidasParaNutri()
                            : chatService.obterTotalNaoLidasParaPaciente(dadosService.getPacienteAtivo().id);
                        if (naoLidas <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.rosaVibrante,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$naoLidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isNutri) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ConversasNutriPage()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatNutriPage(
                              paciente: dadosService.getPacienteAtivo(),
                              isNutri: false,
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  _drawerItem(
                    context,
                    icone: Icons.settings_outlined,
                    texto: 'Configurações',
                    ativo: paginaAtual == 'configuracoes',
                    onTap: () {
                      Navigator.pop(context);
                      if (paginaAtual != 'configuracoes') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ConfiguracoesPage()),
                        );
                      }
                    },
                  ),

                  _drawerItem(
                    context,
                    icone: Icons.notifications_active_outlined,
                    texto: 'Lembretes de Refeição',
                    ativo: false,
                    corIcone: const Color(0xFF6EE7B7),
                    onTap: () async {
                      Navigator.pop(context);
                      final paciente = dadosService.getPacienteAtivo();
                      final proxima = LembretesService.calcularProximaRefeicao(paciente.planoAlimentar);
                      if (proxima != null) {
                        await LembretesService.dispararNotificacaoImediata(
                          titulo: '🥗 Lembrete: ${proxima.refeicao.tipo}',
                          corpo: 'Horário estabelecido pela Nutri: ${proxima.horario} (${proxima.descricaoTempo}). Bom apetite!',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Próxima Refeição: ${proxima.refeicao.tipo} às ${proxima.horario} (${proxima.descricaoTempo}). Notificação de teste enviada!',
                            ),
                            backgroundColor: AppColors.verde,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nenhuma refeição com horário estabelecido no momento.'),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Tile do Modo Noturno (Maçã / Maçã Mordida)
                  const AppleThemeDrawerTile(),
                ],
              ),
            ),

            // Rodapé com logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: _drawerItem(
                context,
                icone: Icons.logout,
                texto: 'Sair do aplicativo',
                ativo: false,
                corIcone: AppColors.vermelho,
                onTap: () async {
                  await ChatService().limpar();
                  await ApiService.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icone,
    required String texto,
    required bool ativo,
    required VoidCallback onTap,
    Color? corIcone,
    Widget? trailing,
  }) {
    final isDark = AppColors.isDark(context);
    final fundoAtivo = isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro;
    final corTextoAtivo = isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro;
    final corTextoInativo = AppColors.getTextoPrincipal(context);
    final corIconeInativo = AppColors.getTextoSecundario(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: ativo ? fundoAtivo : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(
          icone,
          color: corIcone ?? (ativo ? corTextoAtivo : corIconeInativo),
          size: 20,
        ),
        title: Text(
          texto,
          style: TextStyle(
            color: ativo ? corTextoAtivo : corTextoInativo,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
