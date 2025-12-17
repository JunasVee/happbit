// lib/pages/auth/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _auth = AuthService();
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _obscure = true;

  String? _errorMessage; // NEW: inline error message

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null); // clear old errors

    final email = _emailCtl.text.trim();
    final password = _passCtl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter email and password.");
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔐 Attempt login
      final user = await _auth.signIn(email, password);

      // Ensure profile exists and email is stored
      final existing = await _supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      final displayName = existing?['display_name'] ?? '';

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
        'timezone': 'Asia/Jakarta',
      });
    } catch (e) {
      debugPrint("Sign-in error: $e");

      // ❗ Always generic message
      setState(() => _errorMessage = "Invalid email or password.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),

                            /// Title
                            Text(
                              'HappBit',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome back — sign in to continue',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 28),

                            /// Inputs + Button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Column(
                                children: [
                                  _FloatingTextField(
                                    controller: _emailCtl,
                                    label: 'Email',
                                    prefix: const Icon(Icons.email_outlined),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),

                                  _FloatingTextField(
                                    controller: _passCtl,
                                    label: 'Password',
                                    obscureText: _obscure,
                                    prefix: const Icon(Icons.lock_outline),
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),

                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 22),

                                  GradientButton(
                                    text: _loading
                                        ? 'Signing in...'
                                        : 'Sign In',
                                    loading: _loading,
                                    onPressed: _loading ? null : _submit,
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Don't have an account?"),
                                      TextButton(
                                        onPressed: _goToSignUp,
                                        child: const Text('Sign Up'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// Floating text field widget
/// ------------------------------
class _FloatingTextField extends StatelessWidget {
  const _FloatingTextField({
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.95),
          prefixIcon: prefix,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF5C7CFF), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// Gradient Button
/// ------------------------------
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 52,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(14));

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B9DFF), Color(0xFF5C7CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
