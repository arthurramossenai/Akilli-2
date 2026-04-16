import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
            "Veja quanto tempo você economizou fora de distrações e o tempo total investido nas suas tarefas focadas.",
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
                  "2h 15m", // Mock
                  style: GoogleFonts.raleway(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Seção Apps de Produtividade
          Text(
            "Apps Produtivos",
            style: GoogleFonts.raleway(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildAppUsageRow(
            icon: Icons.code,
            appName: 'VS Code',
            time: '1h 45m',
            color: Colors.blue,
          ),
          _buildAppUsageRow(
            icon: Icons.book,
            appName: 'Notion',
            time: '30m',
            color: Colors.black87,
          ),

          const SizedBox(height: 24),

          // Seção Apps de Distração
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
              TextButton(
                onPressed: () {
                  // TODO: Abrir tela de gerenciamento de distrações
                },
                child: const Text('Editar Lista'),
              )
            ],
          ),
          const SizedBox(height: 8),
          _buildAppUsageRow(
            icon: Icons.camera_alt,
            appName: 'Instagram',
            time: '12m',
            color: Colors.pink,
            isDistraction: true,
          ),
          _buildAppUsageRow(
            icon: Icons.video_library,
            appName: 'TikTok',
            time: '4m',
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
