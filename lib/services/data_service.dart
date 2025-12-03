// lib/services/data_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchHabits(String userId) async {
    final res = await client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> markHabitDone(String habitId, String userId) async {
    await client.from('habit_instances').insert({
      'habit_id': habitId,
      'user_id': userId,
      'occured_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Optional: move dummy generator here later
}
