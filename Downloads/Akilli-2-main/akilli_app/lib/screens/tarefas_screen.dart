import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nova_tarefa_screen.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({Key? key}) : super(key: key);

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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () {
                // Poderia ser ação de Perfil ou Sair
                Navigator.pop(context);
              },
              child: const Text("Sair"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NovaTarefaScreen()),
                );
              },
              child: const Text("Nova Tarefa"),
            ),
            const SizedBox(height: 40),

            // Quadro de Tarefas (TASKS-BOARD)
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
            ),
          ],
        ),
      ),
    );
  }
}
