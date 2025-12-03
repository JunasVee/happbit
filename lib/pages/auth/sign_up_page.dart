// lib/pages/auth/sign_up_page.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // <-- display name input
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final displayName = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name, email and password')));
      setState(() => _loading = false);
      return;
    }

    try {
      final user = await _auth.signUp(email, pass);
      // If user is returned immediately, create profile with display_name + email
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'display_name': displayName,
          'email': email,
          'timezone': 'Asia/Jakarta',
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed up and signed in.')));
        Navigator.of(context).pop();
      } else {
        // No user returned -> likely email confirmation required
        // We still create a profiles row tied to auth only AFTER the user confirms (or create a temporary row)
        // Safer approach: create a profile row immediately using a random uuid? Avoid that — instead instruct user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful. Please check your email to confirm your account.')),
        );
        // Optionally: try signInWithPassword here; many projects don't allow immediate sign-in before confirm.
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator() : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
