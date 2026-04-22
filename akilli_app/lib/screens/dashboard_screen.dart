import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/device_service.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AppUsageData> _topApps = [];
  int _totalScreenTime = 0;
  bool _isLoading = true;
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosReais();
  }

  Future<void> _carregarDadosReais() async {
    setState(() => _isLoading = true);
    
    bool hasPermission = await DeviceService.checkAndRequestUsagePermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _isLoading = false;
        });
      }
      return;
    }

    int total = await DeviceService.getTotalScreenTimeToday();
    List<AppUsageData> topApps = await DeviceService.getTopDistractionApps();

    if (mounted) {
      setState(() {
        _totalScreenTime = total;
        // Pega só os 5 mais usados pra não poluir
        _topApps = topApps.take(5).toList();
        _permissionGranted = true;
        _isLoading = false;
      });
    }
  }

  String _formatarMinutos(int minutos) {
    if (minutos < 60) {
      return '${minutos}m';
    }
    int h = minutos ~/ 60;
    int m = minutos % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dashboard",
                style: GoogleFonts.raleway(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (!_isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _carregarDadosReais,
                  tooltip: 'Atualizar dados',
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Veja o tempo detectado pelo Android. Estes tempos refletem o uso real de hoje direto das configurações do aparelho.",
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          if (!_permissionGranted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "Permissão de tempo de tela necessária para visualizar os gráficos.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _carregarDadosReais,
                    child: const Text('Tentar Novamente'),
                  )
                ],
              ),
            )
          else ...[
            // Tempo de Tela Total Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Tempo total de tela hoje",
                    style: GoogleFonts.raleway(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatarMinutos(_totalScreenTime),
                    style: GoogleFonts.raleway(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Seção Apps Mais Usados
            Text(
              "Apps Mais Usados Hoje",
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_topApps.isEmpty)
              const Center(child: Text('Nenhum uso registrado hoje.'))
            else
              ..._topApps.map((app) => _buildAppUsageRow(app)).toList(),
          ]
        ],
      ),
    );
  }

  Widget _buildAppUsageRow(AppUsageData app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: app.icon != null
            ? Image.memory(app.icon!, width: 40, height: 40)
            : const CircleAvatar(child: Icon(Icons.android)),
        title: Text(app.name, style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        subtitle: Text(app.packageName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Text(
          _formatarMinutos(app.minutesUsed),
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
            fontSize: 16
          ),
        ),
      ),
    );
  }
}
