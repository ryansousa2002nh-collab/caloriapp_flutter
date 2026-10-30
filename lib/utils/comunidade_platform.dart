import 'comunidade_platform_stub.dart'
    if (dart.library.io) 'comunidade_platform_io.dart'
    if (dart.library.js_interop) 'comunidade_platform_web.dart';

class ComunidadePlatform {
  /// Abre o seletor de arquivos do dispositivo (Web ou Desktop) e retorna
  /// a imagem escolhida codificada em Data URL (`data:image/...;base64,...`).
  static Future<String?> selecionarImagemDoDispositivo() {
    return selecionarImagemDoDispositivoImpl();
  }

  /// Abre o link externo (ex: Instagram) no navegador padrão ou nova aba.
  static Future<bool> abrirLinkExterno(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value(false);
    final formatted = (clean.startsWith('http://') || clean.startsWith('https://'))
        ? clean
        : 'https://$clean';
    return abrirLinkExternoImpl(formatted);
  }
}

