// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Sign up with email & password
  Future<void> signUp(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // If email confirmation is disabled, user will be available immediately.
      if (res.user == null) {
        throw Exception("Sign-up successful but no user returned (email verification required?).");
      }
    } catch (e) {
      // Supabase v2 throws exceptions for errors
      throw Exception("Sign-up failed: $e");
    }
  }

  /// Sign in with email & password
  Future<void> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception("Sign-in failed (invalid credentials?)");
      }
    } catch (e) {
      throw Exception("Sign-in failed: $e");
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
