import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Step 1: email — Step 2: code + new password
  int _step = 1;

  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Request a reset token ─────────────────────────────────────────
  Future<void> _requestReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Veuillez entrer une adresse e-mail valide.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post('/api/auth/forgot-password', {'email': email});
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _step = 2;
          _successMessage = 'Un code de réinitialisation a été transmis à votre administrateur. Entrez-le ci-dessous.';
        });
        // Transition
        _animCtrl.reset();
        _animCtrl.forward();
      } else {
        setState(() => _errorMessage = body['detail'] ?? 'Une erreur est survenue.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de contacter le serveur. Vérifiez votre connexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Step 2: Confirm new password with token ────────────────────────────────
  Future<void> _confirmReset() async {
    final token = _tokenCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (token.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer le code de réinitialisation.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post('/api/auth/reset-password', {
        'token': token,
        'new_password': pass,
      });
      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        // Show success then go to login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mot de passe mis à jour',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                  child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = body['detail'] ?? 'Code invalide ou expiré.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de contacter le serveur. Vérifiez votre connexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? size.width * 0.15 : 24.0,
              vertical: 24.0,
            ),
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => _step == 1 ? context.go('/login') : setState(() {
                        _step = 1;
                        _errorMessage = null;
                        _successMessage = null;
                        _animCtrl.reset();
                        _animCtrl.forward();
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
                      ),
                      child: Icon(
                        _step == 1 ? Icons.lock_reset_rounded : Icons.vpn_key_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _step == 1 ? 'Mot de passe oublié ?' : 'Nouveau mot de passe',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'Entrez votre adresse e-mail. Votre administrateur vous communiquera un code de réinitialisation.'
                        : 'Entrez le code reçu de votre administrateur, puis choisissez votre nouveau mot de passe.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(1),
                      const SizedBox(width: 8),
                      _buildStepDot(2),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Success Banner
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.success, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: AppColors.success, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── STEP 1: Email Input ──────────────────────────────────────
                  if (_step == 1) ...[
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Adresse e-mail',
                      hint: 'votre@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _requestReset,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Envoyer la demande',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],

                  // ── STEP 2: Token + New Password ─────────────────────────────
                  if (_step == 2) ...[
                    _buildField(
                      controller: _tokenCtrl,
                      label: 'Code de réinitialisation',
                      hint: 'Code communiqué par votre admin',
                      icon: Icons.pin_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passCtrl,
                      label: 'Nouveau mot de passe',
                      hint: 'Au moins 6 caractères',
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPassCtrl,
                      label: 'Confirmer le mot de passe',
                      hint: 'Retapez le même mot de passe',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _confirmReset,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Réinitialiser le mot de passe',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Link back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Vous vous souvenez ? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = _step >= step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF4A5D4C), size: 18),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF4A5D4C), fontSize: 13),
      hintStyle: TextStyle(color: const Color(0xFF4A5D4C).withOpacity(0.5), fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _fieldDeco(label, hint, icon),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _fieldDeco(label, hint, Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF4A5D4C),
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
