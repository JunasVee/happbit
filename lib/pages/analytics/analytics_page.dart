import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/data_service.dart';

class AnalyticsPage extends StatefulWidget {
  final String userId;
  const AnalyticsPage({super.key, required this.userId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _dataService = DataService();
  bool _loading = true;
  List<Map<String, dynamic>> _habits = [];
  Map<String, int> _weeklyTotals = {};
  int _completedToday = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    debugPrint('Analytics: starting load for userId=${widget.userId}');
    try {
      final habits = await _dataService.fetchHabits(widget.userId);
      debugPrint('Analytics: fetched ${habits.length} habits');

      if (habits.isEmpty) {
        debugPrint('Analytics: no habits found, showing empty state');
        setState(() {
          _habits = [];
          _completedToday = 0;
          _longestStreak = 0;
          _weeklyTotals = {};
          _loading = false;
        });
        return;
      }

      int doneToday = habits.where((h) => h['done_today'] == true).length;
      int longestStreak = habits.fold<int>(
        0,
            (max, h) => h['streak'] > max ? h['streak'] : max,
      );
      debugPrint('Analytics: doneToday=$doneToday, longestStreak=$longestStreak');

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));
      debugPrint('Analytics: fetching instances from $start to $now');

      final instances = await _dataService.fetchHabitInstances(
        habitId: habits.first['id'].toString(),
        userId: widget.userId,
        fromUtc: start.toUtc(),
        toUtc: now.toUtc(),
        ascending: true,
        limit: 500,
      );
      debugPrint('Analytics: fetched ${instances.length} instances');

      final totals = <String, int>{};
      for (final inst in instances) {
        final dayKey = DateTime.parse(inst['occured_at']).toLocal().weekday;
        totals['$dayKey'] = (totals['$dayKey'] ?? 0) + 1;
      }
      debugPrint('Analytics: weeklyTotals=$totals');

      setState(() {
        _habits = habits;
        _completedToday = doneToday;
        _longestStreak = longestStreak;
        _weeklyTotals = totals;
        _loading = false;
      });
      debugPrint('Analytics: state updated, loading=false');
    } catch (e, st) {
      debugPrint('Analytics error: $e\n$st');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Fallback when no habits exist
    if (_habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'No habits yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking to see your progress here!',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Normal analytics UI when habits exist
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your progress report',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Habits', value: '${_habits.length}')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Done Today', value: '$_completedToday')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Longest Streak', value: '${_longestStreak}d')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Weekly %', value: _weeklyPercent())),
            ],
          ),

          const SizedBox(height: 32),

          // Weekly bar chart
          Text('Weekly Progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                        return Text(days[(value.toInt() - 1) % 7]);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 1; i <= 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (_weeklyTotals['$i'] ?? 0).toDouble(),
                          color: theme.colorScheme.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Habit breakdown list
          Text('Habit Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final h in _habits) ...[
            _HabitProgressTile(
              title: h['title'],
              progress: h['today_count'] ?? 0,
              total: h['goal'] ?? 1,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  String _weeklyPercent() {
    final total = _weeklyTotals.values.fold<int>(0, (sum, v) => sum + v);
    final maxPossible = _habits.length * 7; // each habit per day
    if (maxPossible == 0) return '0%';
    final percent = (total / maxPossible * 100).round();
    return '$percent%';
  }
}

// Summary card widget
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Habit progress tile
class _HabitProgressTile extends StatelessWidget {
  final String title;
  final int progress;
  final int total;
  const _HabitProgressTile({required this.title, required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0.0 : progress / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text('$progress / $total today',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}