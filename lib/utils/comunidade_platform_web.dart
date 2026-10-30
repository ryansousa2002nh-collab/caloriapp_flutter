import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String?> selecionarImagemDoDispositivoImpl() async {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final result = reader.result;
      final dataUrl = (result as JSString?)?.toDart;
      if (!completer.isCompleted) completer.complete(dataUrl);
    }).toJS;
    reader.onerror = ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS;
    reader.readAsDataURL(file);
  }).toJS;

  input.click();
  return completer.future;
}

Future<bool> abrirLinkExternoImpl(String url) async {
  try {
    web.window.open(url, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}

