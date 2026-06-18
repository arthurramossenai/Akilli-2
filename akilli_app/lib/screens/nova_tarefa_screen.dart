import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';
import '../services/device_service.dart';
import '../services/notification_service.dart';
import 'package:installed_apps/app_info.dart';

class NovaTarefaScreen extends StatefulWidget {
  final Tarefa? tarefaExistente; // Se não-nulo, estamos editando ou duplicando
  final bool isDuplicating;

  const NovaTarefaScreen({Key? key, this.tarefaExistente, this.isDuplicating = false}) : super(key: key);

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
  int? _alertaMinutos; // Null significa sem alerta
  bool _modoFoco = false;
  Map<String, String> _appsProdutivos = {};
  
  // Armazena {packageName: displayName} dos apps bloqueados
  Map<String, String> _appsBloqueados = {};

  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _tituloError;

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
      _isEditMode = !widget.isDuplicating;
      final t = widget.tarefaExistente!;
      _tituloController.text = widget.isDuplicating ? '${t.titulo} (Cópia)' : t.titulo;
      _descricaoController.text = t.descricao;
      _prioridadeSelecionada = ['Alta', 'Média', 'Baixa'].contains(t.prioridade) ? t.prioridade : 'Média';
      _modoFoco = t.modoFoco;
      _alertaMinutos = t.alertaMinutos;
      
      // Parse dos apps produtivos (Mesmo formato JSON que appsBloqueados)
      if (t.appProdutividade != null && t.appProdutividade!.isNotEmpty) {
        try {
          final decoded = jsonDecode(t.appProdutividade!);
          if (decoded is Map) {
            _appsProdutivos = Map<String, String>.from(decoded);
          }
        } catch (_) {
          // Fallback para string simples (se fosse escolhido no dropdown antigo)
          final validApps = ['Notion', 'VS Code', 'Figma', 'Word', 'Duolingo'];
          if (validApps.contains(t.appProdutividade)) {
            _appsProdutivos = {'legacy': t.appProdutividade!};
          }
        }
      }
      
      // Parse da data e hora - tenta ISO parse primeiro (correto com timezone), depois fallback manual
      void parseDateTime(String dtStr, TextEditingController dateCtrl, TextEditingController timeCtrl) {
        if (dtStr.trim().isEmpty) return;
        
        print('parseDateTime input raw: "$dtStr"');
        
        // Método 1: Usar DateTime.parse nativo (suporta ISO 8601 com timezone)
        try {
          final dt = DateTime.parse(dtStr).toLocal();
          dateCtrl.text = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          timeCtrl.text = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          print('parseDateTime SUCCESS (ISO) -> date: "${dateCtrl.text}", time: "${timeCtrl.text}"');
          return;
        } catch (e) {
          print('parseDateTime ISO parse failed: $e');
        }
        
        // Método 2: Fallback manual para "YYYY-MM-DD HH:mm"
        try {
          String normalized = dtStr.trim().replaceFirst('T', ' ');
          // Remove timezone suffix
          normalized = normalized.replaceAll(RegExp(r'[Z]$'), '');
          normalized = normalized.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
          
          final partes = normalized.split(' ');
          
          if (partes.isNotEmpty && partes[0].contains('-')) {
            dateCtrl.text = partes[0];
          }
          
          if (partes.length > 1 && partes[1].contains(':')) {
            final timeParts = partes[1].split(':');
            if (timeParts.length >= 2) {
              timeCtrl.text = '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}';
            }
          }
          print('parseDateTime FALLBACK -> date: "${dateCtrl.text}", time: "${timeCtrl.text}"');
        } catch (e) {
          print('parseDateTime FALLBACK ALSO FAILED: $e');
        }
      }

