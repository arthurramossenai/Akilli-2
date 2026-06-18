import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_colors.dart';
import '../widgets/akilli_logo.dart';
import '../services/supabase_service.dart';
import 'main_tabs_screen.dart';

/// Tela unificada de Login + Registro com animações fluidas.
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ─── Controle de abas ─────────────────────────────────────────────
  bool _isLogin = true;

  // ─── Controllers de texto ─────────────────────────────────────────
  final _nomeController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();

  // ─── Estado ───────────────────────────────────────────────────────
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmSenha = true;
  
  // ─── Validação de Username ────────────────────────────────────────
  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameValid; // null = vazio, true = válido, false = já existe
  List<String> _usernameSuggestions = [];

  final SupabaseService _supabaseService = SupabaseService();

  // ─── Animação do toggle (indicador ativo deslizante) ──────────────
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOutCubic,
    );

    // Adiciona listener para formatar e validar o username enquanto digita
    _usuarioController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    String text = _usuarioController.text;
    
    // Filtra para remover espaços, acentos, letras maiúsculas. (Apenas a-z, 0-9, ., _)
    String filtered = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\._]'), '');
    
    if (filtered != text) {
      _usuarioController.value = TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
      return;
    }

    if (filtered.isEmpty) {
      setState(() {
        _isUsernameValid = null;
        _isCheckingUsername = false;
        _usernameSuggestions.clear();
      });
      return;
    }

    // Debounce para checar no banco
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();
    setState(() {
      _isCheckingUsername = true;
      _isUsernameValid = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      bool exists = await _supabaseService.checkUsernameExists(filtered);
      
      if (!mounted) return;

      if (exists) {
        // Gera sugestões
        List<String> suggestions = [
          '${filtered}12',
          '${filtered}_',
          '${filtered}4',
        ];
        setState(() {
          _isUsernameValid = false;
          _usernameSuggestions = suggestions;
          _isCheckingUsername = false;
        });
      } else {
        setState(() {
          _isUsernameValid = true;
          _usernameSuggestions.clear();
          _isCheckingUsername = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _nomeController.dispose();
    _usuarioController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _switchToLogin() {
    if (!_isLogin) {
      _toggleController.reverse();
      setState(() => _isLogin = true);
    }
  }

  void _switchToRegister() {
    if (_isLogin) {
      _toggleController.forward();
      setState(() => _isLogin = false);
    }
  }

  // ─── Ações ────────────────────────────────────────────────────────

  Future<void> _fazerLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _senhaController.text.trim().isEmpty) {
      _showSnack('Preencha todos os campos.');
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showSnack('Sem conexão com a internet. Verifique seu Wi-Fi ou dados móveis.');
      return;
    }

    setState(() => _isLoading = true);

    final usuario = await _supabaseService.login(
      _emailController.text.trim(),
      _senhaController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (usuario != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainTabsScreen()),
      );
    } else if (mounted) {
      final erro = _supabaseService.lastError ?? '';
      if (erro.toLowerCase().contains('email not confirmed') || erro.toLowerCase().contains('email_not_confirmed')) {
        _showSnack('⚠️ E-mail ainda não confirmado. Verifique sua caixa de entrada e clique no link enviado.');
      } else {
        _showSnack('Falha no login. Verifique seu e-mail e senha.');
      }
    }
  }

  Future<void> _fazerCadastro() async {
    if (_nomeController.text.trim().isEmpty ||
        _usuarioController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _senhaController.text.trim().isEmpty ||
        _confirmSenhaController.text.trim().isEmpty) {
      _showSnack('Preencha todos os campos.');
      return;
    }

    if (_isUsernameValid == false) {
      _showSnack('Este usuário já existe. Escolha outro.');
      return;
    }

    if (_senhaController.text != _confirmSenhaController.text) {
      _showSnack('As senhas não coincidem.');
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showSnack('Sem conexão com a internet. Verifique seu Wi-Fi ou dados móveis.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await _supabaseService.cadastrarUsuario({
      'nome': _nomeController.text.trim(),
      'usuario': _usuarioController.text.trim(),
      'email': _emailController.text.trim(),
      'senha': _senhaController.text.trim(),
      'confirmacao_senha': _confirmSenhaController.text.trim(),
      'telefone': '',
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        // Tenta login automático (funciona se confirmação estiver desabilitada no Supabase)
        final usuario = await _supabaseService.login(
          _emailController.text.trim(),
          _senhaController.text.trim(),
        );

        if (usuario != null && mounted) {
          // Confirmação desabilitada: entra direto no app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainTabsScreen()),
          );
        } else if (mounted) {
          // Confirmação habilitada: pede para checar o email
          _showSnack('✅ Cadastro realizado! Verifique seu e-mail para ativar a conta e depois faça login.');
          _switchToLogin();
          _emailController.clear();
          _senhaController.clear();
          _nomeController.clear();
          _usuarioController.clear();
          _confirmSenhaController.clear();
        }
      } else {
        final erro = _supabaseService.lastError ?? 'Erro desconhecido';
        _showSnack('Falha: $erro');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.kombuGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header com logo ──────────────────────────────────────
            _buildHeader(screenHeight),

            // ── Formulário ───────────────────────────────────────────
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  /// Cabeçalho com fundo Bone + logo + curva decorativa
  Widget _buildHeader(double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.28,
      child: Stack(
        children: [
          // Fundo bege
          Positioned.fill(
            child: Container(color: AppColors.bone),
          ),
          // Curva decorativa no canto superior esquerdo (triângulo escuro)
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: const Size(60, 80),
              painter: _CornerTrianglePainter(
                color: AppColors.darkBackground,
              ),
            ),
          ),
          // Curva inferior direita (a onda que corta entre bege e verde escuro)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 60),
              painter: _BottomCurvePainter(
                color: AppColors.darkBackground,
              ),
            ),
          ),
          // Logo centralizado
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AkilliLogo(
                size: 100,
                color: AppColors.logoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção do formulário com toggle + campos animados
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toggle Segmented Control ─────────────────────────────
          _buildToggle(),

          const SizedBox(height: 24),

          // ── Campos com animação de layout ────────────────────────
          _buildAnimatedFields(),

          const SizedBox(height: 16),

          // ── Remember me toggle ──────────────────────────────────
          _buildRememberMe(),

          const SizedBox(height: 20),

          // ── Botão principal ─────────────────────────────────────
          _buildMainButton(),

          const SizedBox(height: 28),

          // ── Login social ───────────────────────────────────────
          _buildSocialLogin(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Toggle pílula segmentada com animação de deslizamento
  Widget _buildToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.toggleInactive,
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Indicador deslizante — usa AnimatedBuilder do Flutter
              AnimatedBuilder(
                animation: _toggleAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: _toggleAnimation.value * halfWidth,
                    top: 3,
                    bottom: 3,
                    width: halfWidth - 4,
                    child: Container(
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: AppColors.toggleActive,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _switchToLogin,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLogin
                                ? AppColors.darkText
                                : AppColors.lightText.withValues(alpha: 0.7),
                          ),
                          child: const Text('Entrar'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _switchToRegister,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !_isLogin
                                ? AppColors.darkText
                                : AppColors.lightText.withValues(alpha: 0.7),
                          ),
                          child: const Text('Registrar'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Campos do formulário com animação de collapse/expand
  Widget _buildAnimatedFields() {
    return Column(
      children: [
        // Campo Nome — só aparece no registro
        _AnimatedCollapseField(
          visible: !_isLogin,
          child: _buildTextField(
            controller: _nomeController,
            hint: 'Nome',
          ),
        ),

        // Campo Usuário com checagem — só aparece no registro
        _AnimatedCollapseField(
          visible: !_isLogin,
          child: _buildUsernameField(),
        ),

        // E-mail — sempre visível
        _buildTextField(
          controller: _emailController,
          hint: 'E-mail',
          keyboardType: TextInputType.emailAddress,
        ),

        // Senha — sempre visível
        _buildTextField(
          controller: _senhaController,
          hint: 'Senha',
          obscure: _obscureSenha,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSenha
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.mossGreen,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
          ),
        ),

        // Confirmar Senha — só aparece no registro
        _AnimatedCollapseField(
          visible: !_isLogin,
          child: _buildTextField(
            controller: _confirmSenhaController,
            hint: 'Confirmar senha',
            obscure: _obscureConfirmSenha,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.mossGreen,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirmSenha = !_obscureConfirmSenha),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo Username customizado para live check
  Widget _buildUsernameField() {
    Widget? suffixIcon;
    if (_isCheckingUsername) {
      suffixIcon = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tan),
        ),
      );
    } else if (_isUsernameValid == true) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.kombuGreen, size: 20);
    } else if (_isUsernameValid == false) {
      suffixIcon = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _usuarioController,
          hint: 'Nome de usuário',
          suffixIcon: suffixIcon,
        ),
        // Sugestões se o usuário já existir
        if (_isUsernameValid == false && _usernameSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              children: _usernameSuggestions.map((sug) {
                return ActionChip(
                  label: Text(sug, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.bone.withValues(alpha: 0.2),
                  onPressed: () {
                    _usuarioController.text = sug;
                    // O listener já vai rodar e validar novamente
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Constrói um campo de texto estilizado conforme o design
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: GoogleFonts.raleway(
              color: AppColors.lightText,
              fontSize: 16,
            ),
            cursorColor: AppColors.tan,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.raleway(
                color: AppColors.lightText.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.fieldDivider.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.tan,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              suffixIcon: suffixIcon,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Switch "Lembrar-se no próximo login"
  Widget _buildRememberMe() {
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 28,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: _rememberMe,
              onChanged: (v) => setState(() => _rememberMe = v),
              activeColor: AppColors.bone,
              activeTrackColor: AppColors.switchActiveTrack,
              inactiveThumbColor: AppColors.bone,
              inactiveTrackColor: AppColors.switchInactiveTrack,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Lembrar-se no próximo login',
          style: GoogleFonts.raleway(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Botão "Fazer Login" / "Registrar"
  Widget _buildMainButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_isLogin ? _fazerLogin : _fazerCadastro),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: AppColors.buttonBackground.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.raleway(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.buttonText,
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isLogin ? 'Fazer Login' : 'Registrar',
                  key: ValueKey(_isLogin),
                ),
              ),
      ),
    );
  }

  /// Login social (Google + Facebook) — sem integração por enquanto
  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Entrar com',
          style: GoogleFonts.raleway(
            color: AppColors.lightText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        // Google
        _socialButton(
          onTap: () => _showSnack('Login com Google em breve!'),
          child: _buildGoogleIcon(),
        ),
        const SizedBox(width: 12),
        // Facebook
        _socialButton(
          onTap: () => _showSnack('Login com Facebook em breve!'),
          child: const Icon(
            Icons.facebook,
            color: Color(0xFF1877F2),
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  /// Ícone do Google com as 4 cores do logo
  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Animated Collapse Field — campo que encolhe/expande suavemente
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedCollapseField extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _AnimatedCollapseField({
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1.0 : 0.0,
        child: visible ? child : const SizedBox.shrink(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Painters auxiliares
// ══════════════════════════════════════════════════════════════════════════════

/// Triângulo no canto superior esquerdo
class _CornerTrianglePainter extends CustomPainter {
  final Color color;
  _CornerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Curva inferior que cria a transição entre header bege e corpo escuro
class _BottomCurvePainter extends CustomPainter {
  final Color color;
  _BottomCurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 1.2,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo do Google com as 4 cores oficiais
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double cx = w / 2;
    final double cy = w / 2;
    final double r = w * 0.45;
    final double strokeW = w * 0.18;

    // Arco azul (parte direita)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.6,
      1.8,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt,
    );

    // Arco verde (parte inferior)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.2,
      1.2,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt,
    );

    // Arco amarelo (parte esquerda)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.4,
      1.0,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt,
    );

    // Arco vermelho (parte superior)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.4,
      1.55,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt,
    );

    // Barra horizontal do G
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - w * 0.08, r + w * 0.04, w * 0.16),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
