// lib/widgets/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/auth/sign_in_page.dart';
import '../pages/navigation/main_navigation.dart';
import 'app_loading_screen.dart';

/// Robust AuthGate:
/// - shows AppLoadingScreen while checking auth
/// - waits for onAuthStateChange OR a timeout (fallback)
/// - then shows SignInPage or MainNavigation
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SupabaseClient _client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;

  // Whether we've finished the initial auth check (either by event or timeout)
  bool _checked = false;

  // Timeout duration for the initial check (safe fallback)
  static const Duration _initialCheckTimeout = Duration(seconds: 5);
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    debugPrint('[AuthGate] init: starting auth-state listener');

    // Listen to auth state changes (fires on sign-in, sign-out, token refresh etc.)
    _authSub = _client.auth.onAuthStateChange.listen((event) {
      debugPrint('[AuthGate] onAuthStateChange: ${event.event}');
      // Mark initial check complete on first event
      if (!_checked) {
        _completeInitialCheck();
      } else {
        // If already checked, just rebuild to reflect changes
        if (mounted) setState(() {});
      }
    });

    // Fallback timer: if no auth event arrives in reasonable time, proceed anyway
    _fallbackTimer = Timer(_initialCheckTimeout, () {
      debugPrint('[AuthGate] initial auth check timed out after $_initialCheckTimeout');
      _completeInitialCheck();
    });
  }

  void _completeInitialCheck() {
    if (_checked) return;
    _checked = true;
    // cancel fallback timer if still active
    _fallbackTimer?.cancel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    debugPrint('[AuthGate] disposing, cancelling auth listener');
    _authSub.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If initial check not finished yet -> show loading screen
    if (!_checked) {
      return const AppLoadingScreen();
    }

    // After check completed, decide based on current user
    final user = _client.auth.currentUser;

    debugPrint('[AuthGate] build: _checked=$_checked, user=${user?.id}');

    if (user == null) {
      return const SignInPage();
    } else {
      return const MainNavigation();
    }
  }
}
