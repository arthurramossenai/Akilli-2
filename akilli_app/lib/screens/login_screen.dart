import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'tarefas_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _fazerLogin() async {
    setState(() {
      _isLoading = true;
    });

    final usuario = await _supabaseService.login(
      _emailController.text,
      _senhaController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (usuario != null) {
      if (mounted) {
        // Navega para a tela de tarefas (sem distinção admin por enquanto)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TarefasScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no login. Verifique suas credenciais.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Akili",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Mantenha o foco no que importa",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fazerLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Entrar"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CadastroScreen()),
                  );
                },
                child: const Text("Não tem uma conta? Cadastre-se"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
