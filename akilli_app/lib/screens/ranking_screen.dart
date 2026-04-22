import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _ranking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarRanking();
  }

  Future<void> _carregarRanking() async {
    setState(() => _isLoading = true);
    final dados = await _supabaseService.getRanking();
    setState(() {
      _ranking = dados;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = _supabaseService.usuarioLogado;
    final int meuspontos = usuarioLogado?.pontos ?? 0;

    return RefreshIndicator(
      onRefresh: _carregarRanking,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ranking",
              style: GoogleFonts.raleway(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Quem poupou mais tempo fora de apps de distração e somou mais tempo focado sobe no ranking!",
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Card com seus pontos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  const Icon(Icons.emoji_events, color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Seus Pontos",
                          style: GoogleFonts.raleway(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$meuspontos pts",
                          style: GoogleFonts.raleway(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lista do Ranking
            Text(
              "Ranking Global",
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_ranking.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.leaderboard, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "Nenhum jogador ainda.\nComplete sessões de foco para aparecer aqui!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(color: Colors.grey[500], height: 1.5),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ranking.length,
                itemBuilder: (context, index) {
                  final item = _ranking[index];
                  final String nome = item['nome'] ?? 'Anônimo';
                  final String nomeUsuario = item['usuario'] ?? '';
                  final int pontos = item['pontos'] ?? 0;
                  final bool souEu = item['id_usuario'] == usuarioLogado?.idUsuario;
                  final bool isPodium = index < 3;

                  // Ícones para o pódio
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
                      side: souEu
                          ? BorderSide(color: Colors.green[400]!, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: isPodium
                          ? Icon(medalha, color: corMedalha, size: 32)
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
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
                },
              ),
          ],
        ),
      ),
    );
  }
}
