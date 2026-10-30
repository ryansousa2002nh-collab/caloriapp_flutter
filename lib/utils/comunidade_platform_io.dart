import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _androidChannel = MethodChannel(
  'com.example.caloriapp_flutter/comunidade_platform',
);

Future<String?> selecionarImagemDoDispositivoImpl() async {
  try {
    if (Platform.isAndroid) {
      final dataUrl = await _androidChannel.invokeMethod<String>('pickImage');
      if (dataUrl != null && dataUrl.isNotEmpty) {
        return dataUrl;
      }
      return null;
    } else if (Platform.isWindows) {
      const psScript = '''
Add-Type -AssemblyName System.Windows.Forms
\$dlg = New-Object System.Windows.Forms.OpenFileDialog
\$dlg.Title = "Selecionar foto do prato"
\$dlg.Filter = "Imagens (*.jpg;*.jpeg;*.png;*.webp;*.gif)|*.jpg;*.jpeg;*.png;*.webp;*.gif|Todos os arquivos (*.*)|*.*"
if (\$dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dlg.FileName
}
''';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        psScript,
      ]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final ext = path.split('.').last.toLowerCase();
          final mime = ext == 'png'
              ? 'image/png'
              : ext == 'webp'
                  ? 'image/webp'
                  : ext == 'gif'
                      ? 'image/gif'
                      : 'image/jpeg';
          return 'data:$mime;base64,${base64Encode(bytes)}';
        }
      }
    } else if (Platform.isLinux) {
      final result = await Process.run('zenity', [
        '--file-selection',
        '--title=Selecionar foto do prato',
        '--file-filter=Imagens | *.jpg *.jpeg *.png *.webp',
      ]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }
    } else if (Platform.isMacOS) {
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose file of type {"public.image"} with prompt "Selecione a foto do prato")',
      ]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }
    }
  } catch (_) {}
  return null;
}

Future<bool> abrirLinkExternoImpl(String url) async {
  try {
    if (Platform.isAndroid) {
      final opened = await _androidChannel.invokeMethod<bool>(
        'openUrl',
        {'url': url},
      );
      return opened == true;
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (_) {}
  return false;
}

