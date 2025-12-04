import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  final SupabaseClient client = Supabase.instance.client;

  /// Fetch all habits for a user + compute:
  /// - doneToday
  /// - streak
  /// - lastCompleted
  Future<List<Map<String, dynamic>>> fetchHabits(String userId) async {
    final habitsRes = await client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final habits = List<Map<String, dynamic>>.from(habitsRes as List);

    for (var h in habits) {
      final habitId = h['id'].toString();

      final status = await getHabitStatus(habitId, userId);

      h['done_today'] = status['done_today'];
      h['streak'] = status['streak'];
      h['last_completed_at'] = status['last_completed_at'];
    }

    return habits;
  }

  /// Record one completion for a habit
  Future<void> markHabitDone(String habitId, String userId) async {
    await client.from('habit_instances').insert({
      'habit_id': habitId,
      'user_id': userId,
      'occured_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Create a habit (dipanggil dari AddHabitPage)
  Future<void> createHabit({
    required String userId,
    required String title,
    required String category,
    String? description,
    int? dailyTarget,
    String? unit,
  }) async {
    await client.from('habits').insert({
      'user_id': userId,
      'title': title,
      'category': category,
      'description': description,
      'daily_target': dailyTarget,
      'unit': unit,
    });
  }

  /// Mengambil info streak & doneToday
  Future<Map<String, dynamic>> getHabitStatus(
      String habitId, String userId) async {
    
    // Ambil semua instances habit
    final res = await client
        .from('habit_instances')
        .select()
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .order('occured_at', ascending: false);

    final instances = List<Map<String, dynamic>>.from(res as List);

    if (instances.isEmpty) {
      return {
        'done_today': false,
        'streak': 0,
        'last_completed_at': null,
      };
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int streak = 0;

    DateTime? lastDate;

    // cek kalau selesai hari ini
    bool doneToday = false;

    for (var inst in instances) {
      final date = DateTime.parse(inst['occured_at']).toLocal();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // update last completed
      lastDate = lastDate ?? date;

      // apakah hari ini?
      if (dateStr == today) {
        doneToday = true;
      }

      // hitung streak
      if (streak == 0) {
        streak = 1; // hari pertama
      } else {
        final prevDate = DateTime.parse(instances[instances.indexOf(inst) - 1]['occured_at']).toLocal();
        final diff = prevDate.difference(date).inDays;

        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }
    }

    return {
      'done_today': doneToday,
      'streak': streak,
      'last_completed_at': lastDate?.toIso8601String(),
    };
  }
}
