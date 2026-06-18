import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tarefa.dart';
import '../services/supabase_service.dart';
import '../services/app_blocker_channel.dart';
import '../services/notification_service.dart';
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

  /// Parse robusto de datas do Supabase
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

  bool _isFocoAtivo(Tarefa tarefa) {
    if (!tarefa.modoFoco) return false;
    if (tarefa.andamento == 'Concluída' || tarefa.andamento == 'Cancelada') return false;
    
    DateTime agora = DateTime.now();
    DateTime? inicio = _parseDataTarefa(tarefa.dataInicio, defaultHora: 0, defaultMin: 0);
    DateTime? fim = _parseDataTarefa(tarefa.dataFim, defaultHora: 23, defaultMin: 59);
    
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
                const SizedBox(height: 4),
                if (tarefa.descricao.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      tarefa.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _corPrioridade(tarefa.prioridade).withOpacity(0.1),
                        border: Border.all(color: _corPrioridade(tarefa.prioridade)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tarefa.prioridade.toUpperCase(),
                        style: TextStyle(
                          color: _corPrioridade(tarefa.prioridade),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (tarefa.dataInicio != null)
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            () {
                              try {
                                final dt = DateTime.parse(tarefa.dataInicio!).toLocal();
                                return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {
                                return tarefa.dataInicio!.split(tarefa.dataInicio!.contains('T') ? 'T' : ' ').last.substring(0, 5);
                              }
                            }(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${tarefa.andamento}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (tarefa.idTarefa == null) return;
                  if (value == 'deletar') {
                    await AppBlockerChannel.clearBlockedApps();
                    await _supabaseService.deletarTarefa(tarefa.idTarefa!);
                    final ns = NotificationService();
                    await ns.cancelNotification(tarefa.idTarefa! * 10);
                    await ns.cancelNotification(tarefa.idTarefa! * 10 + 1);
                    _carregarTarefas();
                  } else if (value == 'editar' || value == 'duplicar') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NovaTarefaScreen(
                          tarefaExistente: tarefa,
                          isDuplicating: value == 'duplicar',
                        ),
                      ),
                    );
                    _carregarTarefas();
                  } else {
                    // === REGRA: Não pode voltar de "Em Andamento" para "Pendente" ===
                    if (value == 'Pendente' && tarefa.andamento == 'Em Andamento') {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não é possível voltar uma tarefa em andamento para pendente. Edite os horários se necessário.')),
                        );
                      }
                      return;
                    }

                    // === REGRA: Ao marcar como "Em Andamento", atualizar hora de início para agora ===
                    if (value == 'Em Andamento' && tarefa.andamento == 'Pendente') {
                      final agora = DateTime.now();
                      String novaDataInicio = agora.toUtc().toIso8601String();
                      String? novaDataFim;
                      
                      try {
                        if (tarefa.dataInicio != null && tarefa.dataFim != null) {
                          final iniAntigo = _parseDataTarefa(tarefa.dataInicio);
                          final fimAntigo = _parseDataTarefa(tarefa.dataFim);
                          if (iniAntigo != null && fimAntigo != null) {
                            final duracao = fimAntigo.difference(iniAntigo);
                            final novoFim = agora.add(duracao);
                            novaDataFim = novoFim.toUtc().toIso8601String();
                          }
                        }
                      } catch (_) {}

                      await _supabaseService.atualizarAndamentoComInicio(
                        tarefa.idTarefa!, 
                        'Em Andamento', 
                        novaDataInicio,
                        novaDataFim: novaDataFim,
                      );
                      _carregarTarefas();
                      return;
                    }

                    // === REGRA: Ao concluir, calcular pontos pelo tempo REAL gasto ===
                    if (value == 'Concluída' && tarefa.andamento != 'Concluída') {
                      await AppBlockerChannel.clearBlockedApps();
                      final ns = NotificationService();
                      await ns.cancelNotification(tarefa.idTarefa! * 10);
                      await ns.cancelNotification(tarefa.idTarefa! * 10 + 1);

                      double minutosReais = 0;
                      try {
                        if (tarefa.dataInicio != null) {
                          final ini = _parseDataTarefa(tarefa.dataInicio);
                          if (ini != null) {
                            final agora = DateTime.now();
                            minutosReais = agora.difference(ini).inSeconds / 60.0;
                          }
                        }
                      } catch (_) {}

                      // Mínimo 1 minuto para evitar 0 pontos
                      if (minutosReais <= 0) minutosReais = 1.0;

                      int ptsExtra = (minutosReais * 2.4).round();
                      await _supabaseService.adicionarPontos(ptsExtra);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa concluída! +$ptsExtra pontos (${minutosReais.toStringAsFixed(1)} min) 🎉')));
                      }
                    }

                    await _supabaseService.atualizarAndamento(tarefa.idTarefa!, value);
                    _carregarTarefas();
                  }
                },
                itemBuilder: (context) => [
                  if (tarefa.andamento != 'Concluída')
                    const PopupMenuItem(value: 'editar', child: Text('✏️ Editar')),
                  const PopupMenuItem(value: 'duplicar', child: Text('📑 Duplicar')),
                  const PopupMenuDivider(),
                  if (tarefa.andamento != 'Pendente')
                    const PopupMenuItem(value: 'Pendente', child: Text('Marcar como Pendente')),
                  if (tarefa.andamento != 'Em Andamento')
                    const PopupMenuItem(value: 'Em Andamento', child: Text('Marcar como Em Andamento')),
                  if (tarefa.andamento != 'Concluída')
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
