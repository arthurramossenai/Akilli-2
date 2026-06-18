import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

import 'tarefas_screen.dart';
import 'dashboard_screen.dart';
import 'foco_screen.dart';
import 'ranking_screen.dart';
import 'editar_perfil_screen.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import '../services/app_blocker_channel.dart';
import '../services/points_manager.dart';
import '../services/notification_service.dart';
import '../models/tarefa.dart';
import 'auth_screen.dart';
import '../widgets/username_setup_dialog.dart';
import 'pesquisa_usuarios_screen.dart';
import 'notificacoes_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({Key? key}) : super(key: key);

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _currentIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  Timer? _syncTimer;
  Timer? _notifTimer;
  int _notificacoesPendentes = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pedirPermissoes();
    _checkMotivation();
    
    // Tenta sincronizar os pontos baseados no tempo de tela poupado
    PointsManager.syncDailySavedTimePoints(_supabaseService);
    
    _checkMissingUsername();

    // Inicia verificação periódica de tarefas para bloqueio (a cada 15 segundos)
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => _sincronizarBloqueio());
    // Executa imediatamente na primeira vez
    _sincronizarBloqueio();

    // Carrega notificações pendentes e atualiza periodicamente
    _carregarNotificacoes();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => _carregarNotificacoes());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarNotificacoes() async {
    final count = await _supabaseService.contarNotificacoesPendentes();
    if (mounted) {
      setState(() {
        _notificacoesPendentes = count;
      });
    }
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

  Future<void> _checkMissingUsername() async {
    final user = _supabaseService.usuarioLogado;
    if (user == null) return;
    
    // Verifica se o username tem espaço, acento ou letras maiúsculas (padrão antigo que vinha do nome)
    // ou se está vazio (login social futuro)
    bool hasInvalidFormat = user.usuario.isEmpty || user.usuario != user.usuario.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\._]'), '');
    
    if (hasInvalidFormat) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false, // Impede de fechar clicando fora ou no botão voltar
          child: UsernameSetupDialog(supabaseService: _supabaseService),
        ),
      );
      setState(() {}); // Atualiza UI (nome no menu)
    }
  }

  Future<void> _pedirPermissoes() async {
    // Permissão nativa Android usage stats
    await DeviceService.checkAndRequestUsagePermission();

    // Permissão de Notificações (Android 13+)
    await NotificationService().requestPermission();

    // Permissão de Acesso ao Uso + Exibir sobre outros apps
    bool allPermissions = await AppBlockerChannel.isAccessibilityEnabled();
    if (!allPermissions) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Permissões Necessárias'),
            content: const Text(
              'O Akilli precisa de duas permissões para o Modo Foco funcionar:\n\n'
              '1. "Acesso ao Uso" — para detectar qual app está aberto\n'
              '2. "Exibir sobre outros apps" — para mostrar a tela de bloqueio\n\n'
              'Clique abaixo para ativar a permissão que falta.',
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
    // Se o modo foco manual estiver rodando, não interfere
    if (AppBlockerChannel.isManualFocusActive) return;

    try {
      final tarefas = await _supabaseService.getTarefas();
      Tarefa? tarefaAtiva;
      final agora = DateTime.now();
      
      for (var t in tarefas) {
        if (t.andamento == 'Concluída' || t.andamento == 'Cancelada') continue;
        if (!t.modoFoco) continue;
        
        DateTime? inicio = _parseDataTarefa(t.dataInicio, defaultHora: 0, defaultMin: 0);
        DateTime? fim = _parseDataTarefa(t.dataFim, defaultHora: 23, defaultMin: 59);
        
        print('⏱️ SYNC "${t.titulo}": status=${t.andamento} | inicio=$inicio fim=$fim | agora=$agora');
        
        // REGRA 1: Se o fim já passou e a tarefa não está concluída, auto-concluir
        if (fim != null && agora.isAfter(fim)) {
          if (t.idTarefa != null && (t.andamento == 'Em Andamento' || t.andamento == 'Pendente')) {
            print('   -> ⏰ Tarefa "${t.titulo}" expirou, auto-concluindo...');
            await _supabaseService.atualizarAndamento(t.idTarefa!, 'Concluída');
          }
          continue; // Não ativa bloqueio para tarefa expirada
        }
        
        // REGRA 2: Se o início chegou mas ainda está Pendente, mudar para Em Andamento
        if (inicio != null && !agora.isBefore(inicio) && t.andamento == 'Pendente' && t.idTarefa != null) {
          print('   -> 🔄 Tarefa "${t.titulo}" iniciou, mudando para Em Andamento...');
          await _supabaseService.atualizarAndamento(t.idTarefa!, 'Em Andamento');
        }
        
        // REGRA 3: Bloqueia APENAS se estamos dentro do horário da tarefa
        bool dentroDoHorario = false;
        if (inicio != null && !agora.isBefore(inicio)) {
          dentroDoHorario = (fim == null) || !agora.isAfter(fim);
        }
        
        if (dentroDoHorario && t.appsBloqueados != null && t.appsBloqueados!.isNotEmpty) {
          tarefaAtiva = t;
          print('   -> ✅ Tarefa ativa para bloqueio!');
          break;
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
          print('🔒 BLOQUEIO ATIVO: "${tarefaAtiva.titulo}" | apps: $packagesToBlock');
          await AppBlockerChannel.setBlockedApps(packagesToBlock, tarefaAtiva.titulo);
          return;
        }
      }

      // Se não encontrou tarefa ativa, limpa o bloqueio
      await AppBlockerChannel.clearBlockedApps();

    } catch (e) {
      print('Erro ao sincronizar bloqueio: $e');
    }
  }

  /// Parse robusto de datas do Supabase (suporta "2026-04-29 15:00", "2026-04-29T15:00:00+00:00", etc)
  DateTime? _parseDataTarefa(String? dtStr, {int defaultHora = 0, int defaultMin = 0}) {
    if (dtStr == null || dtStr.isEmpty) return null;
    try {
      return DateTime.parse(dtStr).toLocal();
    } catch (_) {}
    try {
      return DateTime.parse(dtStr.replaceFirst(' ', 'T')).toLocal();
    } catch (_) {}
    try {
      final partes = dtStr.trim().split(RegExp(r'[ T]'));
      final dataParts = partes[0].split('-');
      int ano = int.parse(dataParts[0]);
      int mes = int.parse(dataParts[1]);
      int dia = int.parse(dataParts[2]);
      int hora = defaultHora, min = defaultMin;
      if (partes.length > 1) {
        final horaParts = partes[1].split(':');
        hora = int.parse(horaParts[0]);
        min = int.parse(horaParts[1]);
      }
      return DateTime(ano, mes, dia, hora, min);
    } catch (_) {}
    return null;
  }


  final List<Widget> _screens = [
    const TarefasScreen(isTab: true),
    const FocoScreen(),
    const DashboardScreen(),
    const RankingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = _supabaseService.usuarioLogado;
    final String nomeUsuario = user?.nome ?? 'Usuário';
    final String emailUsuario = user?.email ?? '';
    final String inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : '?';

    return Scaffold(
      key: _scaffoldKey,
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
          // Ícone de Notificações com badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                tooltip: 'Notificações',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificacoesScreen()),
                  );
                  // Atualiza contagem ao voltar
                  _carregarNotificacoes();
                },
              ),
              if (_notificacoesPendentes > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _notificacoesPendentes > 9 ? '9+' : '$_notificacoesPendentes',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.person_search, size: 26),
              tooltip: 'Encontrar Pessoas',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PesquisaUsuariosScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.menu, size: 26),
            tooltip: 'Menu',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ==================== DRAWER LATERAL ====================
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: SafeArea(
          child: Column(
            children: [
              // Header do drawer: foto, nome, nível
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.kombuGreen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.tan,
                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              inicialNome,
                              style: GoogleFonts.raleway(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kombuGreen,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Nome
                    Text(
                      nomeUsuario,
                      style: GoogleFonts.raleway(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Email
                    Text(
                      emailUsuario,
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nível
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tan.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.tan.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppColors.tan, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Nível',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Opções do menu
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.kombuGreen),
                title: Text(
                  'Editar Informações',
                  style: GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                onTap: () async {
                  Navigator.pop(context); // fecha o drawer
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                  );
                  if (result == true) {
                    setState(() {}); // atualiza o drawer com os novos dados
                  }
                },
              ),

              const Divider(indent: 16, endIndent: 16),

              // Espaçador para empurrar o logout para baixo
              const Spacer(),

              // Logout
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Sair',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.red,
                  ),
                ),
                onTap: () async {
                  await AppBlockerChannel.clearBlockedApps();
                  _supabaseService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.kombuGreen,
        unselectedItemColor: AppColors.mossGreen,
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
