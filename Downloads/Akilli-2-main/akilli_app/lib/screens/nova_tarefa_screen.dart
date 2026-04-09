import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/api_service.dart';

class NovaTarefaScreen extends StatefulWidget {
  const NovaTarefaScreen({Key? key}) : super(key: key);

  @override
  State<NovaTarefaScreen> createState() => _NovaTarefaScreenState();
}

class _NovaTarefaScreenState extends State<NovaTarefaScreen> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _prioridadeController = TextEditingController(text: 'Média');
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  final AkilliApiService _apiService = AkilliApiService();
  bool _isLoading = false;

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
      prioridade: _prioridadeController.text,
      dataInicio: _dataInicioController.text,
      dataFim: _dataFimController.text,
      andamento: 'Pendente',
    );

    bool sucesso = await _apiService.cadastrarTarefa(novaTarefa);

    setState(() {
      _isLoading = false;
    });

    if (sucesso) {
      if (mounted) {
        Navigator.pop(context); // Volta para a tela de tarefas
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
            TextField(
              controller: _prioridadeController,
              decoration: const InputDecoration(
                labelText: 'Prioridade (Alta, Média, Baixa)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dataInicioController,
                    decoration: const InputDecoration(
                      labelText: 'Data de Início',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _dataFimController,
                    decoration: const InputDecoration(
                      labelText: 'Data de Fim',
                      border: OutlineInputBorder(),
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
