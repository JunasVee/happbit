import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final auth = AuthService();
  final data = DataService();

  bool _loading = true;
  List<Map<String, dynamic>> _habits = [];
  List<double> _weeklyCompletionData = [0, 0, 0, 0, 0, 0, 0];
  int _totalStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  // === FUNGSI FIX ERROR TYPECASTING WARNA ===
  Color _parseSafeColor(dynamic rawColor) {
    if (rawColor == null) return const Color(0xFF4A90E2); // Default biru jika null

    if (rawColor is int) {
      return Color(rawColor);
    }

    if (rawColor is String) {
      // Mencoba parse string "4294929259" menjadi integer
      final parsed = int.tryParse(rawColor);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return const Color(0xFF4A90E2); // Fallback warna jika gagal parse
  }

  Future<void> _loadAnalytics() async {
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final habits = await data.fetchHabits(user.id);
      
      int highestStreak = 0;
      double totalProgressToday = 0;
      
      for (var h in habits) {
        final streak = h['streak'] is int ? h['streak'] as int : 0;
        if (streak > highestStreak) highestStreak = streak;

        final goal = (h['goal'] as num?)?.toDouble() ?? 1.0;
        final todayValue = (h['today_value'] as num?)?.toDouble() ?? 0.0;
        totalProgressToday += (todayValue / goal).clamp(0.0, 1.0);
      }

      // Simulasi data mingguan
      double currentAvg = habits.isEmpty ? 0 : (totalProgressToday / habits.length);
      List<double> dummyWeekly = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, currentAvg];

      setState(() {
        _habits = habits;
        _totalStreak = highestStreak;
        _weeklyCompletionData = dummyWeekly;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading analytics: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Habit Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAnalytics, 
            icon: const Icon(Icons.refresh, color: Colors.black)
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildQuickStats(),
                    const SizedBox(height: 20),
                    _buildWeeklyChart(),
                    const SizedBox(height: 20),
                    _buildPerformanceList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard("Total Habits", _habits.length.toString(), Colors.blue),
        const SizedBox(width: 12),
        _statCard("Best Streak", "$_totalStreak Days", Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 260,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Text(days[value.toInt() % 7], style: const TextStyle(color: Colors.grey, fontSize: 12));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(_weeklyCompletionData.length, (i) => FlSpot(i.toDouble(), _weeklyCompletionData[i])),
              isCurved: true,
              color: const Color(0xFF4A90E2),
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: const Color(0xFF4A90E2).withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Habit Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._habits.map((h) {
          // MENGGUNAKAN FUNGSI PARSE AMAN DI SINI
          final habitColor = _parseSafeColor(h['color']);
          final double progress = ((h['today_value'] ?? 0) / (h['goal'] ?? 1)).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: habitColor.withOpacity(0.1),
                child: Icon(Icons.check_circle_outline, color: habitColor),
              ),
              title: Text(h['title'] ?? 'Habit'),
              subtitle: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: habitColor,
              ),
              trailing: Text("${(progress * 100).toInt()}%"),
            ),
          );
        }).toList(),
      ],
    );
  }
}