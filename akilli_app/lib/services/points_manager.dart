import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'device_service.dart';
import 'supabase_service.dart';

class PointsManager {
  static const String _baselineKey = 'baseline_screen_time_avg_minutes';
  static const String _lastSyncDateKey = 'last_points_sync_date';

  /// Calcula a média diária de uso dos últimos X dias (ex: 30) antes da instalação
  /// e salva no SharedPreferences para usar como linha de base.
  static Future<int> getOrCreateBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    int? baseline = prefs.getInt(_baselineKey);

    if (baseline != null) return baseline;

    bool hasPermission = await DeviceService.checkAndRequestUsagePermission();
    if (!hasPermission) return 240; // Fallback: 4 horas se não der permissão

    // Calcula uso dos últimos 30 dias até hoje
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(days: 30));

    try {
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      int totalMs = 0;
      for (var info in usageStats) {
        totalMs += int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      }

      int totalMinutes = (totalMs / 1000 / 60).round();
      int avgDaily = (totalMinutes / 30).round();

      // Se por acaso voltar 0 ou um valor bizarro, definimos um mínimo realista
      if (avgDaily < 60) avgDaily = 120; 

      await prefs.setInt(_baselineKey, avgDaily);
      return avgDaily;
    } catch (e) {
      return 240; // Fallback se der erro na query
    }
  }

  /// Calcula quantos pontos o usuário ganhou "poupando tempo" no dia de ontem
  /// Pontos por tempo poupado = 1 pt por minuto.
  static Future<void> syncDailySavedTimePoints(SupabaseService supabaseService) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    
    final lastSyncStr = prefs.getString(_lastSyncDateKey);
    if (lastSyncStr == todayStr) return; // Já sincronizou hoje (referente a ontem ou dias passados recentes)

    bool hasPermission = await DeviceService.checkAndRequestUsagePermission();
    if (!hasPermission) return;

    int baseline = await getOrCreateBaseline();

    // Ontem
    DateTime yesterdayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 1));
    DateTime yesterdayEnd = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(milliseconds: 1));

    try {
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(yesterdayStart, yesterdayEnd);
      int totalMs = 0;
      for (var info in usageStats) {
        totalMs += int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      }
      
      int yesterdayMinutes = (totalMs / 1000 / 60).round();
      int tempoPoupado = baseline - yesterdayMinutes;

      if (tempoPoupado > 0) {
        // Envia os pontos para o banco! 1 ponto por min poupado no geral
        await supabaseService.adicionarPontos(tempoPoupado);
      }

      // Marca como checado hoje
      await prefs.setString(_lastSyncDateKey, todayStr);
    } catch (e) {
      print('Erro ao sincronizar pontos poupados: $e');
    }
  }
}
