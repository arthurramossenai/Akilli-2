import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tarefas_screen.dart';
import 'dashboard_screen.dart';
import 'foco_screen.dart';
import 'ranking_screen.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import '../services/app_blocker_channel.dart';
import '../services/points_manager.dart';
import '../models/tarefa.dart';
import 'login_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({Key? key}) : super(key: key);

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _currentIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _pedirPermissoes();
    _checkMotivation();
    
    // Tenta sincronizar os pontos baseados no tempo de tela poupado
    PointsManager.syncDailySavedTimePoints(_supabaseService);
    
    // Inicia verificação periódica de tarefas para bloqueio (a cada 30 segundos)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sincronizarBloqueio());
    // Executa imediatamente na primeira vez
    _sincronizarBloqueio();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMotivation() async {
    bool isMotivation = await AppBlockerChannel.checkMotivationIntent();
    if (isMotivation) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Que orgulho! 🎉'),
          content: const Text(
            'Você escolheu não procrastinar e focar em seus objetivos. Continue assim, o Akilli está aqui pra te ajudar a dominar seu tempo!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vamos lá!'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pedirPermissoes() async {
    // Permissão nativa Android usage stats
    await DeviceService.checkAndRequestUsagePermission();

    // Permissão de Acessibilidade (para o bloqueio real funcionar)
    bool isAccessibilityEnabled = await AppBlockerChannel.isAccessibilityEnabled();
    if (!isAccessibilityEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Permissão Necessária'),
            content: const Text(
              'O Akilli precisa da permissão de Acessibilidade para detectar quando você abre um app de distração e bloquear sua tela durante o Modo Foco.\n\nPor favor, ative-a nas configurações.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBlockerChannel.openAccessibilitySettings();
                },
                child: const Text('Abrir Configurações'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _sincronizarBloqueio() async {
    try {
      final tarefas = await _supabaseService.getTarefas();
      Tarefa? tarefaAtiva;
      
      for (var t in tarefas) {
        if (_isFocoAtivo(t)) {
          if (t.appsBloqueados != null && t.appsBloqueados!.isNotEmpty) {
            tarefaAtiva = t;
            break;
          }
        }
      }

      if (tarefaAtiva != null) {
        List<String> packagesToBlock = [];
        try {
          final decoded = jsonDecode(tarefaAtiva.appsBloqueados!);
          if (decoded is Map) {
            packagesToBlock = decoded.keys.map((e) => e.toString()).toList();
          } else if (decoded is List) {
            packagesToBlock = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}

        if (packagesToBlock.isNotEmpty) {
          await AppBlockerChannel.setBlockedApps(packagesToBlock, tarefaAtiva.titulo);
          return;
        }
      }

      // Se não encontrou tarefa ativa ou a tarefa ativa não tem apps bloqueados, limpa
      await AppBlockerChannel.clearBlockedApps();

    } catch (e) {
      print('Erro ao sincronizar bloqueio: $e');
    }
  }

  bool _isFocoAtivo(Tarefa tarefa) {
    if (!tarefa.modoFoco) return false;
    
    DateTime agora = DateTime.now();
    
    DateTime? inicio;
    DateTime? fim;
    
    if (tarefa.dataInicio != null && tarefa.dataInicio!.isNotEmpty) {
      try {
        final partes = tarefa.dataInicio!.split(' ');
        final dataParts = partes[0].split('-');
        int ano = int.parse(dataParts[0]);
        int mes = int.parse(dataParts[1]);
        int dia = int.parse(dataParts[2]);
        int hora = 0, min = 0;
        if (partes.length > 1) {
          final horaParts = partes[1].split(':');
          hora = int.parse(horaParts[0]);
          min = int.parse(horaParts[1]);
        }
        inicio = DateTime(ano, mes, dia, hora, min);
      } catch (_) {}
    }
    
    if (tarefa.dataFim != null && tarefa.dataFim!.isNotEmpty) {
      try {
        final partes = tarefa.dataFim!.split(' ');
        final dataParts = partes[0].split('-');
        int ano = int.parse(dataParts[0]);
        int mes = int.parse(dataParts[1]);
        int dia = int.parse(dataParts[2]);
        int hora = 23, min = 59;
        if (partes.length > 1) {
          final horaParts = partes[1].split(':');
          hora = int.parse(horaParts[0]);
          min = int.parse(horaParts[1]);
        }
        fim = DateTime(ano, mes, dia, hora, min);
      } catch (_) {}
    }
    
    if (inicio != null && fim != null) {
      return agora.isAfter(inicio) && agora.isBefore(fim);
    }
    if (inicio != null && fim == null) {
      return agora.isAfter(inicio);
    }
    
    return false;
  }

  final List<Widget> _screens = [
    const TarefasScreen(isTab: true),
    const FocoScreen(),
    const DashboardScreen(),
    const RankingScreen(),
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
