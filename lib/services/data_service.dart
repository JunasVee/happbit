import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  final SupabaseClient client = Supabase.instance.client;

  // ==========================
  // Helpers
  // ==========================
  static num _toNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    final n = _toNum(v, fallback: fallback);
    return n.toDouble();
  }

  // ==========================
  // Habits
  // ==========================
  Future<List<Map<String, dynamic>>> fetchHabits(String userId) async {
    final habitsRes = await client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final habits = List<Map<String, dynamic>>.from(habitsRes as List);

    for (final h in habits) {
      final habitId = h['id'].toString();
      final goal = _toNum(h['goal'], fallback: 1);
      final status = await getHabitStatus(habitId, userId, goal: goal);

      // Tambahkan computed fields ke map habit
      h['done_today'] = status['done_today'];
      h['streak'] = status['streak'];
      h['last_completed_at'] = status['last_completed_at'];
      h['today_value'] = status['today_value'];
      h['today_count'] = status['today_count'];
    }

    return habits;
  }

  /// CREATE HABIT
  ///
  /// Tambahan: [color] → simpan warna custom ke kolom `color` (INTEGER)
  /// di tabel `habits` 
  Future<void> createHabit({
    required String userId,
    required String title,
    required String category,
    String? description,
    int? dailyTarget,
    String? unit,
    int? color,
  }) async {
    await client.from('habits').insert({
      'user_id': userId,
      'title': title,
      'category': category,
      'description': description,
      'goal': dailyTarget ?? 1,
      'unit': unit,
      'color': color,
    });
  }

  /// UPDATE HABIT (edit nama, target, dsb.)
  Future<void> updateHabit({
    required String habitId,
    String? title,
    int? goal,
    String? description,
    String? unit,
    String? category,
    int? color, 
  }) async {
    final payload = <String, dynamic>{};

    if (title != null) payload['title'] = title;
    if (goal != null) payload['goal'] = goal;
    if (description != null) payload['description'] = description;
    if (unit != null) payload['unit'] = unit;
    if (category != null) payload['category'] = category;
    if (color != null) payload['color'] = color;

    // kalau tidak ada apa pun yang diubah, nggak usah hit DB
    if (payload.isEmpty) return;

    await client.from('habits').update(payload).eq('id', habitId);
  }

  /// DELETE HABIT (dan semua log-nya)
  Future<void> deleteHabit(String habitId) async {
    // Hapus dulu semua instances (kalau belum diatur cascade di FK)
    await client.from('habit_instances').delete().eq('habit_id', habitId);

    // Lalu hapus habit-nya
    await client.from('habits').delete().eq('id', habitId);
  }

  /// Insert satu log.
  ///
  /// - Kalau tabel `habit_instances` punya kolom `value`, kita simpan `value`.
  /// - Kalau belum punya, fallback insert tanpa `value` (anggap setiap log = 1).
  Future<void> markHabitDone(
    String habitId,
    String userId, {
    num value = 1,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final payloadWithValue = {
      'habit_id': habitId,
      'user_id': userId,
      'occured_at': nowIso,
      'value': value,
    };

    try {
      await client.from('habit_instances').insert(payloadWithValue);
    } catch (_) {
      // Fallback kalau kolom value belum ada di schema
      await client.from('habit_instances').insert({
        'habit_id': habitId,
        'user_id': userId,
        'occured_at': nowIso,
      });
    }
  }

  // ==========================
  // Status / Progress / Streak
  // ==========================

  /// - done_today = total progress hari ini >= goal
  /// - today_value = sum(value) hari ini (atau count kalau tidak ada kolom value)
  /// - streak = jumlah hari berturut-turut (mundur dari hari ini) yang complete
  Future<Map<String, dynamic>> getHabitStatus(
    String habitId,
    String userId, {
    num goal = 1,
  }) async {
    final safeGoal = goal <= 0 ? 1 : goal;
    final nowLocal = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(nowLocal);

    List<Map<String, dynamic>> instances = [];
    bool hasValueColumn = true;

    try {
      final res = await client
          .from('habit_instances')
          .select('occured_at,value')
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .order('occured_at', ascending: false)
          .limit(500);

      instances = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      // Kalau select dengan value gagal → berarti kolom value belum ada
      hasValueColumn = false;

      final res = await client
          .from('habit_instances')
          .select('occured_at')
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .order('occured_at', ascending: false)
          .limit(500);

      instances = List<Map<String, dynamic>>.from(res as List);
    }

    if (instances.isEmpty) {
      return {
        'done_today': false,
        'streak': 0,
        'last_completed_at': null,
        'today_value': 0,
        'today_count': 0,
      };
    }

    // total per hari
    final totalsByDay = <String, double>{};
    final countByDay = <String, int>{};

    DateTime? lastCompletedLocal;

    for (final inst in instances) {
      final dtLocal = DateTime.parse(inst['occured_at']).toLocal();
      lastCompletedLocal ??= dtLocal;

      final dayKey = DateFormat('yyyy-MM-dd').format(dtLocal);
      final v = hasValueColumn ? _toDouble(inst['value'], fallback: 1) : 1.0;

      totalsByDay[dayKey] = (totalsByDay[dayKey] ?? 0) + v;
      countByDay[dayKey] = (countByDay[dayKey] ?? 0) + 1;
    }

    final todayValue = totalsByDay[todayKey] ?? 0.0;
    final todayCount = countByDay[todayKey] ?? 0;
    final doneToday = todayValue >= safeGoal;

    // Streak: mulai dari hari ini kalau complete, kalau tidak dari kemarin
    DateTime cursor = nowLocal;
    if (!doneToday) cursor = cursor.subtract(const Duration(days: 1));

    int streak = 0;
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(cursor);
      final v = totalsByDay[key] ?? 0.0;
      if (v >= safeGoal) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return {
      'done_today': doneToday,
      'streak': streak,
      'last_completed_at': lastCompletedLocal?.toIso8601String(),
      'today_value': todayValue,
      'today_count': todayCount,
    };
  }

  // ==========================
  // Detail helpers
  // ==========================

  Future<Map<String, dynamic>> fetchHabit({
    required String habitId,
    required String userId,
  }) async {
    final res = await client
        .from('habits')
        .select()
        .eq('id', habitId)
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) throw Exception('Habit not found');
    return Map<String, dynamic>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchHabitInstances({
    required String habitId,
    required String userId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 50,
    bool ascending = false,
  }) async {
    dynamic q = client
        .from('habit_instances')
        .select('id,occured_at,value')
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    if (fromUtc != null) {
      q = q.gte('occured_at', fromUtc.toIso8601String());
    }
    if (toUtc != null) {
      q = q.lt('occured_at', toUtc.toIso8601String());
    }

    try {
      final res =
          await q.order('occured_at', ascending: ascending).limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      // fallback kalau kolom value belum ada
      dynamic q2 = client
          .from('habit_instances')
          .select('id,occured_at')
          .eq('habit_id', habitId)
          .eq('user_id', userId);

      if (fromUtc != null) {
        q2 = q2.gte('occured_at', fromUtc.toIso8601String());
      }
      if (toUtc != null) {
        q2 = q2.lt('occured_at', toUtc.toIso8601String());
      }

      final res =
          await q2.order('occured_at', ascending: ascending).limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    }
  }

  Future<List<Map<String, dynamic>>> fetchNews() async {
  try {
    // Pastikan nama tabel di Supabase kamu adalah 'news' atau 'articles'
    // Di sini saya asumsikan nama tabelnya adalah 'news'
    final response = await client
        .from('news') 
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error fetching news: $e');
    return []; // Kembalikan list kosong jika error agar aplikasi tidak crash
    }
  }

  Future<void> removeLatestHabitInstanceInRange({
    required String habitId,
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final res = await client
        .from('habit_instances')
        .select('id,occured_at')
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .gte('occured_at', fromUtc.toIso8601String())
        .lt('occured_at', toUtc.toIso8601String())
        .order('occured_at', ascending: false)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(res as List);
    if (list.isEmpty) return;

    final row = list.first;
    final id = row['id'];
    if (id != null) {
      await client.from('habit_instances').delete().eq('id', id);
    } else {
      await client
          .from('habit_instances')
          .delete()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('occured_at', row['occured_at']);
    }
  }

  Future<void> clearHabitInstancesInRange({
    required String habitId,
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    await client
        .from('habit_instances')
        .delete()
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .gte('occured_at', fromUtc.toIso8601String())
        .lt('occured_at', toUtc.toIso8601String());
  }

  Future<Map<String, dynamic>> getWeeklySummary(String habitId, String userId) async {
    final now = DateTime.now().toUtc();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final res = await fetchHabitInstances(
      habitId: habitId,
      userId: userId,
      fromUtc: startOfWeek,
      toUtc: now,
      limit: 200,
      ascending: true,
    );
    // Aggregate per day
    final totals = <String, double>{};
    for (final inst in res) {
      final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(inst['occured_at']).toLocal());
      totals[dayKey] = (totals[dayKey] ?? 0) + (inst['value'] ?? 1.0);
    }
    return {'totals': totals};
  }

  Future<Map<String, int>> getWeeklyCompletion(String habitId, String userId) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(days: 6));
    final instances = await fetchHabitInstances(
      habitId: habitId,
      userId: userId,
      fromUtc: start,
      toUtc: now,
      ascending: true,
    );

    final totals = <String, int>{};
    for (final inst in instances) {
      final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(inst['occured_at']).toLocal());
      totals[dayKey] = (totals[dayKey] ?? 0) + 1;
    }
    return totals;
  }
}
