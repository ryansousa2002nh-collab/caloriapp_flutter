import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometriaService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyBiometriaAtiva = 'config_biometria';

  /// Verifica se o dispositivo possui hardware biométrico configurado e suportado
  static Future<bool> podeUsarBiometria() async {
    try {
      final bool podeChecar = await _auth.canCheckBiometrics;
      final bool suportado = await _auth.isDeviceSupported();
      return podeChecar && suportado;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o usuário optou por ativar a biometria nas configurações
  static Future<bool> isBiometriaAtiva() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometriaAtiva) ?? false;
  }

  /// Ativa ou desativa a preferência de biometria
  static Future<void> setBiometriaAtiva(bool ativa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometriaAtiva, ativa);
  }

  /// Executa o diálogo nativo de autenticação biométrica (Impressão Digital ou Face ID)
  static Future<bool> autenticar({
    String motivo = 'Confirme sua biometria para acessar o Nutri+',
  }) async {
    try {
      final disponivel = await podeUsarBiometria();
      if (!disponivel) {
        // Se a plataforma não suportar hardware biométrico (ex: emulador sem sensor),
        // retorna falso para prosseguir com login por senha
        return false;
      }

      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
