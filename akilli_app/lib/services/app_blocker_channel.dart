import 'package:flutter/services.dart';

class AppBlockerChannel {
  static const _channel = MethodChannel('com.akilli/app_blocker');

  /// Envia a lista de apps bloqueados para o serviço nativo Android
  static Future<bool> setBlockedApps(List<String> packageNames, String taskName) async {
    try {
      final result = await _channel.invokeMethod('setBlockedApps', {
        'packages': packageNames,
        'taskName': taskName,
      });
      return result == true;
    } catch (e) {
      print('Erro ao definir apps bloqueados: $e');
      return false;
    }
  }

  /// Limpa a lista de apps bloqueados (desativa o bloqueio)
  static Future<bool> clearBlockedApps() async {
    try {
      final result = await _channel.invokeMethod('clearBlockedApps');
      return result == true;
    } catch (e) {
      print('Erro ao limpar apps bloqueados: $e');
      return false;
    }
  }

  /// Verifica se o serviço de acessibilidade do Akilli está habilitado
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result == true;
    } catch (e) {
      print('Erro ao verificar acessibilidade: $e');
      return false;
    }
  }

  /// Abre as configurações de acessibilidade do Android
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Erro ao abrir configurações: $e');
    }
  }

  /// Checa se a intent atual contém a flag de motivação (vindo da tela de bloqueio)
  static Future<bool> checkMotivationIntent() async {
    try {
      final result = await _channel.invokeMethod('checkMotivationIntent');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
