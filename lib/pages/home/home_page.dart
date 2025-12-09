// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../habits/add_habit_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = AuthService();
  final data = DataService();

  bool _loading = true;
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _loading = true);
    final user = auth.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      habits = await data.fetchHabits(user.id);
    } catch (e) {
      debugPrint("Error loading habits: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading habits: $e")),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markDone(String habitId) async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await data.markHabitDone(habitId, user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as done")),
      );

      await _loadHabits();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _signOut() async {
    await auth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signed out")),
    );
  }

  Future<void> _onAddHabit() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddHabitPage(auth: auth, data: data),
      ),
    );

    if (created == true) {
      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final username =
        user?.userMetadata?['username'] as String? ??
        (user?.email?.split('@').first ?? 'User');

    final totalHabits = habits.length;
    final completedHabits = habits.where(_habitDoneToday).length;
    final remainingHabits = totalHabits - completedHabits;
    final progress = totalHabits == 0 ? 0.0 : completedHabits / totalHabits;

    final longestStreak = habits.fold<int>(
      0,
      (max, h) {
        final s = h['streak'] as int? ?? 0;
        return s > max ? s : max;
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadHabits,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    _buildHeader(username),
                    const SizedBox(height: 24),

                    _buildSummaryCard(
                      progress: progress,
                      totalHabits: totalHabits,
                      completedHabits: completedHabits,
                      remainingHabits: remainingHabits,
                    ),

                    const SizedBox(height: 24),

                    _buildTodayGoals(
                      completedHabits: completedHabits,
                      remainingHabits: remainingHabits,
                      longestStreak: longestStreak,
                    ),

                    const SizedBox(height: 24),
                    _buildHabitSectionTitle(),
                    const SizedBox(height: 12),

                    if (habits.isEmpty)
                      _buildEmptyState()
                    else
                      ...habits.map(_buildHabitCard),
                  ],
                ),
              ),
      ),
    );
  }

  // ========================= HEADER =========================

  Widget _buildHeader(String username) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        PopupMenuButton(
          onSelected: (value) {
            if (value == "logout") _signOut();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: "logout", child: Text("Sign out")),
          ],
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== SUMMARY CARD =======================

  Widget _buildSummaryCard({
    required double progress,
    required int totalHabits,
    required int completedHabits,
    required int remainingHabits,
  }) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's overview",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  '$completedHabits of $totalHabits habits completed',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _legendDot(Colors.blue),
                    const SizedBox(width: 6),
                    Text('Completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(width: 16),
                    _legendDot(Colors.orange),
                    const SizedBox(width: 6),
                    Text('Remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _RadialProgress(progress: progress, label: '$percent%'),
        ],
      ),
    );
  }

  // ===================== TODAY GOALS =======================

  Widget _buildTodayGoals({
    required int completedHabits,
    required int remainingHabits,
    required int longestStreak,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's goals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _onAddHabit,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add habit'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _GoalCard(
                title: 'Completed',
                value: '$completedHabits',
                subtitle: 'today',
                icon: Icons.check_circle,
                accentColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GoalCard(
                title: 'Remaining',
                value: '$remainingHabits',
                subtitle: 'left',
                icon: Icons.schedule_rounded,
                accentColor: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _GoalCard(
                title: 'Longest streak',
                value: '${longestStreak}d',
                subtitle: 'best habit',
                icon: Icons.local_fire_department,
                accentColor: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitSectionTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your habits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sorting coming soon')),
            );
          },
          icon: const Icon(Icons.filter_list_rounded),
        ),
      ],
    );
  }

  // ====================== HABIT CARD ========================

  Widget _buildHabitCard(Map<String, dynamic> h) {
    final title = h['title']?.toString() ?? 'Untitled habit';
    final desc = h['description']?.toString() ?? '';
    final doneToday = _habitDoneToday(h);
    final streak = h['streak'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _markDone(h['id'] as String),
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: doneToday ? const Color(0xFF4F7DF9) : Colors.grey[300]!,
                  width: 2,
                ),
                color: doneToday ? const Color(0xFF4F7DF9) : Colors.white,
              ),
              child: doneToday
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),

                if (desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      desc,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (streak > 0)
                Text(
                  '${streak}d streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                doneToday ? 'Done' : 'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: doneToday
                      ? const Color(0xFF4F7DF9)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.flag_outlined, size: 32),
          SizedBox(height: 12),
          Text('No habits yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text(
            'Start by creating your first habit using the "Add habit" button above.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color) {
    return Container(
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  bool _habitDoneToday(Map<String, dynamic> h) {
    final raw = h['done_today'] ?? h['is_done'] ?? h['completed'];
    if (raw is bool) return raw;
    if (raw is int) return raw > 0;
    return false;
  }
}

// ==================== EXTRA WIDGETS =====================

// Radial progress indicator
class _RadialProgress extends StatelessWidget {
  final double progress;
  final String label;

  const _RadialProgress({
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      height: 110,
      width: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 10,
            valueColor: AlwaysStoppedAnimation(Colors.grey[200]!),
          ),
          CircularProgressIndicator(
            value: clamped,
            strokeWidth: 10,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4F7DF9)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'completed',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Small goal card
class _GoalCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _GoalCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black),
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      TextSpan(
                        text: ' $subtitle',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
