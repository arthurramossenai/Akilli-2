import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({Key? key}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _usuarioController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  bool _isSaving = false;
  String? _avatarUrl;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = _supabaseService.usuarioLogado;
    _nomeController = TextEditingController(text: user?.nome ?? '');
    _usuarioController = TextEditingController(text: user?.usuario ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _telefoneController = TextEditingController(text: user?.telefone ?? '');
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _usuarioController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao selecionar imagem')));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    // Faz o upload da imagem se houver uma nova
    if (_selectedImage != null) {
      final ext = _selectedImage!.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final newUrl = await _supabaseService.uploadAvatar(_selectedImage!.path, fileName);
      if (newUrl != null) {
        _avatarUrl = newUrl;
      }
    }

    final sucesso = await _supabaseService.atualizarPerfil(
      nome: _nomeController.text.trim(),
      usuario: _usuarioController.text.trim(),
      email: _emailController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso! ✅'),
            backgroundColor: AppColors.kombuGreen,
          ),
        );
        Navigator.pop(context, true); // retorna true para indicar que houve mudança
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar perfil. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.kombuGreen,
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
                        child: (_selectedImage == null && _avatarUrl == null)
                            ? Text(
                                _nomeController.text.isNotEmpty
                                    ? _nomeController.text[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.raleway(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.tan,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: AppColors.kombuGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toque para alterar a foto',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),

              const SizedBox(height: 32),

              // Campo Nome
              Text('Nome', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration('Seu nome completo', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // Campo Usuário
              Text('Usuário', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usuarioController,
                decoration: _inputDecoration('@seuusuario', Icons.alternate_email),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu usuário' : null,
              ),

              const SizedBox(height: 20),

              // Campo Email
              Text('E-mail', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('seu@email.com', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Campo Telefone
              Text('Telefone', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _telefoneController,
                decoration: _inputDecoration('(71) 99999-9999', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 36),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kombuGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          'Salvar Alterações',
                          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.mossGreen),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kombuGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
