import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/paciente_model.dart';
import '../services/chat_service.dart';
import '../services/dados_service.dart';
import '../theme/app_theme.dart';
import 'criar_dieta_page.dart';

class ChatNutriPage extends StatefulWidget {
  final PacienteModel paciente;
  final bool isNutri;

  const ChatNutriPage({
    super.key,
    required this.paciente,
    this.isNutri = false,
  });

  @override
  State<ChatNutriPage> createState() => _ChatNutriPageState();
}

class _ChatNutriPageState extends State<ChatNutriPage> {
  final ChatService _chatService = ChatService();
  final DadosService _dadosService = DadosService();
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _sugestoesPerguntas = [
    'Dúvida sobre a dieta 🥗',
    'Posso substituir um alimento? 🍠',
    'Horário das refeições ⏰',
    'Como tomar suplementação? 💪',
    'Vontade de comer doce 🍫',
    'Quantidade de água recomendada 💧',
  ];

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    ChatService.conversaAtivaPacienteId = widget.paciente.id;
    _chatService.addListener(_onMensagensAtualizadas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcarLidas();
      _scrollParaFim(animar: false);
      _chatService.sincronizarComBackend(pacienteId: widget.paciente.id);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _chatService.sincronizarComBackend(pacienteId: widget.paciente.id);
      }
    });
  }

  @override
  void dispose() {
    if (ChatService.conversaAtivaPacienteId == widget.paciente.id) {
      ChatService.conversaAtivaPacienteId = null;
    }
    _pollingTimer?.cancel();
    _chatService.removeListener(_onMensagensAtualizadas);
    _mensagemController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMensagensAtualizadas() {
    if (mounted) {
      _marcarLidas();
      setState(() {});
      _scrollParaFim(animar: true);
    }
  }

  void _marcarLidas() {
    _chatService.marcarComoLidas(
      widget.paciente.id,
      isVisualizadoPorNutri: widget.isNutri,
    );
  }

  void _scrollParaFim({bool animar = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animar) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _enviarMensagem({String? textoPersonalizado}) async {
    final texto = (textoPersonalizado ?? _mensagemController.text).trim();
    if (texto.isEmpty) return;

    final isNutri = widget.isNutri;
    final remetente = isNutri ? 'NUTRI' : 'PACIENTE';
    final remetenteNome = isNutri ? _dadosService.nomeNutri : widget.paciente.nome;

    _mensagemController.clear();

    await _chatService.enviarMensagem(
      pacienteId: widget.paciente.id,
      pacienteNome: widget.paciente.nome,
      remetente: remetente,
      remetenteNome: remetenteNome,
      texto: texto,
    );

    _scrollParaFim(animar: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final mensagens = _chatService.obterMensagens(
      widget.paciente.id,
      pacienteNome: widget.paciente.nome,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.verde,
                  backgroundImage: widget.isNutri
                      ? null
                      : const AssetImage('assets/images/logo_nutri.jpg'),
                  child: widget.isNutri
                      ? Text(
                          widget.paciente.nome.isNotEmpty
                              ? widget.paciente.nome[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.fundoPaginaEscuro : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isNutri ? widget.paciente.nome : _dadosService.nomeNutri,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isNutri
                        ? 'Paciente • Meta: ${widget.paciente.metaCalorica.toStringAsFixed(0)} kcal'
                        : 'Nutricionista Responsável • Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isNutri
                          ? AppColors.getTextoSecundario(context)
                          : const Color(0xFF22C55E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isNutri)
            IconButton(
              icon: const Icon(Icons.assignment_outlined),
              tooltip: 'Ver Plano Prescrito',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriarDietaPage(
                      paciente: widget.paciente,
                      isNutri: true,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de boas-vindas / contexto clínico
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.verde),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isNutri
                          ? 'Canal clínico direto com ${widget.paciente.nome}. Mensagens notificam o celular do paciente.'
                          : 'Canal oficial com sua nutricionista. As mensagens notificam a Dra. Juliana em tempo real.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de mensagens
            Expanded(
              child: mensagens.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.getTextoSecundario(context)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma mensagem ainda.\nEnvie uma mensagem para iniciar a conversa!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.getTextoSecundario(context)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: mensagens.length,
                      itemBuilder: (context, index) {
                        final msg = mensagens[index];
                        final isMe = widget.isNutri ? msg.isNutri : msg.isPaciente;
                        return _buildBalaoMensagem(context, msg: msg, isMe: isMe);
                      },
                    ),
            ),

            // Chips com sugestões de dúvidas rápidas para o paciente
            if (!widget.isNutri)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _sugestoesPerguntas.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chipTexto = _sugestoesPerguntas[index];
                    return ActionChip(
                      label: Text(
                        chipTexto,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      backgroundColor: AppColors.getCard(context),
                      side: BorderSide(color: AppColors.getBorda(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () => _enviarMensagem(textoPersonalizado: chipTexto),
                    );
                  },
                ),
              ),

            // Barra de digitação
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                border: Border(
                  top: BorderSide(color: AppColors.getBorda(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.fundoPaginaEscuro : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.getBorda(context)),
                      ),
                      child: TextField(
                        controller: _mensagemController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(
                          color: AppColors.getTextoPrincipal(context),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.isNutri
                              ? 'Responder para ${widget.paciente.nome}...'
                              : 'Mensagem para a Dra. Juliana...',
                          hintStyle: TextStyle(
                            color: AppColors.getTextoSecundario(context),
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => _enviarMensagem(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.verde,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _enviarMensagem(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalaoMensagem(
    BuildContext context, {
    required MensagemChat msg,
    required bool isMe,
  }) {
    final isDark = AppColors.isDark(context);

    // Cores dos balões
    final corFundo = isMe
        ? (isDark ? AppColors.verdeFundoEscuro : const Color(0xFFD1FAE5))
        : (isDark ? AppColors.cardEscuro : const Color(0xFFF1F5F9));

    final corBorda = isMe
        ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
        : (isDark ? AppColors.bordaEscuro : const Color(0xFFE2E8F0));

    final corTexto = isMe
        ? (isDark ? const Color(0xFFF0FDF4) : const Color(0xFF065F46))
        : AppColors.getTextoPrincipal(context);

    final corHora = isMe
        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
        : AppColors.getTextoSecundario(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(color: corBorda),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    msg.isNutri ? Icons.verified : Icons.person,
                    size: 13,
                    color: msg.isNutri ? AppColors.verde : AppColors.getTextoSecundario(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    msg.remetenteNome,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: msg.isNutri ? AppColors.verde : AppColors.getTextoSecundario(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: corTexto,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg.horaFormatada,
                  style: TextStyle(
                    fontSize: 10,
                    color: corHora,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 13,
                    color: msg.lida ? const Color(0xFF2563EB) : corHora,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
