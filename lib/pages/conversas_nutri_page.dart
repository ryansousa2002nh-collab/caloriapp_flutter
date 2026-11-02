import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import 'chat_nutri_page.dart';

class ConversasNutriPage extends StatefulWidget {
  const ConversasNutriPage({super.key});

  @override
  State<ConversasNutriPage> createState() => _ConversasNutriPageState();
}

class _ConversasNutriPageState extends State<ConversasNutriPage> {
  final DadosService _dadosService = DadosService();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_atualizar);
  }

  @override
  void dispose() {
    _chatService.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pacientes = _dadosService.pacientes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mensagens dos Pacientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: pacientes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50, color: AppColors.getTextoSecundario(context)),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum paciente cadastrado para conversar.',
                    style: TextStyle(color: AppColors.getTextoSecundario(context)),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: pacientes.length,
              separatorBuilder: (context, _) => Divider(
                height: 1,
                color: AppColors.getBorda(context),
                indent: 68,
              ),
              itemBuilder: (context, index) {
                final paciente = pacientes[index];
                final ultimaMsg = _chatService.obterUltimaMensagem(paciente.id);
                final naoLidas = _chatService.obterNaoLidasDoPaciente(paciente.id);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.verde,
                        child: Text(
                          paciente.nome.isNotEmpty ? paciente.nome[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (naoLidas > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.rosaVibrante,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$naoLidas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          paciente.nome,
                          style: TextStyle(
                            fontWeight: naoLidas > 0 ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.getTextoPrincipal(context),
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ultimaMsg != null)
                        Text(
                          ultimaMsg.horaFormatada,
                          style: TextStyle(
                            fontSize: 11,
                            color: naoLidas > 0 ? AppColors.verde : AppColors.getTextoSecundario(context),
                            fontWeight: naoLidas > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    ultimaMsg != null
                        ? (ultimaMsg.isNutri ? 'Você: ${ultimaMsg.texto}' : ultimaMsg.texto)
                        : 'Toque para iniciar uma conversa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: naoLidas > 0 ? FontWeight.w600 : FontWeight.normal,
                      color: naoLidas > 0
                          ? AppColors.getTextoPrincipal(context)
                          : AppColors.getTextoSecundario(context),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatNutriPage(
                          paciente: paciente,
                          isNutri: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
