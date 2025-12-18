// lib/pages/analytics/analytics_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class AnalyticsPage extends StatefulWidget {
  final String userId;
  const AnalyticsPage({super.key, required this.userId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _dataService = DataService();
  final _authService = AuthService();
  
  bool _loading = true;
  List<Map<String, dynamic>> _habits = [];
  Map<String, int> _weeklyTotals = {};
  int _completedToday = 0;
  int _longestStreak = 0;
  Map<DateTime, int> _heatmapData = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Color _parseSafeColor(dynamic rawColor) {
    if (rawColor == null) return const Color(0xFF4A90E2);
    if (rawColor is int) return Color(rawColor);
    if (rawColor is String) {
      final parsed = int.tryParse(rawColor);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFF4A90E2);
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final habits = await _dataService.fetchHabits(widget.userId);

      if (habits.isEmpty) {
        setState(() {
          _habits = [];
          _loading = false;
        });
        return;
      }

      int doneToday = habits.where((h) => h['done_today'] == true).length;
      int maxStreak = habits.fold<int>(0, (max, h) {
        int s = (h['streak'] is int) ? h['streak'] : 0;
        return s > max ? s : max;
      });

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 3, now.day);
      final heatmapMap = <DateTime, int>{};
      final totals = <String, int>{}; 
      
      for (var habit in habits) {
        final instances = await _dataService.fetchHabitInstances(
          habitId: habit['id'].toString(), 
          userId: widget.userId,
          fromUtc: startDate.toUtc(),
          toUtc: now.toUtc(),
          limit: 100,
        );

        for (final inst in instances) {
          final date = DateTime.parse(inst['occured_at']).toLocal();
          
          final dayOnly = DateTime(date.year, date.month, date.day);
          heatmapMap[dayOnly] = (heatmapMap[dayOnly] ?? 0) + 1;

          if (date.isAfter(now.subtract(const Duration(days: 7)))) {
            final dayKey = date.weekday;
            totals['$dayKey'] = (totals['$dayKey'] ?? 0) + 1;
          }
        }
      }

      setState(() {
        _habits = habits;
        _completedToday = doneToday;
        _longestStreak = maxStreak;
        _weeklyTotals = totals;
        _heatmapData = heatmapMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Analytics error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('No habits yet. Start tracking!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [IconButton(onPressed: _loadAnalytics, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(theme),
          const SizedBox(height: 24),
          _SmartRecommendation(habits: _habits), 
          const SizedBox(height: 32),
          _buildHeatmapSection(theme),
          const SizedBox(height: 32),
          _buildBarChart(theme),
          const SizedBox(height: 32),
          _buildHabitList(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Habits', 
                value: '${_habits.length}',
                icon: Icons.list_alt_rounded,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Done Today', 
                value: '$_completedToday',
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Best Streak', 
                value: '${_longestStreak}d',
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Consistency', 
                value: _calculateWeeklyPercent(),
                icon: Icons.auto_graph_rounded,
                iconColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Activity (All Categories)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      int index = (val.toInt() - 1) % 7;
                      return Text(index >= 0 ? days[index] : '', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 1; i <= 7; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (_weeklyTotals['$i'] ?? 0).toDouble(),
                        color: theme.colorScheme.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => theme.colorScheme.primaryContainer,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String weekDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][group.x.toInt() - 1];
                    return BarTooltipItem(
                      '$weekDay\n',
                      TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()} Activities',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consistency Heatmap', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: HeatMap(
            datasets: _heatmapData,
            colorMode: ColorMode.opacity,
            defaultColor: Colors.grey.withOpacity(0.1),
            onClick: (DateTime date) {
              int count = _heatmapData[DateTime(date.year, date.month, date.day)] ?? 0;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("On ${date.day}/${date.month}/${date.year}, you completed $count habits!"),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            textColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            showColorTip: true,
            showText: false,
            scrollable: true,
            size: 20,
            colorsets: {
              1: theme.colorScheme.primary.withOpacity(0.2),
              3: theme.colorScheme.primary.withOpacity(0.4),
              5: theme.colorScheme.primary.withOpacity(0.6),
              7: theme.colorScheme.primary.withOpacity(0.8),
              10: theme.colorScheme.primary,
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHabitList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit Breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final h in _habits) ...[
          _HabitProgressTile(
            title: h['title'] ?? 'Habit',
            progress: (h['today_value'] ?? 0).toInt(),
            total: (h['goal'] ?? 1).toInt(),
            color: _parseSafeColor(h['color']),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _calculateWeeklyPercent() {
    final total = _weeklyTotals.values.fold<int>(0, (sum, v) => sum + v);
    final maxPossible = _habits.length * 7;
    if (maxPossible == 0) return '0%';
    return '${(total / maxPossible * 100).round()}%';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HabitProgressTile extends StatelessWidget {
  final String title;
  final int progress;
  final int total;
  final Color color;
  const _HabitProgressTile({required this.title, required this.progress, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (total > 0) ? (progress / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('$progress / $total today', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SmartRecommendation extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  const _SmartRecommendation({required this.habits});

  @override
  Widget build(BuildContext context) {
    String message = "Keep up the good work, Boi! Consistency is key. 🔥";
    IconData icon = Icons.auto_awesome;
    Color color = Colors.blue;

    if (habits.isEmpty) {
      message = "You haven't started any habits. Let's create one!";
    } else {
      var worstHabit = habits.reduce((a, b) {
        double progA = ((a['today_value'] ?? 0) / (a['goal'] ?? 1));
        double progB = ((b['today_value'] ?? 0) / (b['goal'] ?? 1));
        return progA < progB ? a : b;
      });

      double worstProg = ((worstHabit['today_value'] ?? 0) / (worstHabit['goal'] ?? 1));

      if (worstProg < 0.5) {
        message = "Focus on '${worstHabit['title']}' today. You're a bit behind!";
        icon = Icons.priority_high_rounded;
        color = Colors.orange;
      } else if (habits.every((h) => (h['done_today'] == true))) {
        message = "Legend! All habits completed today!";
        icon = Icons.emoji_events_rounded;
        color = Colors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}