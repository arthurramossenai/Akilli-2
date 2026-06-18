import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import 'perfil_publico_screen.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({Key? key}) : super(key: key);

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;

  List<Map<String, dynamic>> _solicitacoesAmizade = [];
  List<Map<String, dynamic>> _convitesGrupo = [];
  bool _isLoadingAmizades = true;
  bool _isLoadingGrupos = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarTudo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    _carregarAmizades();
    _carregarConvites();
  }

  Future<void> _carregarAmizades() async {
    setState(() => _isLoadingAmizades = true);
    final dados = await _supabaseService.getSolicitacoesAmizadePendentes();
    if (mounted) {
      setState(() {
        _solicitacoesAmizade = dados;
        _isLoadingAmizades = false;
      });
    }
  }

  Future<void> _carregarConvites() async {
    setState(() => _isLoadingGrupos = true);
    final dados = await _supabaseService.getConvitesGrupoPendentes();
    if (mounted) {
      setState(() {
        _convitesGrupo = dados;
        _isLoadingGrupos = false;
      });
    }
  }

  Future<void> _responderAmizade(int outroUserId, String resposta, int index) async {
    final success = await _supabaseService.responderSolicitacaoAmizade(outroUserId, resposta);
    if (success && mounted) {
      setState(() {
        _solicitacoesAmizade.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta == 'aceito' ? 'Amizade aceita! 🎉' : 'Solicitação recusada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _responderConviteGrupo(int conviteId, int grupoId, String resposta, int index) async {
    final success = await _supabaseService.responderConviteGrupo(conviteId, grupoId, resposta);
    if (success && mounted) {
      setState(() {
        _convitesGrupo.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta == 'aceito' ? 'Você entrou no grupo! 🎉' : 'Convite recusado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmizades = _solicitacoesAmizade.length;
    final totalConvites = _convitesGrupo.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notificações',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.kombuGreen,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.kombuGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              labelStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.raleway(fontWeight: FontWeight.w500, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 18),
                      const SizedBox(width: 6),
                      Text('Amizades${totalAmizades > 0 ? ' ($totalAmizades)' : ''}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_add, size: 18),
                      const SizedBox(width: 6),
                      Text('Grupos${totalConvites > 0 ? ' ($totalConvites)' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAmizadesTab(),
          _buildGruposTab(),
        ],
      ),
    );
  }

  // ==================== TAB: SOLICITAÇÕES DE AMIZADE ====================

  Widget _buildAmizadesTab() {
    if (_isLoadingAmizades) {
      return const Center(child: CircularProgressIndicator(color: AppColors.kombuGreen));
    }

    if (_solicitacoesAmizade.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_disabled,
        title: 'Nenhuma solicitação',
        subtitle: 'Quando alguém quiser ser seu amigo,\nvocê verá aqui!',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarAmizades,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _solicitacoesAmizade.length,
        itemBuilder: (context, index) {
          final item = _solicitacoesAmizade[index];
          final remetente = item['usuarios'];
          final String nome = remetente?['nome'] ?? 'Usuário';
          final String username = remetente?['usuario'] ?? '';
          final String? avatarUrl = remetente?['avatar_url'];
          final int outroUserId = item['usuario1_id'];
          final String inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PerfilPublicoScreen(
                            userId: outroUserId,
                            nome: nome,
                            username: username,
                            pontos: remetente?['pontos'] ?? 0,
                            avatarUrl: avatarUrl,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.kombuGreen,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              inicial,
                              style: GoogleFonts.raleway(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username quer ser seu amigo',
                          style: GoogleFonts.raleway(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botões
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Aceitar
                      Material(
                        color: AppColors.kombuGreen,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _responderAmizade(outroUserId, 'aceito', index),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.check, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Recusar
                      Material(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _responderAmizade(outroUserId, 'recusado', index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.close, color: Colors.red[400], size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== TAB: CONVITES DE GRUPO ====================

  Widget _buildGruposTab() {
    if (_isLoadingGrupos) {
      return const Center(child: CircularProgressIndicator(color: AppColors.kombuGreen));
    }

    if (_convitesGrupo.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_off,
        title: 'Nenhum convite',
        subtitle: 'Quando alguém te convidar para um grupo,\nvocê verá aqui!',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarConvites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _convitesGrupo.length,
        itemBuilder: (context, index) {
          final item = _convitesGrupo[index];
          final remetente = item['remetente'];
          final grupo = item['grupo'];
          final String nomeRemetente = remetente?['nome'] ?? 'Alguém';
          final String usernameRemetente = remetente?['usuario'] ?? '';
          final String? avatarUrl = remetente?['avatar_url'];
          final String nomeGrupo = grupo?['nome'] ?? 'Grupo';
          final int conviteId = item['id'];
          final int grupoId = item['grupo_id'];
          final String inicial = nomeRemetente.isNotEmpty ? nomeRemetente[0].toUpperCase() : '?';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ícone do grupo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple[300]!, Colors.deepPurple[600]!],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.group, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeGrupo,
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppColors.kombuGreen,
                                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null
                                      ? Text(
                                          inicial,
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '@$usernameRemetente convidou você',
                                    style: GoogleFonts.raleway(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _responderConviteGrupo(conviteId, grupoId, 'recusado', index),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[400],
                            side: BorderSide(color: Colors.red[200]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _responderConviteGrupo(conviteId, grupoId, 'aceito', index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kombuGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Entrar no Grupo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
