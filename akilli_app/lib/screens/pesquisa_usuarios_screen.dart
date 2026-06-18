import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import 'perfil_publico_screen.dart';

class PesquisaUsuariosScreen extends StatefulWidget {
  const PesquisaUsuariosScreen({Key? key}) : super(key: key);

  @override
  State<PesquisaUsuariosScreen> createState() => _PesquisaUsuariosScreenState();
}

class _PesquisaUsuariosScreenState extends State<PesquisaUsuariosScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _resultados = [];
  bool _isLoading = false;

  Future<void> _buscar() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _resultados = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final dados = await _supabaseService.buscarUsuarios(query);

    setState(() {
      _resultados = dados;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Encontrar Pessoas',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.kombuGreen,
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquise por @username ou nome...',
                prefixIcon: const Icon(Icons.search, color: AppColors.mossGreen),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.mossGreen),
                  onPressed: () {
                    _searchController.clear();
                    _buscar();
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              onChanged: (_) {
                // Opcional: _buscar() a cada letra (pode consumir muito BD)
              },
            ),
          ),
          
          // Resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.kombuGreen))
                : _resultados.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Digite algo para buscar.'
                              : 'Nenhum usuário encontrado.',
                          style: GoogleFonts.raleway(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _resultados.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _resultados[index];
                          final nome = user['nome'] ?? 'Usuário';
                          final username = user['usuario'] ?? '';
                          final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.kombuGreen,
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      inicial,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(nome, style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                            subtitle: Text('@$username'),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PerfilPublicoScreen(
                                    userId: user['id_usuario'],
                                    nome: nome,
                                    username: username,
                                    pontos: user['pontos'] ?? 0,
                                    avatarUrl: user['avatar_url'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
