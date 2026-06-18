import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class UsernameSetupDialog extends StatefulWidget {
  final SupabaseService supabaseService;

  const UsernameSetupDialog({Key? key, required this.supabaseService}) : super(key: key);

  @override
  State<UsernameSetupDialog> createState() => _UsernameSetupDialogState();
}

class _UsernameSetupDialogState extends State<UsernameSetupDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isChecking = false;
  bool? _isValid;
  bool _isSaving = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    String text = _controller.text;
    String filtered = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\._]'), '');
    
    if (filtered != text) {
      _controller.value = TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
      return;
    }

    if (filtered.isEmpty) {
      setState(() {
        _isValid = null;
        _isChecking = false;
        _suggestions.clear();
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _isChecking = true;
      _isValid = null;
    });

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      bool exists = await widget.supabaseService.checkUsernameExists(filtered);
      if (!mounted) return;

      if (exists) {
        setState(() {
          _isValid = false;
          _suggestions = ['${filtered}12', '${filtered}_', '${filtered}4'];
          _isChecking = false;
        });
      } else {
        setState(() {
          _isValid = true;
          _suggestions.clear();
          _isChecking = false;
        });
      }
    });
  }

  Future<void> _salvar() async {
    if (_isValid != true) return;
    
    setState(() => _isSaving = true);
    final user = widget.supabaseService.usuarioLogado;
    
    if (user != null) {
      bool success = await widget.supabaseService.atualizarPerfil(
        nome: user.nome,
        usuario: _controller.text,
        email: user.email,
        telefone: user.telefone,
      );
      
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar username.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon;
    if (_isChecking) {
      suffixIcon = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tan),
        ),
      );
    } else if (_isValid == true) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.kombuGreen, size: 20);
    } else if (_isValid == false) {
      suffixIcon = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Qual username você quer usar?', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vimos que você ainda não escolheu um nome de usuário único!'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'ex: arthursalvador',
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_isValid == false && _suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: _suggestions.map((sug) {
                  return ActionChip(
                    label: Text(sug, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.bone.withValues(alpha: 0.2),
                    onPressed: () {
                      _controller.text = sug;
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: (_isValid == true && !_isSaving) ? _salvar : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kombuGreen,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
