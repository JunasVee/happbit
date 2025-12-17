import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            OverviewSection(),
            SizedBox(height: 24),
            WeeklyHabitChart(),
            SizedBox(height: 24),
            GoalProgressSection(),
            SizedBox(height: 24),
            RecommendationSection(),
          ],
        ),
      ),
    );
  }
}

/* =========================
   OVERVIEW SECTION
========================= */

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Overview',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          StatItem(label: 'Habits', value: '12'),
          StatItem(label: 'Goals', value: '5'),
          StatItem(label: 'Streak', value: '7 🔥'),
        ],
      ),
    );
  }
}

/* =========================
   WEEKLY HABIT CHART
========================= */

class WeeklyHabitChart extends StatelessWidget {
  const WeeklyHabitChart({super.key});

  @override
  Widget build(BuildContext context) {
    final weeklyData = [3, 4, 2, 5, 6, 4, 7]; // dummy data

    return CardWrapper(
      title: 'Weekly Habit Completion',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(days[value.toInt()]),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  weeklyData.length,
                  (i) => FlSpot(i.toDouble(), weeklyData[i].toDouble()),
                ),
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   GOAL PROGRESS + LOGIC
========================= */

class GoalProgressSection extends StatelessWidget {
  const GoalProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    const completed = 18;
    const target = 30;
    final progress = completed / target;

    return CardWrapper(
      title: 'Goal Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% of monthly goal'),
          const SizedBox(height: 12),
          RecommendationText(progress: progress),
        ],
      ),
    );
  }
}

/* =========================
   RECOMMENDATION SECTION
========================= */

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Recommendations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('💧 Drink 1 more glass of water'),
          SizedBox(height: 6),
          Text('🚶 Walk 10 minutes'),
          SizedBox(height: 6),
          Text('😴 Sleep before 23:00'),
        ],
      ),
    );
  }
}

/* =========================
   REUSABLE COMPONENTS
========================= */

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class RecommendationText extends StatelessWidget {
  final double progress;

  const RecommendationText({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress < 0.4) {
      return const Text('⚠️ Try to complete at least 2 habits today');
    } else if (progress < 0.8) {
      return const Text('👍 You’re on track, keep it consistent');
    } else {
      return const Text('🔥 Amazing! Maintain your streak');
    }
  }
}

class CardWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const CardWrapper({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
