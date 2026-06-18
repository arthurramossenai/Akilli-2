import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/app_info.dart';
import '../services/device_service.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _permissionGranted = true;

  Map<String, String> _appsFoco = {};
  Map<String, String> _appsDistracao = {};

  int _minutosFocoHoje = 0;
  int _minutosDistracaoHoje = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
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

    final prefs = await SharedPreferences.getInstance();
    
    final jsonFoco = prefs.getString('foco_global_apps_produtividade');
    if (jsonFoco != null) {
      try {
        _appsFoco = Map<String, String>.from(jsonDecode(jsonFoco));
      } catch (_) {}
    }

    final jsonDistracao = prefs.getString('foco_global_apps');
    if (jsonDistracao != null) {
      try {
        _appsDistracao = Map<String, String>.from(jsonDecode(jsonDistracao));
      } catch (_) {}
    }

    // Calcula tempo de uso
    int minFoco = 0;
    int minDist = 0;
    
    // getTopDistractionApps pega todo o uso. A gente filtra os configurados.
    final allUsage = await DeviceService.getTopDistractionApps();
    
    for (var u in allUsage) {
      if (_appsFoco.containsKey(u.packageName)) {
        minFoco += u.minutesUsed;
      } else if (_appsDistracao.containsKey(u.packageName)) {
        minDist += u.minutesUsed;
      }
    }

    if (mounted) {
      setState(() {
        _minutosFocoHoje = minFoco;
        _minutosDistracaoHoje = minDist;
        _permissionGranted = true;
        _isLoading = false;
      });
    }
  }

  String _formatarMinutos(int minutos) {
    if (minutos < 60) return '${minutos}m';
    int h = minutos ~/ 60;
    int m = minutos % 60;
    return '${h}h ${m}m';
  }

  Future<void> _configurarApps(bool isFoco) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<AppInfo> appsInstalados = [];
    try {
      appsInstalados = await DeviceService.getInstalledApps();
    } catch (_) {}

    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    Map<String, String> selecionados = Map.from(isFoco ? _appsFoco : _appsDistracao);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isFoco ? Icons.star : Icons.block, color: isFoco ? Colors.green : Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(child: Text(isFoco ? 'Apps de Foco' : 'Apps de Distração', style: const TextStyle(fontSize: 16))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: appsInstalados.isEmpty
                  ? const Center(child: Text('Nenhum app encontrado.'))
                  : ListView.builder(
                      itemCount: appsInstalados.length,
                      itemBuilder: (context, index) {
                        final app = appsInstalados[index];
                        bool marcado = selecionados.containsKey(app.packageName);
                        return CheckboxListTile(
                          value: marcado,
                          activeColor: isFoco ? Colors.green : Colors.grey[700],
                          title: Text(app.name, style: const TextStyle(fontSize: 14)),
                          secondary: app.icon != null
                              ? Image.memory(app.icon!, width: 32, height: 32)
                              : const Icon(Icons.android),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selecionados[app.packageName] = app.name;
                              } else {
                                selecionados.remove(app.packageName);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  if (isFoco) {
                    await prefs.setString('foco_global_apps_produtividade', jsonEncode(selecionados));
                  } else {
                    await prefs.setString('foco_global_apps', jsonEncode(selecionados));
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  _carregarDados();
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text('Salvar (${selecionados.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: isFoco ? Colors.green : Colors.grey[700]),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maximo = (_minutosFocoHoje + _minutosDistracaoHoje).toDouble();
    final double pctFoco = maximo > 0 ? _minutosFocoHoje / maximo : 0;
    final double pctDist = maximo > 0 ? _minutosDistracaoHoje / maximo : 0;

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
                style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (!_isLoading)
                IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDados)
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Configure seus apps de foco e distração para ver o gráfico de produtividade do dia.",
            style: GoogleFonts.raleway(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 32),

          if (!_permissionGranted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text("Permissão de tempo de tela necessária.", textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _carregarDados, child: const Text('Tentar Novamente')),
                ],
              ),
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Gráfico
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Produtividade de Hoje", style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  if (maximo == 0)
                    const Center(child: Text("Sem uso registrado hoje nos apps configurados.", style: TextStyle(color: Colors.grey)))
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            if (pctFoco > 0)
                              Expanded(flex: (pctFoco * 100).toInt(), child: Container(height: 24, decoration: BoxDecoration(color: AppColors.kombuGreen, borderRadius: BorderRadius.horizontal(left: const Radius.circular(12), right: Radius.circular(pctDist == 0 ? 12 : 0))))),
                            if (pctDist > 0)
                              Expanded(flex: (pctDist * 100).toInt(), child: Container(height: 24, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.horizontal(right: const Radius.circular(12), left: Radius.circular(pctFoco == 0 ? 12 : 0))))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.circle, color: AppColors.kombuGreen, size: 12),
                                    const SizedBox(width: 4),
                                    Text("Foco", style: GoogleFonts.raleway(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Text(_formatarMinutos(_minutosFocoHoje), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text("Distração", style: GoogleFonts.raleway(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.circle, color: Colors.grey[400], size: 12),
                                  ],
                                ),
                                Text(_formatarMinutos(_minutosDistracaoHoje), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botões de Configuração
            Text("Configurações", style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.star, color: Colors.green)),
                title: Text("Apps de Foco", style: GoogleFonts.raleway(fontWeight: FontWeight.w600)),
                subtitle: Text("${_appsFoco.length} apps selecionados", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _configurarApps(true),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.block, color: Colors.grey[700])),
                title: Text("Apps de Distração", style: GoogleFonts.raleway(fontWeight: FontWeight.w600)),
                subtitle: Text("${_appsDistracao.length} apps selecionados", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _configurarApps(false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
