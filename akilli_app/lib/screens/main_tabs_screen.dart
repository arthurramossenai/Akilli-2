import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tarefas_screen.dart';
import 'dashboard_screen.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import 'login_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({Key? key}) : super(key: key);

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _currentIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _pedirPermissoes();
  }

  Future<void> _pedirPermissoes() async {
    // Ao abrir o app logado, já pede a permissão do UsageStats
    await DeviceService.checkAndRequestUsagePermission();
  }

  // Vamos substituir os "Containers" vazios pelas telas reais assim que criá-las
  final List<Widget> _screens = [
    const TarefasScreen(isTab: true), // Precisamos avisar o TarefasScreen que ele está em uma aba para tirar a AppBar dele
    const Center(child: Text("Em breve: Modo Foco Global")), // Tela Foco
    const DashboardScreen(), // Tela Apps (Dashboard)
    const Center(child: Text("Em breve: Ranking Premium")), // Tela Ranking
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Akilli",
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () {
                _supabaseService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("Sair"),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Foco',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Ranking',
          ),
        ],
      ),
    );
  }
}
