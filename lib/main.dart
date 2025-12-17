// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/app_lock_controller.dart';
import 'services/app_settings.dart';
import 'widgets/app_controllers.dart';
import 'widgets/app_lock_overlay.dart';
// AuthGate will decide whether to show SignIn or Home based on auth state.
// Make sure this file exists: lib/widgets/auth_gate.dart
import 'widgets/auth_gate.dart';

// AnalyticsPage
import 'pages/analytics/analytics_page.dart';

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

  // Load local app settings before rendering UI.
  final settings = AppSettings();
  await settings.load();

  // Load app-lock state before rendering UI.
  final lock = AppLockController();
  await lock.load();

  runApp(MyApp(settings: settings, lock: lock));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key, 
    required this.settings,
    required this.lock,
  });

  final AppSettings settings;
  final AppLockController lock;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF7B9DFF);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.light,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.dark,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );


    return AppControllers(
      settings: settings,
      lock: lock,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'HappBit',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,

            // NEW: AppLockOverlay sits above the whole app
            builder: (context, child) {
              return AppLockOverlay(
                lock: lock,
                child: child ?? const SizedBox.shrink(),
              );
            },

            // AuthGate will show SignInPage when not signed in, otherwise HomePage
            home: const AuthGate(),

            // Optional named routes if you want them elsewhere
            routes: {
              // '/sign-in': (_) => const SignInPage(),
              // '/sign-up': (_) => const SignUpPage(),
              // '/home': (_) => const HomePage(),
            },
          );
        },
      ),
    );
  }
}
