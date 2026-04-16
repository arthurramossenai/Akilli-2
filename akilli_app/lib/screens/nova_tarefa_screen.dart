import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';

class NovaTarefaScreen extends StatefulWidget {
  const NovaTarefaScreen({Key? key}) : super(key: key);

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
  
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

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

    Tarefa novaTarefa = Tarefa(
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      prioridade: _prioridadeSelecionada,
      dataInicio: _dataInicioController.text,
      dataFim: _dataFimController.text,
      andamento: 'Pendente',
      modoFoco: _modoFoco,
      appProdutividade: _appProdutividade,
    );

    bool sucesso = await _supabaseService.cadastrarTarefa(novaTarefa);

    setState(() {
      _isLoading = false;
    });

    if (sucesso) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarefa criada com sucesso!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar tarefa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Tarefa"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Criar Nova Tarefa",
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
              subtitle: const Text('Ativar bloqueio de alertas durante esta tarefa'),
              value: _modoFoco,
              onChanged: (bool value) {
                setState(() {
                  _modoFoco = value;
                });
              },
              activeColor: Colors.green,
            ),
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
                    : const Text("Salvar Tarefa"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
