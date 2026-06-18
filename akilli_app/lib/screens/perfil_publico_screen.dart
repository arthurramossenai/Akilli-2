import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';

class PerfilPublicoScreen extends StatefulWidget {
  final int userId;
  final String nome;
  final String username;
  final int pontos;
  final String? avatarUrl;

  const PerfilPublicoScreen({
    Key? key,
    required this.userId,
    required this.nome,
    required this.username,
    required this.pontos,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<PerfilPublicoScreen> createState() => _PerfilPublicoScreenState();
}

class _PerfilPublicoScreenState extends State<PerfilPublicoScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  String? _statusAmizade; // null (nenhuma), 'pendente_enviado', 'pendente_recebido', 'aceito'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarStatus();
  }

  Future<void> _carregarStatus() async {
    final statusDB = await _supabaseService.checarStatusAmizade(widget.userId);
    setState(() {
      _statusAmizade = statusDB;
      _isLoading = false;
    });
  }

  Future<void> _enviarSolicitacao() async {
    setState(() => _isLoading = true);
    final success = await _supabaseService.enviarSolicitacaoAmizade(widget.userId);
    if (success) {
      await _carregarStatus();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar solicitação.')));
      }
    }
  }

  Future<void> _responderSolicitacao(String resposta) async {
    setState(() => _isLoading = true);
    final success = await _supabaseService.responderSolicitacaoAmizade(widget.userId, resposta);
    if (success) {
      await _carregarStatus();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao responder.')));
      }
    }
  }

  // --- Função para convidar para um grupo ---
  Future<void> _mostrarDialogConviteGrupo() async {
    // 1. Carrega os grupos que eu pertenço
    final meusGrupos = await _supabaseService.getMeusGrupos();
    if (meusGrupos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você não faz parte de nenhum grupo para convidar.')));
      return;
    }

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Convidar para...', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: meusGrupos.length,
              itemBuilder: (context, index) {
                final grupo = meusGrupos[index]['grupos'];
                return ListTile(
                  title: Text(grupo['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Código: ${grupo['codigo']}'),
                  trailing: const Icon(Icons.send, color: AppColors.kombuGreen),
                  onTap: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviando convite...')));
                    final success = await _supabaseService.convidarParaGrupo(widget.userId, grupo['id_grupo']);
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Convite enviado para @${widget.username}!')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ou convite já enviado.')));
                      }
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final inicial = widget.nome.isNotEmpty ? widget.nome[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('@${widget.username}', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.kombuGreen,
      ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator(color: AppColors.kombuGreen)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.kombuGreen,
                      backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
                      child: widget.avatarUrl == null
                          ? Text(
                              inicial,
                              style: GoogleFonts.raleway(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.nome,
                      style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bone,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.pontos} pontos',
                            style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.kombuGreen),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    // --- BOTOES DE AÇÃO SOCIAL ---
                    
                    // AMIZADES
                    if (_statusAmizade == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _enviarSolicitacao,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Adicionar aos Amigos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kombuGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else if (_statusAmizade == 'enviado')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: null, // Desabilitado
                          icon: const Icon(Icons.access_time),
                          label: const Text('Solicitação Enviada'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else if (_statusAmizade == 'recebido')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _responderSolicitacao('aceito'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kombuGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Aceitar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _responderSolicitacao('recusado'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Recusar'),
                            ),
                          ),
                        ],
                      )
                    else if (_statusAmizade == 'aceito')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check_circle, color: AppColors.kombuGreen),
                          label: const Text('Vocês são amigos', style: TextStyle(color: AppColors.kombuGreen)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppColors.kombuGreen),
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 16),
                    
                    // GRUPOS
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _mostrarDialogConviteGrupo,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Convidar para um Grupo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kombuGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
