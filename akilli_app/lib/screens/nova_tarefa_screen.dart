import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import 'package:installed_apps/app_info.dart';

class NovaTarefaScreen extends StatefulWidget {
  final Tarefa? tarefaExistente; // Se não-nulo, estamos editando

  const NovaTarefaScreen({Key? key, this.tarefaExistente}) : super(key: key);

  @override
  State<NovaTarefaScreen> createState() => _NovaTarefaScreenState();
}

class _NovaTarefaScreenState extends State<NovaTarefaScreen> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFimController = TextEditingController();

  String _prioridadeSelecionada = 'Média';
  bool _modoFoco = false;
  String? _appProdutividade;
  
  // Armazena {packageName: displayName} dos apps bloqueados
  Map<String, String> _appsBloqueados = {};

  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Package names de apps populares de distração
  static const List<String> _appsPopularesPkg = [
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
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
    if (widget.tarefaExistente != null) {
      _isEditMode = true;
      final t = widget.tarefaExistente!;
      _tituloController.text = t.titulo;
      _descricaoController.text = t.descricao;
      _prioridadeSelecionada = t.prioridade;
      _modoFoco = t.modoFoco;
      _appProdutividade = t.appProdutividade;
      
      // Parse da data e hora (formato: "2025-04-22" ou "2025-04-22 14:30")
      if (t.dataInicio != null && t.dataInicio!.isNotEmpty) {
        final partes = t.dataInicio!.split(' ');
        _dataInicioController.text = partes[0];
        if (partes.length > 1) _horaInicioController.text = partes[1];
      }
      if (t.dataFim != null && t.dataFim!.isNotEmpty) {
        final partes = t.dataFim!.split(' ');
        _dataFimController.text = partes[0];
        if (partes.length > 1) _horaFimController.text = partes[1];
      }
      
      // Parse dos apps bloqueados (JSON com {pkg: name})
      if (t.appsBloqueados != null && t.appsBloqueados!.isNotEmpty) {
        try {
          final decoded = jsonDecode(t.appsBloqueados!);
          if (decoded is Map) {
            _appsBloqueados = Map<String, String>.from(decoded);
          } else if (decoded is List) {
            // Compatibilidade com formato antigo (lista de strings)
            for (var pkg in decoded) {
              _appsBloqueados[pkg.toString()] = pkg.toString().split('.').last;
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (data != null) {
      controller.text = '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selecionarHora(TextEditingController controller) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      controller.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _abrirSeletorApps() async {
    // Mostra loading
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

    // Separa apps populares (que existem no dispositivo) dos demais
    List<AppInfo> populares = [];
    List<AppInfo> outros = [];

    for (var app in appsInstalados) {
      if (_appsPopularesPkg.contains(app.packageName)) {
        populares.add(app);
      } else {
        outros.add(app);
      }
    }

    // Cópia local da seleção
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
                const Expanded(child: Text('Selecionar Apps')),
                if (selecionados.isNotEmpty)
                  Chip(
                    label: Text('${selecionados.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: appsInstalados.isEmpty
                  ? const Center(child: Text('Nenhum app encontrado.\nVerifique as permissões.'))
                  : ListView(
                      children: [
                        // Seção Apps Populares
                        if (populares.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              '🔥 Apps Populares',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          ...populares.map(buildAppTile),
                          const Divider(thickness: 2),
                        ],
                        // Seção Outros Apps
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            '📱 Todos os Apps',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...outros.map(buildAppTile),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _appsBloqueados = selecionados;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text('Pronto (${selecionados.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          );
        },
      ),
    );
  }

  String _buildDataCompleta(String data, String hora) {
    if (data.isEmpty) return '';
    if (hora.isEmpty) return data;
    return '$data $hora';
  }

  Future<void> _salvarTarefa() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título é obrigatório.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? dataInicio = _buildDataCompleta(_dataInicioController.text, _horaInicioController.text);
    String? dataFim = _buildDataCompleta(_dataFimController.text, _horaFimController.text);

    Tarefa tarefa = Tarefa(
      idTarefa: widget.tarefaExistente?.idTarefa,
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      prioridade: _prioridadeSelecionada,
      dataInicio: dataInicio.isNotEmpty ? dataInicio : null,
      dataFim: dataFim.isNotEmpty ? dataFim : null,
      andamento: widget.tarefaExistente?.andamento ?? 'Pendente',
      modoFoco: _modoFoco,
      appProdutividade: _appProdutividade,
      appsBloqueados: _appsBloqueados.isNotEmpty ? jsonEncode(_appsBloqueados) : null,
    );

    bool sucesso;
    if (_isEditMode) {
      sucesso = await _supabaseService.atualizarTarefa(tarefa);
    } else {
      sucesso = await _supabaseService.cadastrarTarefa(tarefa);
    }

    setState(() {
      _isLoading = false;
    });

    if (sucesso) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Tarefa atualizada!' : 'Tarefa criada com sucesso!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar tarefa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Editar Tarefa" : "Nova Tarefa"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditMode ? "Editar Tarefa" : "Criar Nova Tarefa",
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _prioridadeSelecionada,
              decoration: const InputDecoration(
                labelText: 'Prioridade',
                border: OutlineInputBorder(),
              ),
              items: ['Alta', 'Média', 'Baixa']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _prioridadeSelecionada = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Modo Foco'),
              subtitle: const Text('Ativar bloqueio de apps durante esta tarefa'),
              value: _modoFoco,
              onChanged: (bool value) {
                setState(() {
                  _modoFoco = value;
                  if (!value) {
                    _appsBloqueados.clear();
                  }
                });
              },
              activeColor: Colors.green,
            ),

            // Seletor de apps bloqueados (só aparece quando Modo Foco ativo)
            if (_modoFoco) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _abrirSeletorApps,
                icon: const Icon(Icons.block, color: Colors.red),
                label: Text(
                  _appsBloqueados.isEmpty
                      ? 'Selecionar apps para bloquear'
                      : '${_appsBloqueados.length} app(s) selecionado(s)',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_appsBloqueados.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _appsBloqueados.entries.map((entry) {
                    return Chip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _appsBloqueados.remove(entry.key);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _appProdutividade,
              decoration: const InputDecoration(
                labelText: 'App Produtivo (Opcional)',
                border: OutlineInputBorder(),
                helperText: 'Onde você executará esta tarefa?',
              ),
              items: ['Nenhum', 'Notion', 'VS Code', 'Figma', 'Word', 'Duolingo']
                  .map((p) => DropdownMenuItem(value: p == 'Nenhum' ? null : p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _appProdutividade = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Data e Hora de Início
            Text('Início', style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dataInicioController,
                    readOnly: true,
                    onTap: () => _selecionarData(_dataInicioController),
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _horaInicioController,
                    readOnly: true,
                    onTap: () => _selecionarHora(_horaInicioController),
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data e Hora de Fim
            Text('Fim', style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dataFimController,
                    readOnly: true,
                    onTap: () => _selecionarData(_dataFimController),
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _horaFimController,
                    readOnly: true,
                    onTap: () => _selecionarHora(_horaFimController),
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvarTarefa,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditMode ? "Salvar Alterações" : "Salvar Tarefa"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
