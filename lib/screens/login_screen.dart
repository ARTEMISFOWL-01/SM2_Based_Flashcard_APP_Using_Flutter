import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _obscure = true;
  bool _isLogin = true;

  String? _emailError;
  String? _passError;
  String? _authError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _emailCtrl.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
      if (_authError != null) setState(() => _authError = null);
    });
    _passCtrl.addListener(() {
      if (_passError != null) setState(() => _passError = null);
      if (_authError != null) setState(() => _authError = null);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailErr;
    String? passErr;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailErr = 'Enter a valid email address';
    }

    if (pass.isEmpty) {
      passErr = 'Password is required';
    } else if (!_isLogin && pass.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    setState(() {
      _emailError = emailErr;
      _passError = passErr;
      _authError = null;
    });

    return emailErr == null && passErr == null;
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('network') || msg.contains('socketexception')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return e
        .toString()
        .replaceAll(RegExp(r'^AuthApiException\(message:\s*'), '')
        .replaceAll(RegExp(r',\s*statusCode.*$'), '')
        .replaceAll(')', '')
        .trim();
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        widget.onLoginSuccess();
      } else {
        await _supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (mounted) {
          setState(() {
            _isLogin = true;
            _authError = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Account created! Check your email to verify.')),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _authError = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.accentGlow, blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.bg, size: 30),
                ),

                const SizedBox(height: 32),

                // Heading
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _isLogin ? 'Welcome\nback.' : 'Create\naccount.',
                    key: ValueKey(_isLogin),
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isLogin ? 'Continue your learning journey.' : 'Start mastering anything today.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),

                const SizedBox(height: 36),

                // Auth error banner
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _authError != null
                      ? Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _authError!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.45),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _authError = null),
                                child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 15),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Email
                _FieldLabel('Email'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _emailCtrl,
                  hintText: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  error: _emailError,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),

                const SizedBox(height: 20),

                // Password
                _FieldLabel('Password'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _passCtrl,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  error: _passError,
                  onSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.bg,
                      disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.bg),
                          )
                        : Text(_isLogin ? 'Sign In' : 'Create Account'),
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _emailError = null;
                      _passError = null;
                      _authError = null;
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                          TextSpan(
                            text: _isLogin ? 'Sign up' : 'Sign in',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Field label ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

// ── Input field with inline error ──────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? error;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.error,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon,
                color: hasError ? AppColors.danger : AppColors.textMuted,
                size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: hasError
                ? AppColors.danger.withValues(alpha: 0.06)
                : AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.cardBorder,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.accent,
                width: 1.5,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.danger, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        error!,
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