      if (t.dataInicio != null && t.dataInicio!.isNotEmpty) {
        parseDateTime(t.dataInicio!, _dataInicioController, _horaInicioController);
      }
      if (t.dataFim != null && t.dataFim!.isNotEmpty) {
        parseDateTime(t.dataFim!, _dataFimController, _horaFimController);
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
    } else {
      // Valor padrão para data/hora inicial e final de nova tarefa
      final agora = DateTime.now();
      final dataFormatada = '${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
      final horaFormatada = '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
      
      _dataInicioController.text = dataFormatada;
      _horaInicioController.text = horaFormatada;
      _dataFimController.text = dataFormatada;
      _horaFimController.text = horaFormatada;
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

  Future<void> _abrirSeletorApps(bool isFoco) async {
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
    Map<String, String> selecionados = Map.from(isFoco ? _appsProdutivos : _appsBloqueados);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildAppTile(AppInfo app) {
            bool marcado = selecionados.containsKey(app.packageName);
            return CheckboxListTile(
              value: marcado,
              activeColor: isFoco ? Colors.green : Colors.red,
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
                Icon(isFoco ? Icons.star : Icons.block, color: isFoco ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(isFoco ? 'Apps de Foco' : 'Selecionar Apps')),
                if (selecionados.isNotEmpty)
                  Chip(
                    label: Text('${selecionados.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: isFoco ? Colors.green : Colors.red,
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
                                color: isFoco ? Colors.green[700] : Colors.red[700],
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
                    if (isFoco) {
                      _appsProdutivos = selecionados;
                    } else {
                      _appsBloqueados = selecionados;
                    }
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text('Pronto (${selecionados.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: isFoco ? Colors.green : Colors.red),
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
    try {
      final dataParts = data.split('-');
      final horaParts = hora.split(':');
      final dt = DateTime(
        int.parse(dataParts[0]),
        int.parse(dataParts[1]),
        int.parse(dataParts[2]),
        int.parse(horaParts[0]),
        int.parse(horaParts[1]),
      );
      // Converte para UTC para salvar corretamente no timestamptz do Supabase
      return dt.toUtc().toIso8601String();
    } catch (_) {
      return '${data}T$hora:00';
    }
  }

  Future<void> _salvarTarefa() async {
    setState(() {
      _tituloError = null;
    });

    if (_tituloController.text.trim().isEmpty) {
      setState(() {
        _tituloError = 'O título é obrigatório para salvar a tarefa.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o título da tarefa.')),
      );
      return;
    }

    if (_dataInicioController.text.isEmpty || _horaInicioController.text.isEmpty ||
        _dataFimController.text.isEmpty || _horaFimController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário de início e fim são obrigatórios.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? dataInicio = _buildDataCompleta(_dataInicioController.text, _horaInicioController.text);
    String? dataFim = _buildDataCompleta(_dataFimController.text, _horaFimController.text);

    Tarefa tarefa = Tarefa(
      idTarefa: _isEditMode ? widget.tarefaExistente?.idTarefa : null,
      idUsuario: widget.tarefaExistente?.idUsuario,
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      prioridade: _prioridadeSelecionada,
      dataInicio: dataInicio.isNotEmpty ? dataInicio : null,
      dataFim: dataFim.isNotEmpty ? dataFim : null,
      andamento: _isEditMode ? (widget.tarefaExistente?.andamento ?? 'Pendente') : 'Pendente',
      modoFoco: _modoFoco,
      appProdutividade: _appsProdutivos.isNotEmpty ? jsonEncode(_appsProdutivos) : null,
      appsBloqueados: _appsBloqueados.isNotEmpty ? jsonEncode(_appsBloqueados) : null,
      alertaMinutos: _alertaMinutos,
    );

    Tarefa? returnedTask;
    if (_isEditMode) {
      returnedTask = await _supabaseService.atualizarTarefa(tarefa);
    } else {
      returnedTask = await _supabaseService.cadastrarTarefa(tarefa);
    }

    setState(() {
      _isLoading = false;
    });

    if (returnedTask != null) {
      // Agenda notificações usando os horários LOCAIS digitados pelo usuário
      if (returnedTask.idTarefa != null) {
        final ns = NotificationService();
        final int baseId = returnedTask.idTarefa! * 10;
        
        // Cancela existentes se for edição
        if (_isEditMode) {
          await ns.cancelNotification(baseId);
          await ns.cancelNotification(baseId + 1);
        }

        try {
          // Constrói DateTime LOCAL diretamente dos controllers (o que o usuário digitou)
          DateTime? buildLocalDt(String dataStr, String horaStr) {
            if (dataStr.isEmpty || horaStr.isEmpty) return null;
            try {
              final dp = dataStr.split('-');
              final hp = horaStr.split(':');
              return DateTime(
                int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]),
                int.parse(hp[0]), int.parse(hp[1]),
              );
            } catch (_) { return null; }
          }

          final startDt = buildLocalDt(_dataInicioController.text, _horaInicioController.text);
          final endDt = buildLocalDt(_dataFimController.text, _horaFimController.text);

          print('DEBUG NOTIFICAÇÃO: startDt=$startDt, endDt=$endDt, alerta=$_alertaMinutos');

          if (startDt != null && _alertaMinutos != null) {
            final notifyDt = startDt.subtract(Duration(minutes: _alertaMinutos!));
            final agora = DateTime.now();
            print('Notificação INÍCIO: tarefa começa em $startDt, notificação em $notifyDt ($_alertaMinutos min antes)');
            if (notifyDt.isAfter(agora)) {
              await ns.scheduleNotification(
                id: baseId,
                title: 'Tarefa: ${returnedTask.titulo}',
                body: _alertaMinutos! == 0 
                    ? 'Sua tarefa começa agora!' 
                    : 'Sua tarefa começa em $_alertaMinutos minutos!',
                scheduledDate: notifyDt,
              );
              print('✅ Notificação INÍCIO agendada com sucesso!');
            } else if (startDt.isAfter(agora)) {
              await ns.showNow(
                id: baseId,
                title: 'Tarefa: ${returnedTask.titulo}',
                body: 'Atenção! Sua tarefa começa em breve!',
              );
              print('⚠️ Notificação INÍCIO enviada imediatamente.');
            } else {
              print('⚠️ Notificação INÍCIO no passado, tarefa já começou, ignorada.');
            }
          }

          if (endDt != null) {
            final notifyEndDt = endDt.subtract(const Duration(minutes: 5));
            final agora = DateTime.now();
            print('Notificação FIM: tarefa termina em $endDt, notificação em $notifyEndDt (5 min antes)');
            if (notifyEndDt.isAfter(agora)) {
              await ns.scheduleNotification(
                id: baseId + 1,
                title: 'Tarefa: ${returnedTask.titulo}',
                body: 'Atenção! Faltam 5 minutos para o fim da sua tarefa.',
                scheduledDate: notifyEndDt,
              );
              debugPrint('✅ Notificação FIM agendada com sucesso!');
            } else if (endDt.isAfter(agora)) {
              await ns.showNow(
                id: baseId + 1,
                title: 'Tarefa: ${returnedTask.titulo}',
                body: 'Atenção! Sua tarefa acaba em menos de 5 minutos.',
              );
            } else {
              debugPrint('⚠️ Notificação FIM no passado, ignorada.');
            }
          }
        } catch (e) {
          debugPrint('Erro ao agendar notificação: $e');
        }

        // Notificação imediata de confirmação
        await ns.showNow(
          id: baseId + 2,
          title: '✅ Tarefa salva: ${returnedTask.titulo}',
          body: 'Início: ${_horaInicioController.text} | Fim: ${_horaFimController.text}',
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Tarefa atualizada!' : 'Tarefa criada com sucesso!')),
        );
      }
    } else {
      if (context.mounted) {
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
              decoration: InputDecoration(
                labelText: 'Título',
                border: const OutlineInputBorder(),
                errorText: _tituloError,
              ),
              onChanged: (_) {
                if (_tituloError != null) setState(() => _tituloError = null);
              },
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
            DropdownButtonFormField<int?>(
              value: _alertaMinutos,
              decoration: const InputDecoration(
                labelText: 'Alerta (Notificação)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications_active),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Sem alerta')),
                DropdownMenuItem(value: 0, child: Text('Na hora exata')),
                DropdownMenuItem(value: 5, child: Text('5 minutos antes')),
                DropdownMenuItem(value: 10, child: Text('10 minutos antes')),
                DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                DropdownMenuItem(value: 60, child: Text('1 hora antes')),
              ],
              onChanged: (value) {
                setState(() {
                  _alertaMinutos = value;
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
              activeColor: Colors.green, // Fallback if activeThumbColor is too new, but linter complains.
              activeTrackColor: Colors.green.withValues(alpha: 0.5),
            ),

            // Seletor de apps bloqueados (só aparece quando Modo Foco ativo)
            if (_modoFoco) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _abrirSeletorApps(false),
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
            OutlinedButton.icon(
              onPressed: () => _abrirSeletorApps(true),
              icon: Icon(Icons.star, color: Colors.green[700]),
              label: Text(
                _appsProdutivos.isEmpty
                    ? 'Selecionar Apps de Foco (Opcional)'
                    : '${_appsProdutivos.length} app(s) de foco selecionado(s)',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: BorderSide(color: Colors.green[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_appsProdutivos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _appsProdutivos.entries.map((entry) {
                  return Chip(
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _appsProdutivos.remove(entry.key);
                      });
                    },
                    backgroundColor: Colors.green[50],
                    side: BorderSide(color: Colors.green[200]!),
                  );
                }).toList(),
              ),
            ],

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
