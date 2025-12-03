// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Sign up - returns the created User if available (may be null if email confirmation required)
  Future<User?> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password must not be empty.');
    }
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      // res.user may be null when email confirmation is required
      return res.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in (email+password)
  Future<User> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) throw Exception('Sign-in failed (no user returned).');
      return res.user!;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
