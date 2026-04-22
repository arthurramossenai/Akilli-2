import 'dart:convert';
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

  String _prioridadeSelecionada = 'Média';
  bool _modoFoco = false;
  String? _appProdutividade;
  List<String> _appsBloqueados = []; // Lista de package_names selecionados

  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.tarefaExistente != null) {
      _isEditMode = true;
      final t = widget.tarefaExistente!;
      _tituloController.text = t.titulo;
      _descricaoController.text = t.descricao;
      _dataInicioController.text = t.dataInicio ?? '';
      _dataFimController.text = t.dataFim ?? '';
      _prioridadeSelecionada = t.prioridade;
      _modoFoco = t.modoFoco;
      _appProdutividade = t.appProdutividade;
      if (t.appsBloqueados != null && t.appsBloqueados!.isNotEmpty) {
        try {
          _appsBloqueados = List<String>.from(jsonDecode(t.appsBloqueados!));
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

  Future<void> _abrirSeletorApps() async {
    // Mostra loading enquanto carrega os apps do dispositivo
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

    // Cria cópia local da seleção para o dialog
    List<String> selecionados = List.from(_appsBloqueados);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Selecionar Apps para Bloquear'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: appsInstalados.isEmpty
                  ? const Center(child: Text('Nenhum app encontrado.\nVerifique as permissões.'))
                  : ListView.builder(
                      itemCount: appsInstalados.length,
                      itemBuilder: (context, index) {
                        final app = appsInstalados[index];
                        bool marcado = selecionados.contains(app.packageName);
                        return CheckboxListTile(
                          value: marcado,
                          activeColor: Colors.green,
                          title: Text(app.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                selecionados.add(app.packageName);
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _appsBloqueados = selecionados;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Pronto (${selecionados.length})'),
              ),
            ],
          );
        },
      ),
    );
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

    Tarefa tarefa = Tarefa(
      idTarefa: widget.tarefaExistente?.idTarefa,
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      prioridade: _prioridadeSelecionada,
      dataInicio: _dataInicioController.text.isNotEmpty ? _dataInicioController.text : null,
      dataFim: _dataFimController.text.isNotEmpty ? _dataFimController.text : null,
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

            // Seletor de apps (só aparece quando Modo Foco está ativo)
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
                  children: _appsBloqueados.map((pkg) {
                    // Mostra o nome curto do package
                    String label = pkg.split('.').last;
                    return Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _appsBloqueados.remove(pkg);
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dataInicioController,
                    readOnly: true,
                    onTap: () => _selecionarData(_dataInicioController),
                    decoration: const InputDecoration(
                      labelText: 'Data de Início',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _dataFimController,
                    readOnly: true,
                    onTap: () => _selecionarData(_dataFimController),
                    decoration: const InputDecoration(
                      labelText: 'Data de Fim',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
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
