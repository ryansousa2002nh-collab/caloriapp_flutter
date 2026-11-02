import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dieta_model.dart';

class ProximaRefeicaoInfo {
  final RefeicaoModel refeicao;
  final String horario;
  final Duration tempoRestante;
  final bool ehAmanha;

  ProximaRefeicaoInfo({
    required this.refeicao,
    required this.horario,
    required this.tempoRestante,
    this.ehAmanha = false,
  });

  String get descricaoTempo {
    if (tempoRestante.inMinutes <= 0) {
      return 'Agora!';
    }
    final horas = tempoRestante.inHours;
    final minutos = tempoRestante.inMinutes % 60;
    if (horas > 0) {
      return 'em ${horas}h ${minutos > 0 ? '${minutos}min' : ''}'.trim();
    }
    return 'em ${minutos}min';
  }
}

class LembretesService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;
  static const String _keyNotificacoesDieta = 'config_notif_dieta';

  /// Inicializa o plugin de notificações locais para Android e iOS
  static Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);

      // Solicita permissão no Android 13+ e cria o canal em alta prioridade
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            'nutri_chat_notificacoes',
            'Mensagens da Nutri+',
            description: 'Notificações em tempo real do chat entre Nutricionista e Paciente',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _inicializado = true;
    } catch (_) {}
  }

  /// Verifica se os lembretes de dieta estão habilitados nas configurações
  static Future<bool> isLembretesAtivos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificacoesDieta) ?? true;
  }

  /// Ativa ou desativa os lembretes
  static Future<void> setLembretesAtivos(bool ativo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificacoesDieta, ativo);
  }

  /// Calcula com precisão qual é a próxima refeição do dia com base nos horários que a Nutri fixou
  static ProximaRefeicaoInfo? calcularProximaRefeicao(List<RefeicaoModel> refeicoes) {
    if (refeicoes.isEmpty) return null;

    final agora = DateTime.now();
    final minutosAtuais = agora.hour * 60 + agora.minute;

    final refeicoesComHorario = <MapEntry<int, RefeicaoModel>>[];

    for (final ref in refeicoes) {
      final horStr = (ref.horarioSugerido ?? '').trim();
      if (horStr.isEmpty) continue;

      final partes = horStr.split(':');
      if (partes.length >= 2) {
        final h = int.tryParse(partes[0]) ?? 0;
        final m = int.tryParse(partes[1]) ?? 0;
        final minutosDoDia = h * 60 + m;
        refeicoesComHorario.add(MapEntry(minutosDoDia, ref));
      }
    }

    if (refeicoesComHorario.isEmpty) return null;

    // Ordena as refeições pelo horário do dia
    refeicoesComHorario.sort((a, b) => a.key.compareTo(b.key));

    // 1. Procura a próxima refeição ainda hoje
    for (final entry in refeicoesComHorario) {
      if (entry.key > minutosAtuais) {
        final diferencaMinutos = entry.key - minutosAtuais;
        return ProximaRefeicaoInfo(
          refeicao: entry.value,
          horario: entry.value.horarioSugerido ?? '',
          tempoRestante: Duration(minutes: diferencaMinutos),
          ehAmanha: false,
        );
      }
    }

    // 2. Se todas de hoje já passaram, a próxima é a primeira de amanhã
    final primeiraAmanha = refeicoesComHorario.first;
    final minutosAteMeiaNoite = (24 * 60) - minutosAtuais;
    final totalMinutos = minutosAteMeiaNoite + primeiraAmanha.key;

    return ProximaRefeicaoInfo(
      refeicao: primeiraAmanha.value,
      horario: primeiraAmanha.value.horarioSugerido ?? '',
      tempoRestante: Duration(minutes: totalMinutos),
      ehAmanha: true,
    );
  }

  /// Dispara uma notificação imediata no celular para teste do paciente ou nutricionista
  static Future<void> dispararNotificacaoImediata({
    required String titulo,
    required String corpo,
  }) async {
    await inicializar();

    const androidDetails = AndroidNotificationDetails(
      'nutri_lembretes_refeicoes',
      'Lembretes de Refeições Nutri+',
      channelDescription: 'Avisos nos horários prescritos pela nutricionista',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: 1001,
        title: titulo,
        body: corpo,
        notificationDetails: notificationDetails,
      );
    } catch (_) {}
  }

  /// Dispara notificação nativa imediata de nova mensagem no chat (funciona com o app aberto ou em segundo plano)
  static Future<void> dispararNotificacaoChat({
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
    await inicializar();

    const androidDetails = AndroidNotificationDetails(
      'nutri_chat_notificacoes',
      'Mensagens da Nutri+',
      channelDescription: 'Notificações em tempo real do chat entre Nutricionista e Paciente',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Gera ID único para não sobrescrever notificações anteriores
      final notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _notificationsPlugin.show(
        id: notifId,
        title: titulo,
        body: corpo,
        notificationDetails: notificationDetails,
        payload: payload ?? 'chat',
      );
    } catch (_) {}
  }

  /// Agenda ou atualiza os lembretes de refeição com base no plano estabelecido pela nutri
  static Future<void> agendarLembretesDieta(List<RefeicaoModel> refeicoes) async {
    final ativo = await isLembretesAtivos();
    if (!ativo || refeicoes.isEmpty) return;

    await inicializar();

    // Notificação inteligente com a próxima refeição prescrita
    final proxima = calcularProximaRefeicao(refeicoes);
    if (proxima != null) {
      final descTempo = proxima.descricaoTempo;
      await dispararNotificacaoImediata(
        titulo: '🥗 Próxima Refeição: ${proxima.refeicao.tipo}',
        corpo: 'Horário estabelecido pela Nutri: ${proxima.horario} ($descTempo). Não deixe de registrar seu consumo!',
      );
    }
  }
}
