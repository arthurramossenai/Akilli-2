import 'package:usage_stats/usage_stats.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class DeviceService {
  /// Solicita e checa se a permissão de Usage Stats (Tempo de Tela) foi concedida
  static Future<bool> checkAndRequestUsagePermission() async {
    bool? isGranted = await UsageStats.checkUsagePermission();
    if (isGranted == null || !isGranted) {
      await UsageStats.grantUsagePermission();
      isGranted = await UsageStats.checkUsagePermission();
    }
    return isGranted ?? false;
  }

  /// Retorna a lista de todos os aplicativos instalados no dispositivo (com seus ícones e nomes reais)
  static Future<List<AppInfo>> getInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
    // Ordena do A-Z
    apps.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  /// Retorna o tempo de uso de hoje de um determinado Package Name (em minutos)
  static Future<int> getDailyUsageMinutes(String packageName) async {
    // Definimos o período: desde as 00h00 de hoje até agora
    DateTime startDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime endDate = DateTime.now();

    List<UsageInfo> usageStats =
        await UsageStats.queryUsageStats(startDate, endDate);

    // Procura o app na lista de uso
    for (var info in usageStats) {
      if (info.packageName == packageName) {
        int totalTimeInForegroundMillis =
            int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        return (totalTimeInForegroundMillis / 1000 / 60)
            .round(); // Converte ms para minutos
      }
    }
    return 0; // Se não encontrou, usou 0 minutos
  }
}
