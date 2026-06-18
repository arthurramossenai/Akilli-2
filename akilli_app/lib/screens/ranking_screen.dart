import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'perfil_publico_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;

  // Ranking global
  List<Map<String, dynamic>> _rankingGlobal = [];
  bool _isLoadingGlobal = true;

  // Ranking amigos
  List<Map<String, dynamic>> _rankingAmigos = [];
  bool _isLoadingAmigos = true;

  // Grupos
  List<Map<String, dynamic>> _meusGrupos = [];
  bool _isLoadingGrupos = true;

  // Ranking do grupo selecionado
  Map<String, dynamic>? _grupoSelecionado;
  List<Map<String, dynamic>> _rankingGrupo = [];
  bool _isLoadingRankingGrupo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Recarrega dados ao trocar de tab (indexIsChanging evita duplicatas)
      if (!_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        _carregarAmigos();
      }
      if (_tabController.index == 2) {
        _carregarGrupos();
      }
    });
    _carregarRankingGlobal();
    _carregarAmigos(); // Pré-carrega amigos para não ficar vazio na primeira vez
    _carregarGrupos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _erroGlobal;
  String? _erroAmigos;

  Future<void> _carregarRankingGlobal() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGlobal = true;
      _erroGlobal = null;
    });
    try {
      final dados = await _supabaseService.getRanking();
      print('DEBUG RANKING SCREEN: Global recebeu ${dados.length} itens');
      if (mounted) {
        setState(() {
          _rankingGlobal = dados;
          _isLoadingGlobal = false;
        });
      }
    } catch (e) {
      print('ERRO _carregarRankingGlobal: $e');
      if (mounted) {
        setState(() {
          _erroGlobal = e.toString();
          _isLoadingGlobal = false;
        });
      }
    }
  }

  Future<void> _carregarAmigos() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAmigos = true;
      _erroAmigos = null;
    });
    try {
      final dados = await _supabaseService.getRankingAmigos();
      print('DEBUG RANKING SCREEN: Amigos recebeu ${dados.length} itens');
      if (mounted) {
        setState(() {
          _rankingAmigos = dados;
          _isLoadingAmigos = false;
        });
      }
    } catch (e) {
      print('ERRO _carregarAmigos: $e');
      if (mounted) {
        setState(() {
          _erroAmigos = e.toString();
          _isLoadingAmigos = false;
        });
      }
    }
  }

  Future<void> _carregarGrupos() async {
    setState(() => _isLoadingGrupos = true);
    final dados = await _supabaseService.getMeusGrupos();
    setState(() {
      _meusGrupos = dados;
      _isLoadingGrupos = false;
    });
  }

  Future<void> _carregarRankingGrupo(int idGrupo) async {
    setState(() => _isLoadingRankingGrupo = true);
    final dados = await _supabaseService.getRankingGrupo(idGrupo);
    setState(() {
      _rankingGrupo = dados;
      _isLoadingRankingGrupo = false;
    });
  }

  void _mostrarDialogCriarGrupo() {
    final nomeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.group_add, color: Colors.deepPurple[400]),
            const SizedBox(width: 8),
            const Text('Criar Grupo'),
          ],
        ),
        content: TextField(
          controller: nomeController,
          decoration: InputDecoration(
            labelText: 'Nome do grupo',
            hintText: 'Ex: Turma do Foco 🔥',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.edit),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite um nome para o grupo')),
                );
                return;
              }
              Navigator.pop(ctx);
              final result = await _supabaseService.criarGrupo(nome);
              if (result != null) {
                final codigo = result['codigo'];
                await _carregarGrupos();
                if (mounted) {
                  _mostrarDialogCodigoGrupo(nome, codigo);
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao criar grupo')),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogCodigoGrupo(String nomeGrupo, String codigo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✅ Grupo Criado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartilhe este código com seus amigos para eles entrarem no grupo "$nomeGrupo":',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    codigo,
                    style: GoogleFonts.robotoMono(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.deepPurple[400]),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado! 📋')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogEntrarGrupo() {
    final codigoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.teal[400]),
            const SizedBox(width: 8),
            const Text('Entrar em Grupo'),
          ],
        ),
        content: TextField(
          controller: codigoController,
          decoration: InputDecoration(
            labelText: 'Código do grupo',
            hintText: 'Ex: ABC123',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.vpn_key),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final codigo = codigoController.text.trim();
              if (codigo.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O código deve ter 6 caracteres')),
                );
                return;
              }
              Navigator.pop(ctx);
              final result = await _supabaseService.entrarNoGrupo(codigo);
              if (result != null) {
                await _carregarGrupos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Entrou no grupo "${result['nome']}"! 🎉')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grupo não encontrado. Verifique o código.')),
                  );
                }
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  void _abrirRankingGrupo(Map<String, dynamic> membroData) {
    final grupo = membroData['grupos'];
    if (grupo == null) return;

    setState(() {
      _grupoSelecionado = grupo;
    });
    _carregarRankingGrupo(grupo['id_grupo']);
  }

  void _voltarParaListaGrupos() {
    setState(() {
      _grupoSelecionado = null;
      _rankingGrupo = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = _supabaseService.usuarioLogado;
    final int meuspontos = usuarioLogado?.pontos ?? 0;

    return Column(
      children: [
        // Header com pontos
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[600]!, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seus Pontos",
                        style: GoogleFonts.raleway(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$meuspontos pts",
                        style: GoogleFonts.raleway(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[700],
            labelStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.raleway(fontWeight: FontWeight.w500, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '🌍 Global'),
              Tab(text: '🤝 Amigos'),
              Tab(text: '👥 Grupos'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankingGlobal(),
              _buildRankingAmigos(),
              _grupoSelecionado != null ? _buildRankingDoGrupo() : _buildListaGrupos(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB: RANKING GLOBAL ====================

  Widget _buildRankingGlobal() {
    if (_erroGlobal != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar ranking:\n$_erroGlobal', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _carregarRankingGlobal, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarRankingGlobal,
      child: _isLoadingGlobal
          ? const Center(child: CircularProgressIndicator())
          : _rankingGlobal.isEmpty
              ? _buildEmptyState('Nenhum jogador ainda.\nComplete tarefas para aparecer!', Icons.leaderboard)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _rankingGlobal.length,
                  itemBuilder: (context, index) {
                    return _buildRankingItem(_rankingGlobal[index], index);
                  },
                ),
    );
  }

  // ==================== TAB: RANKING AMIGOS ====================
  Widget _buildRankingAmigos() {
    if (_erroAmigos != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar amigos:\n$_erroAmigos', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _carregarAmigos, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarAmigos,
      child: _isLoadingAmigos
          ? const Center(child: CircularProgressIndicator())
          : _rankingAmigos.isEmpty
              ? _buildEmptyState('Você ainda não adicionou nenhum amigo.\nBusque pessoas na lupa!', Icons.person_add)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _rankingAmigos.length,
                  itemBuilder: (context, index) {
                    return _buildRankingItem(_rankingAmigos[index], index);
                  },
                ),
    );
  }

  // ==================== TAB: LISTA DE GRUPOS ====================

  Widget _buildListaGrupos() {
    return RefreshIndicator(
      onRefresh: _carregarGrupos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botões: Criar e Entrar
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Criar Grupo',
                    color: Colors.deepPurple,
                    onTap: _mostrarDialogCriarGrupo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.login,
                    label: 'Entrar com Código',
                    color: Colors.teal,
                    onTap: _mostrarDialogEntrarGrupo,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Meus Grupos',
              style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            if (_isLoadingGrupos)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_meusGrupos.isEmpty)
              _buildEmptyState('Você ainda não está em nenhum grupo.\nCrie ou entre com um código!', Icons.group_off)
            else
              ..._meusGrupos.map((m) => _buildGrupoCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.raleway(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrupoCard(Map<String, dynamic> membroData) {
    final grupo = membroData['grupos'];
    if (grupo == null) return const SizedBox();

    final String nomeGrupo = grupo['nome'] ?? 'Grupo';
    final String codigo = grupo['codigo'] ?? '';
    final usuarioLogado = _supabaseService.usuarioLogado;
    final bool soCriador = grupo['id_criador'] == usuarioLogado?.idUsuario;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _abrirRankingGrupo(membroData),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[300]!, Colors.deepPurple[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeGrupo,
                      style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Código: $codigo',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        if (soCriador) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Criador',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== RANKING DO GRUPO SELECIONADO ====================

  Widget _buildRankingDoGrupo() {
    final String nomeGrupo = _grupoSelecionado?['nome'] ?? 'Grupo';
    final String codigoGrupo = _grupoSelecionado?['codigo'] ?? '';
    final int idGrupo = _grupoSelecionado?['id_grupo'] ?? 0;

    return Column(
      children: [
        // Header do grupo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _voltarParaListaGrupos,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeGrupo,
                      style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Código: $codigoGrupo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 20, color: Colors.grey[600]),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codigoGrupo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado! 📋')),
                  );
                },
                tooltip: 'Copiar código',
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) async {
                  if (value == 'sair') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sair do grupo?'),
                        content: Text('Deseja sair de "$nomeGrupo"? Seus pontos no grupo serão perdidos.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sair', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _supabaseService.sairDoGrupo(idGrupo);
                      _voltarParaListaGrupos();
                      _carregarGrupos();
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'sair', child: Text('🚪 Sair do grupo')),
                ],
              ),
            ],
          ),
        ),

        // Lista de ranking
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _carregarRankingGrupo(idGrupo),
            child: _isLoadingRankingGrupo
                ? const Center(child: CircularProgressIndicator())
                : _rankingGrupo.isEmpty
                    ? _buildEmptyState('Nenhum membro ainda.', Icons.group_off)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        itemCount: _rankingGrupo.length,
                        itemBuilder: (context, index) {
                          return _buildRankingItem(_rankingGrupo[index], index);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // ==================== COMPONENTES COMPARTILHADOS ====================

  Widget _buildRankingItem(Map<String, dynamic> item, int index) {
    final usuarioLogado = _supabaseService.usuarioLogado;
    final String nome = item['nome'] ?? 'Anônimo';
    final String nomeUsuario = item['usuario'] ?? '';
    final int pontos = item['pontos'] ?? 0;
    final bool souEu = item['id_usuario'] == usuarioLogado?.idUsuario;
    final bool isPodium = index < 3;

    IconData? medalha;
    Color? corMedalha;
    if (index == 0) {
      medalha = Icons.emoji_events;
      corMedalha = Colors.amber[600];
    } else if (index == 1) {
      medalha = Icons.emoji_events;
      corMedalha = Colors.grey[400];
    } else if (index == 2) {
      medalha = Icons.emoji_events;
      corMedalha = Colors.brown[400];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: souEu ? 4 : 1,
      color: souEu ? Colors.green[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: souEu ? BorderSide(color: Colors.green[400]!, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: souEu ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PerfilPublicoScreen(
                userId: item['id_usuario'],
                nome: nome,
                username: nomeUsuario,
                pontos: pontos,
                avatarUrl: item['avatar_url'],
              ),
            ),
          );
        },
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isPodium
                ? Icon(medalha, color: corMedalha, size: 28)
                : Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.bone,
              backgroundImage: item['avatar_url'] != null ? NetworkImage(item['avatar_url']) : null,
              child: item['avatar_url'] == null
                  ? Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.kombuGreen),
                    )
                  : null,
            ),
          ],
        ),
        title: Text(
          nome,
          style: GoogleFonts.raleway(
            fontWeight: souEu ? FontWeight.bold : FontWeight.w600,
            color: souEu ? Colors.green[800] : Colors.black87,
          ),
        ),
        subtitle: Text(
          '@$nomeUsuario${souEu ? ' (Você)' : ''}',
          style: TextStyle(
            color: souEu ? Colors.green[600] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Text(
          '$pontos pts',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isPodium ? corMedalha : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
