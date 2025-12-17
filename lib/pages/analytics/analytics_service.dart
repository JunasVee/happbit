// lib/analytics/analytics_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

enum TrackerStatus { pass, fail }

class DailyTrackerResult {
  final int water;     // glasses
  final double sleep;  // hours
  final int calories;  // kcal

  final TrackerStatus waterStatus;
  final TrackerStatus sleepStatus;
  final TrackerStatus caloriesStatus;

  DailyTrackerResult({
    required this.water,
    required this.sleep,
    required this.calories,
    required this.waterStatus,
    required this.sleepStatus,
    required this.caloriesStatus,
  });

  bool get questPassed =>
      waterStatus == TrackerStatus.pass &&
          sleepStatus == TrackerStatus.pass &&
          caloriesStatus == TrackerStatus.pass;
}

class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// CONFIG — change here, nowhere else
  static const int minWater = 8;
  static const double minSleep = 7.0;
  static const int maxCalories = 2200;

  /// Fetch today logs
  Future<DailyTrackerResult> getTodayResult() async {
    final uid = _client.auth.currentUser!.id;

    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);

    final logs = await _client
        .from('habit_instances')
        .select('habit_id, occured_at')
        .eq('user_id', uid)
        .gte('occured_at', startOfDay.toIso8601String());

    int water = 0;
    double sleep = 0;
    int calories = 0;

    for (final log in logs) {
      final habitId = log['habit_id'];

      if (habitId == 'WATER_ID') water++;
      if (habitId == 'SLEEP_ID') sleep += 1;
      if (habitId == 'CALORIES_ID') calories += 100;
    }

    return DailyTrackerResult(
      water: water,
      sleep: sleep,
      calories: calories,
      waterStatus:
      water >= minWater ? TrackerStatus.pass : TrackerStatus.fail,
      sleepStatus:
      sleep >= minSleep ? TrackerStatus.pass : TrackerStatus.fail,
      caloriesStatus:
      calories <= maxCalories ? TrackerStatus.pass : TrackerStatus.fail,
    );
  }


  /// STRICT streak logic
  Future<int> getCurrentStreak() async {
    final uid = _client.auth.currentUser!.id;

    final logs = await _client
        .from('habit_instances')
        .select('occured_at')
        .eq('user_id', uid)
        .order('occured_at', ascending: false);

    int streak = 0;
    DateTime dayCursor = DateTime.now().toUtc();

    while (true) {
      final day = dayCursor.toIso8601String().substring(0, 10);

      final dayLogs = logs.where((l) =>
          (l['occured_at'] as String).startsWith(day));

      if (dayLogs.isEmpty) break;

      // Evaluate quest per day
      final passed = _evaluateDay(dayLogs.toList());
      if (!passed) break;

      streak++;
      dayCursor = dayCursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  bool _evaluateDay(List logs) {
    int water = 0;
    double sleep = 0;
    int calories = 0;

    for (final l in logs) {
      final id = l['habit_id'];
      if (id == 'WATER_ID') water++;
      if (id == 'SLEEP_ID') sleep += 1;
      if (id == 'CALORIES_ID') calories += 100;
    }

    return water >= minWater &&
        sleep >= minSleep &&
        calories <= maxCalories;
  }
}
