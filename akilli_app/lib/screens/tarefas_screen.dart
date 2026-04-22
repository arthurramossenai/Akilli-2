import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';
import '../services/app_blocker_channel.dart';
import 'nova_tarefa_screen.dart';
import 'login_screen.dart';

class TarefasScreen extends StatefulWidget {
  final bool isTab;
  const TarefasScreen({Key? key, this.isTab = false}) : super(key: key);

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
    final tarefasData = await _supabaseService.getTarefas();
    if (mounted) {
      setState(() {
        _tarefas = tarefasData;
        _isLoading = false;
      });
    }
  }

  bool _isFocoAtivo(Tarefa tarefa) {
    if (!tarefa.modoFoco) return false;
    if (tarefa.andamento == 'Concluída' || tarefa.andamento == 'Cancelada') return false;
    
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
    
    if (inicio != null) {
      if (fim != null) {
        return !agora.isBefore(inicio) && !agora.isAfter(fim);
      } else {
        return !agora.isBefore(inicio);
      }
    }
    
    return false;
  }

  IconData _iconeAndamento(String status) {
    switch (status) {
      case 'Concluída': return Icons.check_circle;
      case 'Em Andamento': return Icons.play_circle_fill;
      default: return Icons.circle_outlined;
    }
  }

  Color _corPrioridade(String prioridade) {
    switch (prioridade) {
      case 'Alta': return Colors.red;
      case 'Média': return Colors.orange;
      case 'Baixa': return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _buildList(List<Tarefa> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Text(
          "Nenhuma Tarefa",
          style: GoogleFonts.raleway(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final tarefa = lista[index];
        final bool focoAtivo = _isFocoAtivo(tarefa);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: focoAtivo ? 4 : 2,
          color: focoAtivo ? Colors.green[50] : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: focoAtivo
                ? BorderSide(color: Colors.green[400]!, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: focoAtivo
                ? const Icon(Icons.local_fire_department, color: Colors.green, size: 28)
                : Icon(
                    _iconeAndamento(tarefa.andamento),
                    color: _corPrioridade(tarefa.prioridade),
                    size: 28,
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    tarefa.titulo,
                    style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                  ),
                ),
                if (focoAtivo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 EM FOCO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
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
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (tarefa.idTarefa == null) return;
                if (value == 'deletar') {
                  await AppBlockerChannel.clearBlockedApps();
                  await _supabaseService.deletarTarefa(tarefa.idTarefa!);
                  _carregarTarefas();
                } else if (value == 'editar') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NovaTarefaScreen(tarefaExistente: tarefa),
                    ),
                  );
                  _carregarTarefas();
                } else {
                  if (value == 'Concluída' && tarefa.andamento != 'Concluída') {
                    await AppBlockerChannel.clearBlockedApps();
                    int minutosTracker = 0;
                    try {
                      if (tarefa.dataInicio != null) {
                        DateTime parseDate(String dt) {
                          final partes = dt.split(' ');
                          final d = partes[0].split('-');
                          int h = 0, m = 0;
                          if (partes.length > 1) {
                            final t = partes[1].split(':');
                            h = int.parse(t[0]); m = int.parse(t[1]);
                          }
                          return DateTime(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]), h, m);
                        }
                        final ini = parseDate(tarefa.dataInicio!);
                        final agora = DateTime.now();
                        DateTime fimConsiderado = agora;
                        if (tarefa.dataFim != null && tarefa.dataFim!.isNotEmpty) {
                          final fimReal = parseDate(tarefa.dataFim!);
                          if (agora.isAfter(fimReal)) {
                            fimConsiderado = fimReal;
                          }
                        }
                        minutosTracker = fimConsiderado.difference(ini).inMinutes;
                      }
                    } catch (_) {}
                    
                    if (minutosTracker <= 0) minutosTracker = 1;
                    
                    int ptsExtra = (minutosTracker * 2.4).round();
                    await _supabaseService.adicionarPontos(ptsExtra);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa concluída! +$ptsExtra pontos 🎉')));
                    }
                  }

                  await _supabaseService.atualizarAndamento(tarefa.idTarefa!, value);
                  _carregarTarefas();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('✏️ Editar')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'Pendente', child: Text('Marcar como Pendente')),
                const PopupMenuItem(value: 'Em Andamento', child: Text('Marcar como Em Andamento')),
                const PopupMenuItem(value: 'Concluída', child: Text('Marcar como Concluída')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'deletar', child: Text('Deletar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _tarefas.where((t) => t.andamento == 'Pendente').toList();
    final emAndamento = _tarefas.where((t) => t.andamento == 'Em Andamento').toList();
    final concluidas = _tarefas.where((t) => t.andamento == 'Concluída').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: widget.isTab ? null : AppBar(
          title: Text(
            "Akilli",
            style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton(
                onPressed: () {
                  _supabaseService.logout();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                child: const Text("Sair"),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tarefas",
                              style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NovaTarefaScreen()),
                                );
                                _carregarTarefas();
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Nova"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Defina suas metas e gerencie o andamento.",
                          style: GoogleFonts.raleway(fontSize: 16, color: Colors.grey[700], height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: "Pendente"),
                      Tab(text: "Em Andamento"),
                      Tab(text: "Concluídas"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        RefreshIndicator(onRefresh: _carregarTarefas, child: _buildList(pendentes)),
                        RefreshIndicator(onRefresh: _carregarTarefas, child: _buildList(emAndamento)),
                        RefreshIndicator(onRefresh: _carregarTarefas, child: _buildList(concluidas)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
