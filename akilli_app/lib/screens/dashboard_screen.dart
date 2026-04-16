import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/device_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tiktokUsage = 0;
  int _instagramUsage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosReais();
  }

  Future<void> _carregarDadosReais() async {
    // Busca dados reais de pacotes comuns de distração
    int tiktok = await DeviceService.getDailyUsageMinutes('com.zhiliaoapp.musically');
    int instagram = await DeviceService.getDailyUsageMinutes('com.instagram.android');
    
    if (mounted) {
      setState(() {
        _tiktokUsage = tiktok;
        _instagramUsage = instagram;
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard",
            style: GoogleFonts.raleway(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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

          // Tempo Poupado Card
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
                  "Tempo Desbloqueado hoje",
                  style: GoogleFonts.raleway(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "2h 15m", // Ainda mock (será calculado com lógica do app no futuro)
                  style: GoogleFonts.raleway(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Seção Apps de Distração (DADOS REAIS NATIVOS)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Apps de Distração",
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _carregarDadosReais,
                      child: const Text('Atualizar'),
                    )
            ],
          ),
          const SizedBox(height: 8),
          _buildAppUsageRow(
            icon: Icons.camera_alt,
            appName: 'Instagram',
            time: _formatarMinutos(_instagramUsage),
            color: Colors.pink,
            isDistraction: true,
          ),
          _buildAppUsageRow(
            icon: Icons.video_library,
            appName: 'TikTok',
            time: _formatarMinutos(_tiktokUsage),
            color: Colors.black,
            isDistraction: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageRow({required IconData icon, required String appName, required String time, required Color color, bool isDistraction = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(appName, style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        trailing: Text(
          time,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: isDistraction ? Colors.red[600] : Colors.green[600],
            fontSize: 16
          ),
        ),
      ),
    );
  }
}
