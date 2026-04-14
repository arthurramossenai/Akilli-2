import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';
import 'nova_tarefa_screen.dart';
import 'login_screen.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({Key? key}) : super(key: key);

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Tarefa> _tarefas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    setState(() => _isLoading = true);
    final tarefas = await _supabaseService.getTarefas();
    setState(() {
      _tarefas = tarefas;
      _isLoading = false;
    });
  }

  Color _corPrioridade(String prioridade) {
    if (prioridade == 'Modo foco') {
      return Colors.red[400]!;
    } else {
      return Colors.blue[400]!;
    }
  }

  IconData _iconeAndamento(String andamento) {
    switch (andamento) {
      case 'Concluída':
        return Icons.check_circle;
      case 'Em Andamento':
        return Icons.timelapse;
      case 'Cancelada':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Akili",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarTarefas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tarefas",
                      style: GoogleFonts.raleway(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Defina suas metas e tarefas importantes. O app usa essas informações para lembrar você do que realmente importa quando surgir uma distração.",
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NovaTarefaScreen()),
                        );
                        _carregarTarefas();
                      },
                      child: const Text("Nova Tarefa"),
                    ),
                    const SizedBox(height: 24),

                    if (_tarefas.isEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            "Nenhuma Tarefa Registrada",
                            style: GoogleFonts.raleway(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tarefas.length,
                        itemBuilder: (context, index) {
                          final tarefa = _tarefas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Icon(
                                _iconeAndamento(tarefa.andamento),
                                color: _corPrioridade(tarefa.prioridade),
                                size: 28,
                              ),
                              title: Text(
                                tarefa.titulo,
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tarefa.prioridade} • ${tarefa.andamento}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (tarefa.descricao.isNotEmpty)
                                    Text(
                                      tarefa.descricao,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (tarefa.idTarefa == null) return;
                                  if (value == 'deletar') {
                                    await _supabaseService.deletarTarefa(tarefa.idTarefa!);
                                    _carregarTarefas();
                                  } else {
                                    await _supabaseService.atualizarAndamento(
                                      tarefa.idTarefa!,
                                      value,
                                    );
                                    _carregarTarefas();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Pendente',
                                    child: Text('Marcar como Pendente'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Em Andamento',
                                    child: Text('Marcar como Em Andamento'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Concluída',
                                    child: Text('Marcar como Concluída'),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'deletar',
                                    child: Text(
                                      'Deletar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
