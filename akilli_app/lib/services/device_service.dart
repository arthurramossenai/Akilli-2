import 'dart:typed_data';
import 'package:usage_stats/usage_stats.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppUsageData {
  final String packageName;
  final String name;
  final Uint8List? icon;
  final int minutesUsed;

  AppUsageData({
    required this.packageName,
    required this.name,
    this.icon,
    required this.minutesUsed,
  });
}

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
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  /// Retorna os apps de distração mais usados hoje
  static Future<List<AppUsageData>> getTopDistractionApps() async {
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime endDate = DateTime.now();

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
    List<AppInfo> installedApps = await getInstalledApps();

    List<AppUsageData> topApps = [];

    for (var info in usageStats) {
      if (info.packageName == null || info.packageName == 'com.example.akilli_app') continue;

      int totalTimeInForegroundMillis = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      int minutes = (totalTimeInForegroundMillis / 1000 / 60).round();

      if (minutes > 0) {
        // Tenta encontrar o app instalado correspondente para pegar o nome e ícone real
        AppInfo? appInfo;
        try {
          appInfo = installedApps.firstWhere((app) => app.packageName == info.packageName);
        } catch (_) {}

        if (appInfo != null) {
          topApps.add(AppUsageData(
            packageName: appInfo.packageName,
            name: appInfo.name,
            icon: appInfo.icon,
            minutesUsed: minutes,
          ));
        }
      }
    }

    // Agrupa por packageName (caso a API retorne múltiplos eventos para o mesmo app)
    Map<String, AppUsageData> grouped = {};
    for (var data in topApps) {
      if (grouped.containsKey(data.packageName)) {
         grouped[data.packageName] = AppUsageData(
           packageName: data.packageName,
           name: data.name,
           icon: data.icon,
           minutesUsed: grouped[data.packageName]!.minutesUsed + data.minutesUsed,
         );
      } else {
        grouped[data.packageName] = data;
      }
    }

    List<AppUsageData> finalApps = grouped.values.toList();
    // Ordena do mais usado pro menos
    finalApps.sort((a, b) => b.minutesUsed.compareTo(a.minutesUsed));

    return finalApps;
  }

  /// Retorna o tempo total de tela de hoje em minutos
  static Future<int> getTotalScreenTimeToday() async {
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime endDate = DateTime.now();

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
    int totalMs = 0;
    
    for (var info in usageStats) {
      totalMs += int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
    }
    
    return (totalMs / 1000 / 60).round();
  }
}
