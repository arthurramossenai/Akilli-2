import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/app_info.dart';
import '../models/sessao_foco.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import '../services/app_blocker_channel.dart';

class FocoScreen extends StatefulWidget {
  const FocoScreen({Key? key}) : super(key: key);

  @override
  State<FocoScreen> createState() => _FocoScreenState();
}

class _FocoScreenState extends State<FocoScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // Estado do temporizador
  int _minutosEscolhidos = 25; // Padrão Pomodoro
  int _segundosRestantes = 25 * 60;
  bool _emAndamento = false;
  bool _pausado = false;
  Timer? _timer;
  DateTime? _inicioSessao;

  // Opções pré-definidas de tempo
  final List<int> _opcoesMinutos = [10, 15, 20, 25, 30, 45, 60, 90];

  // Apps de Distração para bloqueio (Global Foco)
  Map<String, String> _appsBloqueados = {};

  static const List<String> _appsPopularesPkg = [
    'com.instagram.android',
    'com.zhiliaoapp.musically',
    'com.twitter.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.whatsapp',
    'com.google.android.youtube',
    'com.reddit.frontpage',
    'com.discord',
    'com.spotify.music',
    'com.netflix.mediaclient',
    'tv.twitch.android.app',
  ];

  @override
  void initState() {
    super.initState();
    _carregarAppsGlobais();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarAppsGlobais() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonApps = prefs.getString('foco_global_apps');
    if (jsonApps != null) {
      try {
        final decoded = jsonDecode(jsonApps) as Map;
        setState(() {
          _appsBloqueados = Map<String, String>.from(decoded);
        });
      } catch (_) {}
    }
  }

  Future<void> _salvarAppsGlobais(Map<String, String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foco_global_apps', jsonEncode(apps));
  }

  Future<void> _abrirSeletorApps() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<AppInfo> appsInstalados = [];
    try {
      appsInstalados = await DeviceService.getInstalledApps();
    } catch (e) {
      print('Erro ao carregar apps: $e');
    }

    if (mounted) Navigator.pop(context); // Fecha loading
    if (!mounted) return;

    List<AppInfo> populares = [];
    List<AppInfo> outros = [];

    for (var app in appsInstalados) {
      if (_appsPopularesPkg.contains(app.packageName)) {
        populares.add(app);
      } else {
        outros.add(app);
      }
    }

    Map<String, String> selecionados = Map.from(_appsBloqueados);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildAppTile(AppInfo app) {
            bool marcado = selecionados.containsKey(app.packageName);
            return CheckboxListTile(
              value: marcado,
              activeColor: Colors.green,
              secondary: app.icon != null
                  ? Image.memory(app.icon!, width: 36, height: 36)
                  : const Icon(Icons.android, size: 36),
              title: Text(app.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onChanged: (bool? val) {
                setDialogState(() {
                  if (val == true) {
                    selecionados[app.packageName] = app.name;
                  } else {
                    selecionados.remove(app.packageName);
                  }
                });
              },
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(child: Text('Apps de Distração')),
                if (selecionados.isNotEmpty)
                  Chip(
                    label: Text('${selecionados.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: appsInstalados.isEmpty
                  ? const Center(child: Text('Nenhum app encontrado.'))
                  : ListView(
                      children: [
                        if (populares.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('🔥 Populares', style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[700])),
                          ),
                          ...populares.map(buildAppTile),
                          const Divider(thickness: 2),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('📱 Todos os Apps', style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        ),
                        ...outros.map(buildAppTile),
                      ],
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _appsBloqueados = selecionados);
                  _salvarAppsGlobais(selecionados);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          );
        },
      ),
    );
  }

  void _iniciarTimer() async {
    // Inicia o bloqueio real dos apps
    if (_appsBloqueados.isNotEmpty) {
      await AppBlockerChannel.setBlockedApps(_appsBloqueados.keys.toList(), "Modo Foco Manual");
    }

    setState(() {
      _segundosRestantes = _minutosEscolhidos * 60;
      _emAndamento = true;
      _pausado = false;
      _inicioSessao = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        _timer?.cancel();
        _finalizarSessao(sucesso: true);
      }
    });
  }

  void _pausarTimer() {
    _timer?.cancel();
    setState(() {
      _pausado = true;
    });
  }

  void _retomarTimer() {
    setState(() {
      _pausado = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        _timer?.cancel();
        _finalizarSessao(sucesso: true);
      }
    });
  }

  void _desistirTimer() {
    _timer?.cancel();
    _finalizarSessao(sucesso: false);
  }

  Future<void> _finalizarSessao({required bool sucesso}) async {
    // Desliga o bloqueio nativo ao encerrar
    await AppBlockerChannel.clearBlockedApps();

    DateTime fimSessao = DateTime.now();

    int minutosReais = _inicioSessao != null
        ? fimSessao.difference(_inicioSessao!).inMinutes
        : 0;
    if (minutosReais < 1) minutosReais = 1;

    int pontos = sucesso ? _minutosEscolhidos * 2 : 0;

    SessaoFoco sessao = SessaoFoco(
      inicioSessao: _inicioSessao ?? fimSessao,
      fimSessao: fimSessao,
      duracaoMinutos: sucesso ? _minutosEscolhidos : minutosReais,
      statusSessao: sucesso ? 'Sucesso' : 'Falha',
      pontosGanhos: pontos,
    );

    bool salvo = await _supabaseService.salvarSessaoFoco(sessao);

    setState(() {
      _emAndamento = false;
      _pausado = false;
      _segundosRestantes = _minutosEscolhidos * 60;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                sucesso ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: sucesso ? Colors.amber : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(sucesso ? 'Parabéns!' : 'Sessão encerrada'),
            ],
          ),
          content: Text(
            sucesso
                ? 'Você completou $_minutosEscolhidos minutos focado e ganhou $pontos pontos! 🎉'
                : 'Você desistiu após $minutosReais minutos. Tente novamente!',
            style: GoogleFonts.raleway(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _formatarTempo(int totalSegundos) {
    int minutos = totalSegundos ~/ 60;
    int segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progresso = _emAndamento
        ? 1.0 - (_segundosRestantes / (_minutosEscolhidos * 60))
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Modo Foco",
            style: GoogleFonts.raleway(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _emAndamento
                ? "Mantenha o foco! Não saia do app."
                : "Escolha o tempo e inicie sua sessão de foco.",
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!_emAndamento) ...[
            const SizedBox(height: 24),
            // Aba de configuração rápida de apps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!)
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Apps a bloquear:",
                          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          _appsBloqueados.isEmpty
                              ? "Nenhum app selecionado"
                              : "${_appsBloqueados.length} apps selecionados",
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        )
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _abrirSeletorApps,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!)
                    ),
                    child: const Text('Configurar'),
                  )
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),

          // Timer circular
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progresso,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _emAndamento ? Colors.green[600]! : Colors.grey[400]!,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatarTempo(_segundosRestantes),
                      style: GoogleFonts.raleway(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _emAndamento ? Colors.green[700] : Colors.black87,
                      ),
                    ),
                    if (_emAndamento && _pausado)
                      Text(
                        "PAUSADO",
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Seletor de tempo
          if (!_emAndamento) ...[
            Text(
              "Duração da sessão",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ..._opcoesMinutos.map((minutos) {
                  bool selecionado = _minutosEscolhidos == minutos;
                  return ChoiceChip(
                    label: Text('$minutos min'),
                    selected: selecionado,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _minutosEscolhidos = minutos;
                          _segundosRestantes = minutos * 60;
                        });
                      }
                    },
                    selectedColor: Colors.green[100],
                    labelStyle: TextStyle(
                      color: selecionado ? Colors.green[800] : Colors.black54,
                      fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
                ActionChip(
                  label: const Text('Personalizar'),
                  avatar: const Icon(Icons.edit, size: 16),
                  onPressed: () {
                    final controller = TextEditingController(text: _minutosEscolhidos.toString());
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Tempo personalizado'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                            hintText: 'Ex: 120',
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () {
                              int? m = int.tryParse(controller.text);
                              if (m != null && m > 0) {
                                setState(() {
                                  _minutosEscolhidos = m;
                                  _segundosRestantes = m * 60;
                                });
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 48),

          // Botões de Ação
          if (!_emAndamento)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _iniciarTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Iniciar Foco",
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _desistirTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Desistir",
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _pausado ? _retomarTimer : _pausarTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pausado ? Colors.green[600] : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _pausado ? "Retomar" : "Pausar",
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
