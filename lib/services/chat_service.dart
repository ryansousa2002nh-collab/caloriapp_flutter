import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import 'api_service.dart';
import 'lembretes_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instancia = ChatService._interno();
  factory ChatService() => _instancia;
  ChatService._interno() {
    carregarMensagens();
    unawaited(sincronizarComBackend());
  }

  static const String _keyMensagens = 'nutri_chat_mensagens_clean_v1';
  final List<MensagemChat> _mensagens = [];

  /// ID do paciente cuja conversa está aberta na tela neste exato momento.
  /// Quando definido, silencia notificações locais para esta conversa.
  static int? conversaAtivaPacienteId;

  /// IDs de mensagens que já dispararam notificação nesta sessão para evitar repetições.
  final Set<String> _notificadasIds = {};

  List<MensagemChat> get todasMensagens => List.unmodifiable(_mensagens);

  /// Limpa as mensagens em memória e no armazenamento local (usado no logout/troca de usuário)
  Future<void> limpar() async {
    _mensagens.clear();
    _notificadasIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMensagens);
    } catch (_) {}
    notifyListeners();
  }

  /// Carrega as mensagens salvas no armazenamento local
  Future<void> carregarMensagens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dadosSalvos = prefs.getString(_keyMensagens);

      _mensagens.clear();
      if (dadosSalvos != null && dadosSalvos.isNotEmpty) {
        final List<dynamic> listaJson = jsonDecode(dadosSalvos);
        for (final item in listaJson) {
          _mensagens.add(MensagemChat.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  /// Salva todas as mensagens no SharedPreferences
  Future<void> _salvarMensagens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listaJson = _mensagens.map((m) => m.toJson()).toList();
      await prefs.setString(_keyMensagens, jsonEncode(listaJson));
    } catch (_) {}
  }

  /// Sincroniza as mensagens com a API em nuvem e notifica estritamente o destinatário
  Future<void> sincronizarComBackend({int? pacienteId}) async {
    try {
      final listJson = await ApiService.getMensagensChat(pacienteId: pacienteId);
      if (listJson.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final tipoLogado = prefs.getString('tipo_usuario') ?? 'NUTRI';
      final isNutriLogado = tipoLogado == 'NUTRI';

      bool houveMudanca = false;

      for (final item in listJson) {
        final novaMsg = MensagemChat.fromJson(Map<String, dynamic>.from(item as Map));

        // 1. Procura se a mensagem já existe por ID do servidor
        int index = _mensagens.indexWhere((m) => m.id == novaMsg.id);

        // 2. Se não achou por ID, procura se era uma mensagem local temporária recém-enviada
        // que agora retornou com o ID definitivo do servidor
        if (index < 0) {
          index = _mensagens.indexWhere((m) =>
            m.id.startsWith('msg_') &&
            m.texto == novaMsg.texto &&
            m.remetente == novaMsg.remetente &&
            (pacienteId == null || m.pacienteId == novaMsg.pacienteId)
          );
        }

        if (index >= 0) {
          // Atualiza a mensagem existente com os dados oficiais do servidor
          if (_mensagens[index].id != novaMsg.id || _mensagens[index].lida != novaMsg.lida) {
            _mensagens[index] = novaMsg;
            houveMudanca = true;
          }
        } else {
          // Mensagem realmente nova recebida do servidor
          _mensagens.add(novaMsg);
          houveMudanca = true;

          // REGRAS ESTRITAS DE NOTIFICAÇÃO:
          // 1. Mensagem enviada pelo próprio usuário? NUNCA notifica quem enviou!
          final enviadaPorMim = novaMsg.minhaMensagem ||
              (isNutriLogado && novaMsg.remetente == 'NUTRI') ||
              (!isNutriLogado && novaMsg.remetente == 'PACIENTE');
          if (enviadaPorMim) continue;

          // 2. Mensagem já lida? Não notifica.
          if (novaMsg.lida) continue;

          // 3. Usuário está com o chat aberto na tela desta mesma conversa? Silencia push nativo.
          if (conversaAtivaPacienteId != null && conversaAtivaPacienteId == novaMsg.pacienteId) {
            continue;
          }

          // 4. Já disparou notificação desta mensagem nesta sessão? Não duplica!
          if (_notificadasIds.contains(novaMsg.id)) continue;
          _notificadasIds.add(novaMsg.id);

          // 5. Destinatários estritos:
          //    - Nutricionista só é notificada sobre mensagens de pacientes.
          //    - Paciente só é notificado sobre mensagens da nutricionista.
          if (isNutriLogado && novaMsg.remetente == 'PACIENTE') {
            await LembretesService.dispararNotificacaoChat(
              titulo: '💬 Nova mensagem de ${novaMsg.pacienteNome}',
              corpo: novaMsg.texto,
            );
          } else if (!isNutriLogado && novaMsg.remetente == 'NUTRI') {
            await LembretesService.dispararNotificacaoChat(
              titulo: '👩‍⚕️ Dra. Juliana Braz (Nutri)',
              corpo: novaMsg.texto,
            );
          }
        }
      }

      if (houveMudanca) {
        _mensagens.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        await _salvarMensagens();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Retorna as mensagens de um paciente específico (ordenadas por data)
  List<MensagemChat> obterMensagens(int pacienteId, {String pacienteNome = 'Paciente'}) {
    final mensagensDoPaciente = _mensagens.where((m) => m.pacienteId == pacienteId).toList();

    if (mensagensDoPaciente.isEmpty) {
      final msgInicial = MensagemChat(
        id: 'msg_welcome_$pacienteId',
        pacienteId: pacienteId,
        pacienteNome: pacienteNome,
        remetente: 'NUTRI',
        remetenteNome: 'Dra. Juliana Braz',
        texto: 'Olá, $pacienteNome! Sou a Dra. Juliana Braz, sua nutricionista. Este é o nosso canal direto e exclusivo para tirar dúvidas sobre sua dieta, combinações de alimentos ou como você está se sentindo. Como posso te ajudar hoje? 🍏',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        lida: true,
        minhaMensagem: false,
        paraMim: true,
        notificar: false,
      );
      return [msgInicial];
    }

    mensagensDoPaciente.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return mensagensDoPaciente;
  }

  /// Retorna a última mensagem trocada com o paciente
  MensagemChat? obterUltimaMensagem(int pacienteId) {
    final msgs = _mensagens.where((m) => m.pacienteId == pacienteId).toList();
    if (msgs.isEmpty) return null;
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return msgs.last;
  }

  /// Quantidade de mensagens não lidas para a Nutri (enviadas por pacientes)
  int obterTotalNaoLidasParaNutri() {
    return _mensagens.where((m) => m.remetente == 'PACIENTE' && !m.lida).length;
  }

  /// Quantidade de mensagens não lidas para um paciente específico (enviadas pela Nutri)
  int obterTotalNaoLidasParaPaciente(int pacienteId) {
    return _mensagens.where((m) => m.pacienteId == pacienteId && m.remetente == 'NUTRI' && !m.lida).length;
  }

  /// Quantidade de mensagens não lidas de um paciente específico para a Nutri
  int obterNaoLidasDoPaciente(int pacienteId) {
    return _mensagens.where((m) => m.pacienteId == pacienteId && m.remetente == 'PACIENTE' && !m.lida).length;
  }

  /// Marca as mensagens de uma conversa como lidas
  Future<void> marcarComoLidas(int pacienteId, {required bool isVisualizadoPorNutri}) async {
    bool alterou = false;
    for (int i = 0; i < _mensagens.length; i++) {
      final m = _mensagens[i];
      if (m.pacienteId == pacienteId) {
        if (isVisualizadoPorNutri && m.remetente == 'PACIENTE' && !m.lida) {
          _mensagens[i] = m.copyWith(lida: true);
          alterou = true;
        } else if (!isVisualizadoPorNutri && m.remetente == 'NUTRI' && !m.lida) {
          _mensagens[i] = m.copyWith(lida: true);
          alterou = true;
        }
      }
    }
    if (alterou) {
      await _salvarMensagens();
      notifyListeners();
    }
    unawaited(ApiService.marcarMensagensLidasChat(pacienteId: pacienteId));
  }

  /// Envia uma nova mensagem no chat e sincroniza com o servidor
  Future<void> enviarMensagem({
    required int pacienteId,
    required String pacienteNome,
    required String remetente, // 'PACIENTE' ou 'NUTRI'
    required String remetenteNome,
    required String texto,
  }) async {
    final cleanTexto = texto.trim();
    if (cleanTexto.isEmpty) return;

    final tempId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final novaMensagem = MensagemChat(
      id: tempId,
      pacienteId: pacienteId,
      pacienteNome: pacienteNome,
      remetente: remetente,
      remetenteNome: remetenteNome,
      texto: cleanTexto,
      timestamp: DateTime.now(),
      lida: false,
      minhaMensagem: true,
      paraMim: false,
      notificar: false,
    );

    _mensagens.add(novaMensagem);
    await _salvarMensagens();
    notifyListeners();

    // Envia para o banco de dados na nuvem (API Django no Render)
    try {
      final resp = await ApiService.enviarMensagemChat(
        pacienteId: pacienteId,
        texto: cleanTexto,
      );
      if (resp != null && resp['id'] != null) {
        final serverId = resp['id'].toString();
        final idx = _mensagens.indexWhere((m) => m.id == tempId);
        if (idx >= 0) {
          _mensagens[idx] = _mensagens[idx].copyWith(
            id: serverId,
            minhaMensagem: true,
          );
          await _salvarMensagens();
          notifyListeners();
        }
      }
    } catch (_) {}
  }
}
