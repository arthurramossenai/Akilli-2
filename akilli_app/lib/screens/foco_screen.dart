import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sessao_foco.dart';
import '../services/supabase_service.dart';

class FocoScreen extends StatefulWidget {
  const FocoScreen({Key? key}) : super(key: key);

  @override
  State<FocoScreen> createState() => _FocoScreenState();
}

class _FocoScreenState extends State<FocoScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // Estado do temporizador
  int _minutosEscolhidos = 25; // Padrão Pomodoro
  int _segundosRestantes = 25 * 60;
  bool _emAndamento = false;
  bool _pausado = false;
  Timer? _timer;
  DateTime? _inicioSessao;

  // Opções pré-definidas de tempo
  final List<int> _opcoesMinutos = [10, 15, 20, 25, 30, 45, 60, 90];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarTimer() {
    setState(() {
      _segundosRestantes = _minutosEscolhidos * 60;
      _emAndamento = true;
      _pausado = false;
      _inicioSessao = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        // Timer acabou! Sessão concluída com sucesso
        _timer?.cancel();
        _finalizarSessao(sucesso: true);
      }
    });
  }

  void _pausarTimer() {
    _timer?.cancel();
    setState(() {
      _pausado = true;
    });
  }

  void _retomarTimer() {
    setState(() {
      _pausado = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        _timer?.cancel();
        _finalizarSessao(sucesso: true);
      }
    });
  }

  void _desistirTimer() {
    _timer?.cancel();
    _finalizarSessao(sucesso: false);
  }

  Future<void> _finalizarSessao({required bool sucesso}) async {
    DateTime fimSessao = DateTime.now();

    // Calcula minutos efetivamente focados
    int minutosReais = _inicioSessao != null
        ? fimSessao.difference(_inicioSessao!).inMinutes
        : 0;
    if (minutosReais < 1) minutosReais = 1;

    // Calcula pontos: 1 ponto por minuto focado (só se completou)
    int pontos = sucesso ? _minutosEscolhidos : 0;

    SessaoFoco sessao = SessaoFoco(
      inicioSessao: _inicioSessao ?? fimSessao,
      fimSessao: fimSessao,
      duracaoMinutos: sucesso ? _minutosEscolhidos : minutosReais,
      statusSessao: sucesso ? 'Sucesso' : 'Falha',
      pontosGanhos: pontos,
    );

    bool salvo = await _supabaseService.salvarSessaoFoco(sessao);

    setState(() {
      _emAndamento = false;
      _pausado = false;
      _segundosRestantes = _minutosEscolhidos * 60;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                sucesso ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: sucesso ? Colors.amber : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(sucesso ? 'Parabéns!' : 'Sessão encerrada'),
            ],
          ),
          content: Text(
            sucesso
                ? 'Você completou $_minutosEscolhidos minutos focado e ganhou $pontos pontos! 🎉'
                : 'Você desistiu após $minutosReais minutos. Tente novamente!',
            style: GoogleFonts.raleway(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _formatarTempo(int totalSegundos) {
    int minutos = totalSegundos ~/ 60;
    int segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progresso = _emAndamento
        ? 1.0 - (_segundosRestantes / (_minutosEscolhidos * 60))
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Modo Foco",
            style: GoogleFonts.raleway(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _emAndamento
                ? "Mantenha o foco! Não saia do app."
                : "Escolha o tempo e inicie sua sessão de foco.",
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Timer circular
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anel de progresso
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progresso,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _emAndamento ? Colors.green[600]! : Colors.grey[400]!,
                    ),
                  ),
                ),
                // Tempo no centro
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatarTempo(_segundosRestantes),
                      style: GoogleFonts.raleway(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _emAndamento ? Colors.green[700] : Colors.black87,
                      ),
                    ),
                    if (_emAndamento && _pausado)
                      Text(
                        "PAUSADO",
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Seletor de tempo (só aparece quando NÃO está em andamento)
          if (!_emAndamento) ...[
            Text(
              "Duração da sessão",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _opcoesMinutos.map((minutos) {
                bool selecionado = _minutosEscolhidos == minutos;
                return ChoiceChip(
                  label: Text('${minutos}m'),
                  selected: selecionado,
                  selectedColor: Colors.green[600],
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _minutosEscolhidos = minutos;
                      _segundosRestantes = minutos * 60;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Botões de ação
          if (!_emAndamento)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _iniciarTimer,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  "Iniciar Foco",
                  style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _pausado ? _retomarTimer : _pausarTimer,
                      icon: Icon(_pausado ? Icons.play_arrow : Icons.pause, size: 24),
                      label: Text(
                        _pausado ? "Retomar" : "Pausar",
                        style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _desistirTimer,
                      icon: const Icon(Icons.stop, size: 24),
                      label: Text(
                        "Desistir",
                        style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Info de pontos
          if (!_emAndamento)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Você ganha 1 ponto por minuto focado ao completar a sessão inteira. Desistir não dá pontos!",
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.green[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
