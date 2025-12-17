// lib/debug/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});
  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final AuthService _auth = AuthService();
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = false;

  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passCtl = TextEditingController();

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await _auth.signUp(_emailCtl.text.trim(), _passCtl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up success — check email if required')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SignUp error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await _auth.signIn(_emailCtl.text.trim(), _passCtl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in')),
      );

      // update UI
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SignIn error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateDummyData() async {
    setState(() => _loading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not signed in.');

      final uid = user.id;

      // Upsert profile
      await _client.from('profiles').upsert({
        'id': uid,
        'display_name': 'HappBit User',
        'timezone': 'Asia/Jakarta',
      });

      if (!mounted) return;

      // Insert sample habits
      final inserted = await _client.from('habits').insert([
        {
          'user_id': uid,
          'title': 'Drink Water',
          'frequency': {'type': 'daily'},
          'goal': 8,
        },
        {
          'user_id': uid,
          'title': 'Meditate',
          'frequency': {'type': 'daily'},
          'goal': 1,
        },
      ]).select();

      if (!mounted) return;

      final drinkWaterId = inserted[0]['id'] as String;

      // Insert one instance
      await _client.from('habit_instances').insert([
        {
          'habit_id': drinkWaterId,
          'user_id': uid,
          'occured_at': DateTime.now().toUtc().toIso8601String(),
        }
      ]);

      if (!mounted) return;

      // Insert reminder example
      await _client.from('reminders').insert([
        {
          'habit_id': drinkWaterId,
          'user_id': uid,
          'time': '08:00:00',
          'enabled': true,
        }
      ]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dummy data inserted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final uid = user?.id ?? '(not signed in)';

    return Scaffold(
      appBar: AppBar(title: const Text('Debug / Dev Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Current user: $uid'),
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: const Text('Sign In'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _generateDummyData,
                  child: const Text('Generate Dummy'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      await _auth.signOut();
                      if (!mounted) return;
                      setState(() {});
                    },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
