// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (must be added to flutter assets in pubspec.yaml)
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HappBit (Dev)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 123, 147, 255),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;

  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passCtl = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _habits = [];

  @override
  void initState() {
    super.initState();
    // listen to auth changes so UI refreshes automatically
    _authSub = client.auth.onAuthStateChange.listen((event) {
      if (mounted) {
        setState(() {});
        _loadHabitsIfSignedIn();
      }
    });

    _loadHabitsIfSignedIn();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _loadHabitsIfSignedIn() async {
    final user = client.auth.currentUser;
    if (user != null) {
      await fetchHabits();
    } else {
      setState(() => _habits = []);
    }
  }

  // ---------------------------
  // AUTH: Improved signUp logic
  // ---------------------------
  Future<void> _signUp() async {
    setState(() => _loading = true);
    final email = _emailCtl.text.trim();
    final password = _passCtl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      setState(() => _loading = false);
      return;
    }

    try {
      debugPrint('Attempting signUp for $email');

      // 1) Try sign up
      final signUpRes = await client.auth.signUp(email: email, password: password);
      debugPrint('signUpRes: user=${signUpRes.user}, session=${signUpRes.session}');

      // If user returned immediately (email confirm disabled), create profile & finish
      if (signUpRes.user != null) {
        final user = signUpRes.user!;
        await _ensureProfileExists(user.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up successful and signed in.')));
        await fetchHabits();
        return;
      }

      // signUpRes.user == null -> likely email confirmation required OR server didn't create session.
      // Try to sign in immediately (some Supabase projects allow direct sign-in).
      try {
        final signInRes = await client.auth.signInWithPassword(email: email, password: password);
        debugPrint('signIn after signup attempt: user=${signInRes.user}, session=${signInRes.session}');

        if (signInRes.user != null) {
          // signed in successfully
          await _ensureProfileExists(signInRes.user!.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in after sign up.')));
          await fetchHabits();
          return;
        } else {
          // not signed in; inform user to check email verification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-up created. Please check your email to confirm your account.')),
          );
          return;
        }
      } catch (signInErr) {
        // signIn failed (likely email confirmation required). Inform user clearly.
        debugPrint('signIn after signUp failed: $signInErr');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up created. Please check your email to confirm your account.')),
        );
        return;
      }
    } catch (e, st) {
      debugPrint('Sign up error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------
  // SIGN IN
  // ---------------------------
  Future<void> _signIn() async {
    setState(() => _loading = true);
    final email = _emailCtl.text.trim();
    final password = _passCtl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      debugPrint('signIn res: user=${res.user}, session=${res.session}');
      if (res.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in did not return a user. Check email confirmation.')));
      } else {
        await _ensureProfileExists(res.user!.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in successfully.')));
        await fetchHabits();
      }
    } catch (e, st) {
      debugPrint('Sign in error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await client.auth.signOut();
    if (mounted) {
      setState(() {
        _habits = [];
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out.')));
  }

  // Ensure profile exists (safe when RLS disabled; when enabled you need policies)
  Future<void> _ensureProfileExists(String userId) async {
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'display_name': 'HappBit User',
        'timezone': 'Asia/Jakarta',
      });
    } catch (e) {
      // don't block user if this fails, just print for debugging
      debugPrint('_ensureProfileExists error: $e');
    }
  }

  // ---------------------------
  // Data functions
  // ---------------------------
  Future<void> fetchHabits() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await client.from('habits').select().eq('user_id', user.id).order('created_at', ascending: false);
      if (res == null) {
        setState(() => _habits = []);
      } else {
        final list = List<Map<String, dynamic>>.from(res as List<dynamic>);
        setState(() => _habits = list);
      }
    } catch (e) {
      debugPrint('fetchHabits error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading habits: $e')));
    }
  }

  Future<void> markHabitDone(String habitId) async {
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }
    try {
      await client.from('habit_instances').insert({
        'habit_id': habitId,
        'user_id': user.id,
        'occured_at': DateTime.now().toUtc().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked done')));
      await fetchHabits();
    } catch (e) {
      debugPrint('markHabitDone error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error marking done: $e')));
    }
  }

  Future<void> _generateDummyData() async {
    setState(() => _loading = true);
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in first to seed data')));
      setState(() => _loading = false);
      return;
    }
    try {
      await _ensureProfileExists(user.id);

      final habits = await client.from('habits').insert([
        {
          'user_id': user.id,
          'title': 'Drink Water',
          'description': 'Stay hydrated.',
          'icon': 'water',
          'color': '#4DB6AC',
          'frequency': {'type': 'daily'},
          'goal': 8,
        },
        {
          'user_id': user.id,
          'title': 'Meditate',
          'description': 'Calm your mind.',
          'icon': 'meditation',
          'color': '#FF8A65',
          'frequency': {'type': 'daily'},
          'goal': 1,
        },
      ]).select();

      if (habits != null && (habits as List).isNotEmpty) {
        final firstId = habits[0]['id'] as String;
        await client.from('habit_instances').insert([
          {
            'habit_id': firstId,
            'user_id': user.id,
            'occured_at': DateTime.now().toUtc().toIso8601String(),
          }
        ]);
        await client.from('reminders').insert([
          {
            'habit_id': firstId,
            'user_id': user.id,
            'time': '08:00:00',
            'enabled': true,
          }
        ]);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dummy data generated.')));
      await fetchHabits();
    } catch (e) {
      debugPrint('seed error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating dummy data: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final user = client.auth.currentUser;
    final userId = user?.id ?? '(not signed in)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HappBit - Dev'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Logged-in user: $userId'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
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
                  child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign Up'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: const Text('Sign In'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signOut,
                  child: const Text('Sign Out'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _generateDummyData,
              child: _loading ? const CircularProgressIndicator() : const Text('Generate Dummy Data'),
            ),
            const SizedBox(height: 16),
            const Text('Your habits:'),
            const SizedBox(height: 8),
            _habits.isEmpty
                ? const Text('(no habits yet)')
                : Column(
                    children: _habits.map((h) {
                      final title = h['title'] ?? 'Untitled';
                      final id = h['id'] as String;
                      final desc = h['description'] ?? '';
                      final goal = h['goal'] ?? 1;
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(desc.toString()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Goal: $goal'),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: () => markHabitDone(id),
                                tooltip: 'Mark done',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            const Text(
              'Notes:\n• If inserts fail, ensure RLS is disabled for development or policies allow inserts.\n• Do not publish anon key publicly. Rotate keys if leaked.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
