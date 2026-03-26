import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  final AkilliApiService _apiService = AkilliApiService();
  bool _isLoading = false;

  Future<void> _fazerCadastro() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.cadastrarUsuario({
      'nome': _nomeController.text,
      'usuario': _usuarioController.text,
      'email': _emailController.text,
      'senha': _senhaController.text,
      'confirmacao_senha': _senhaController.text,
      'telefone': _telefoneController.text,
    });

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login.')),
        );
        Navigator.pop(context); // Volta pro login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no cadastro. Usuário ou e-mail pode já existir.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _usuarioController, decoration: const InputDecoration(labelText: 'Usuário', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: _senhaController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fazerCadastro,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Cadastrar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
