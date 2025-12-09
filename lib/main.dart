// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// AuthGate will decide whether to show SignIn or Home based on auth state.
// Make sure this file exists: lib/widgets/auth_gate.dart
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (must be added to flutter assets in pubspec.yaml)
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  // Safety check — prevents confusing startup errors later
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
  }

  // Optional debug prints (remove in production)
  debugPrint('SUPABASE_URL=${supabaseUrl.substring(0, supabaseUrl.length.clamp(0, 60))}'); // short print

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF7B9DFF);
    return MaterialApp(
      title: 'HappBit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: color),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // AuthGate will show SignInPage when not signed in, otherwise HomePage
      home: const AuthGate(),
      // Optional named routes if you want them elsewhere
      routes: {
        // '/sign-in': (_) => const SignInPage(),
        // '/sign-up': (_) => const SignUpPage(),
        // '/home': (_) => const HomePage(),
      },
    );
  }
}
