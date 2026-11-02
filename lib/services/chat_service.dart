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

  List<MensagemChat> get todasMensagens => List.unmodifiable(_mensagens);

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

  /// Sincroniza as mensagens com a API em nuvem e notifica o dispositivo caso receba mensagem nova
  Future<void> sincronizarComBackend({int? pacienteId}) async {
    try {
      final listJson = await ApiService.getMensagensChat(pacienteId: pacienteId);
      if (listJson.isEmpty) return;

      bool houveMudanca = false;
      for (final item in listJson) {
        final novaMsg = MensagemChat.fromJson(Map<String, dynamic>.from(item as Map));
        final index = _mensagens.indexWhere((m) => m.id == novaMsg.id);
        if (index >= 0) {
          if (_mensagens[index].lida != novaMsg.lida) {
            _mensagens[index] = novaMsg;
            houveMudanca = true;
          }
        } else {
          _mensagens.add(novaMsg);
          houveMudanca = true;

          // Dispara notificação no celular caso seja mensagem recebida
          final titulo = novaMsg.isNutri
              ? '👩‍⚕️ Dra. Juliana Braz (Nutri)'
              : '💬 Nova mensagem de ${novaMsg.pacienteNome}';
          await LembretesService.dispararNotificacaoChat(
            titulo: titulo,
            corpo: novaMsg.texto,
          );
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
      );
      _mensagens.add(msgInicial);
      _salvarMensagens();
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
      unawaited(ApiService.marcarMensagensLidasChat(pacienteId: pacienteId));
    }
  }

  /// Envia uma nova mensagem no chat
  Future<void> enviarMensagem({
    required int pacienteId,
    required String pacienteNome,
    required String remetente, // 'PACIENTE' ou 'NUTRI'
    required String remetenteNome,
    required String texto,
    bool simularRespostaAutomatica = true,
  }) async {
    final cleanTexto = texto.trim();
    if (cleanTexto.isEmpty) return;

    final novaMensagem = MensagemChat(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      pacienteId: pacienteId,
      pacienteNome: pacienteNome,
      remetente: remetente,
      remetenteNome: remetenteNome,
      texto: cleanTexto,
      timestamp: DateTime.now(),
      lida: false,
    );

    _mensagens.add(novaMensagem);
    await _salvarMensagens();
    notifyListeners();

    // 1. Envia para o banco de dados na nuvem (API Django no Render)
    unawaited(ApiService.enviarMensagemChat(
      pacienteId: pacienteId,
      texto: cleanTexto,
    ));

    // 2. Notificação e resposta inteligente para demonstração
    if (remetente == 'PACIENTE') {
      if (simularRespostaAutomatica) {
        Timer(const Duration(milliseconds: 2200), () async {
          final respostaTexto = _gerarRespostaClinicaInteligente(cleanTexto, pacienteNome);
          final msgNutri = MensagemChat(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            pacienteId: pacienteId,
            pacienteNome: pacienteNome,
            remetente: 'NUTRI',
            remetenteNome: 'Dra. Juliana Braz',
            texto: respostaTexto,
            timestamp: DateTime.now(),
            lida: false,
          );

          _mensagens.add(msgNutri);
          await _salvarMensagens();
          notifyListeners();

          // Notifica o celular do paciente com a resposta
          await LembretesService.dispararNotificacaoChat(
            titulo: '👩‍⚕️ Dra. Juliana Braz (Nutri)',
            corpo: respostaTexto,
          );
        });
      }
    } else {
      // Enviado pela Dra. Juliana -> Dispara notificação nativa no celular
      await LembretesService.dispararNotificacaoChat(
        titulo: '👩‍⚕️ Dra. Juliana Braz (Nutri)',
        corpo: cleanTexto,
      );
    }
  }

  /// Gera respostas clínicas inteligentes e personalizadas para a demonstração ao vivo
  String _gerarRespostaClinicaInteligente(String textoPaciente, String nomePaciente) {
    final t = textoPaciente.toLowerCase();

    if (t.contains('água') || t.contains('agua') || t.contains('sede') || t.contains('beber')) {
      return 'Olá $nomePaciente! Lembre-se de beber cerca de 35ml a 40ml de água por quilo de peso ao longo do dia. Evite ingerir grandes volumes durante o almoço e jantar para facilitar sua digestão! 💧';
    }
    if (t.contains('fome') || t.contains('saciedade') || t.contains('apetite')) {
      return 'É comum sentir um pouco de apetite nas primeiras fases do plano. Uma dica valiosa: aumente as porções de folhas verdes e vegetais fibrosos nas refeições principais para elevar a saciedade sem extrapolar as calorias! 🥗';
    }
    if (t.contains('substituir') || t.contains('trocar') || t.contains('substituição') || t.contains('troca')) {
      return 'Pode substituir sim! O segredo é trocar por alimentos do mesmo grupo nutricional: batata doce por mandioca, arroz por quinoa ou frango por peixe/ovos na mesma proporção em gramas/ml recomendada. 🍠';
    }
    if (t.contains('leite') || t.contains('iogurte') || t.contains('queijo')) {
      return 'Para os laticínios da sua dieta, priorize sempre versões desnatadas ou o queijo minas frescal, que possuem menor densidade calórica e excelente teor de cálcio e proteínas! 🥛';
    }
    if (t.contains('horario') || t.contains('horário') || t.contains('refeição') || t.contains('refeicoes')) {
      return 'Tente manter uma janela de 3 a 4 horas entre as refeições conforme prescrevi no seu plano. O mais importante é bater sua meta diária de macros com consistência! ⏰';
    }
    if (t.contains('doce') || t.contains('sobremesa') || t.contains('açúcar') || t.contains('acucar')) {
      return 'Se der vontade de doce, inclua frutas com canela aquecidas (como banana ou maçã) ou um pedacinho de chocolate 70% cacau após o almoço! 🍎🍫';
    }
    if (t.contains('suplemento') || t.contains('whey') || t.contains('creatina')) {
      return 'A suplementação deve ser tomada conforme orientamos na sua prescrição: o Whey pode ser usado no lanche ou pós-treino, e a creatina todos os dias (3g a 5g), inclusive nos dias de descanso! 💪';
    }

    return 'Olá $nomePaciente! Recebi sua mensagem. Já estou acompanhando seu diário alimentar e suas metas no app. Continue firme no plano e me avise como está se sentindo! 🌟';
  }
}
