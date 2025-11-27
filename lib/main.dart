// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception("Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HappBit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 123, 147, 255),
        ),
      ),
      home: const MyHomePage(title: 'HappBit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SupabaseClient client = Supabase.instance.client;
  bool loading = false;

  Future<void> generateDummyData() async {
    setState(() => loading = true);

    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception("No user logged in. Please sign in first.");
      }

      final uid = user.id;

      // 1️⃣ Upsert profile — V2: return value directly
      await client.from('profiles').upsert({
        'id': uid,
        'display_name': 'HappBit User',
        'timezone': 'Asia/Jakarta',
      });

      // 2️⃣ Insert habits (must call .select())
      final habits = await client.from('habits').insert([
        {
          'user_id': uid,
          'title': 'Drink Water',
          'description': 'Stay hydrated.',
          'icon': 'water',
          'color': '#4DB6AC',
          'frequency': {'type': 'daily'},
          'goal': 8,
        },
        {
          'user_id': uid,
          'title': 'Meditate',
          'description': 'Calm your mind.',
          'icon': 'meditation',
          'color': '#FF8A65',
          'frequency': {'type': 'daily'},
          'goal': 1,
        },
        {
          'user_id': uid,
          'title': 'Workout',
          'description': 'Gym or home workout.',
          'icon': 'dumbbell',
          'color': '#9575CD',
          'frequency': {
            'type': 'weekly',
            'days': [1, 3, 5],
          },
          'goal': 1,
        },
      ]).select();

      final drinkWaterId = habits[0]['id'] as String;
      final meditateId = habits[1]['id'] as String;
      final workoutId = habits[2]['id'] as String;

      // 3️⃣ Insert habit_instances
      await client.from('habit_instances').insert([
        {
          'habit_id': drinkWaterId,
          'user_id': uid,
          'occured_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        },
        {
          'habit_id': drinkWaterId,
          'user_id': uid,
          'occured_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
        },
        {
          'habit_id': meditateId,
          'user_id': uid,
          'occured_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
      ]);

      // 4️⃣ Insert reminders
      await client.from('reminders').insert([
        {
          'habit_id': drinkWaterId,
          'user_id': uid,
          'time': '08:00:00',
          'enabled': true,
        },
        {
          'habit_id': meditateId,
          'user_id': uid,
          'time': '07:30:00',
          'enabled': true,
          'repeat': {
            'mon': true,
            'tue': true,
            'wed': true,
            'thu': true,
            'fri': true,
          },
        },
        {
          'habit_id': workoutId,
          'user_id': uid,
          'time': '18:00:00',
          'enabled': true,
          'repeat': {'mon': true, 'wed': true, 'fri': true},
        },
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dummy data generated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = client.auth.currentUser?.id ?? "(not signed in)";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged-in user: $userId"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : generateDummyData,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Generate Dummy Data"),
            ),
          ],
        ),
      ),
    );
  }
}
