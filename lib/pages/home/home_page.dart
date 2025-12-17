import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../habits/add_habit_page.dart';
import '../habits/habit_detail_page.dart';

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

  // palette warna yg bisa dipilih user
  static const List<Color> _kColorOptions = [
    Color(0xFF4F7DF9), // blue
    Color(0xFF33C07A), // green
    Color(0xFFFF6B6B), // red
    Color(0xFFFB9B1A), // orange
    Color(0xFF9B51E0), // purple
    Color(0xFF00B894), // teal

    Color(0xFF2D9CDB), // light blue
    Color(0xFF27AE60), // emerald
    Color(0xFFE67E22), // carrot
    Color(0xFFF2994A), // warm orange
    Color(0xFFEB5757), // soft red
    Color(0xFFBB6BD9), // soft purple

    Color(0xFF16A085), // green teal
    Color(0xFF2980B9), // strong blue
    Color(0xFFC0392B), // dark red
    Color(0xFF8E44AD), // deep purple
    Color(0xFF34495E), // bluish gray
    Color(0xFF7F8C8D), // gray
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  // ---------------- helpers kecil ----------------

  static double _dnum(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _s(dynamic v, [String fallback = '']) =>
      (v == null) ? fallback : v.toString();

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

  bool _doneToday(Map<String, dynamic> h) {
    final raw = h['done_today'];
    if (raw is bool) return raw;
    if (raw is int) return raw > 0;
    return false;
  }

  double _goal(Map<String, dynamic> h) {
    final g = _dnum(h['goal'], fallback: 1);
    return g <= 0 ? 1 : g;
  }

  double _todayValue(Map<String, dynamic> h) {
    final v = _dnum(h['today_value'], fallback: -1);
    if (v >= 0) return v;
    final c = _dnum(h['today_count'], fallback: 0);
    return c;
  }

  String _unit(Map<String, dynamic> h) => _s(h['unit'], '');

  String _category(Map<String, dynamic> h) => _s(h['category'], '');

  IconData _iconFor(String category) {
    switch (category) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'calories':
        return Icons.local_fire_department_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      case 'weights':
        return Icons.fitness_center_rounded;
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'stretching':
        return Icons.accessibility_new_rounded;
      case 'journaling':
        return Icons.edit_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'protein':
        return Icons.egg_rounded;
      case 'micros':
        return Icons.eco_rounded;
      case 'supplements':
        return Icons.medication_rounded;
      default:
        return Icons.flag_outlined;
    }
  }

  /// Warna default berdasarkan kategori (fallback)
  Color _accentFor(String category) {
    switch (category) {
      case 'water':
        return const Color(0xFF4F7DF9);
      case 'sleep':
        return const Color(0xFF33C07A);
      case 'calories':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF4F7DF9);
    }
  }

  /// Warna final untuk habit (pakai kolom `color` kalau ada)
  Color _accentFromHabit(Map<String, dynamic> h) {
    final raw = h['color'];
    if (raw is int && raw != 0) {
      return Color(raw);
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed != 0) {
        return Color(parsed);
      }
    }
    return _accentFor(_category(h));
  }

  String _formatValue(double value, String unit) {
    if (unit == 'ml') {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}L';
      return '${value.toInt()}ml';
    }
    if (unit == 'kcal') return '${value.toInt()}kcal';
    if (unit == 'steps') return '${value.toInt()}';
    if (unit == 'g') return '${value.toInt()}g';
    if (unit == 'hr') return '${value.toInt()}h';
    if (unit.isEmpty) return value.toInt().toString();
    return '${value.toInt()}$unit';
  }

  String _progressText(Map<String, dynamic> h) {
    final t = _todayValue(h);
    final g = _goal(h);
    final u = _unit(h);

    final left = _formatValue(t, u);
    final right = _formatValue(g, u);

    return '$left / $right';
  }

  List<Map<String, dynamic>> _pickTop3ForGoals() {
    final preferred = ['water', 'sleep', 'calories'];
    final picked = <Map<String, dynamic>>[];

    for (final c in preferred) {
      final found = habits.where((h) => _category(h) == c).toList();
      if (found.isNotEmpty) picked.add(found.first);
    }

    for (final h in habits) {
      if (picked.length >= 3) break;
      if (!picked.contains(h)) picked.add(h);
    }

    return picked.take(3).toList();
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

  Future<void> _signOut() async {
    await auth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signed out")),
    );
  }

  Future<void> _openHabitDetail(Map<String, dynamic> habit) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HabitDetailPage(
          habit: habit,
          auth: auth,
          data: data,
        ),
      ),
    );
    if (updated == true) _loadHabits();
  }

  // ---------- EDIT & DELETE (titik tiga) + GANTI WARNA ----------

  Future<void> _onEditHabit(Map<String, dynamic> habit) async {
    final nameCtrl = TextEditingController(
      text: _s(habit['title']),
    );
    final goalCtrl = TextEditingController(
      text: _goal(habit).toInt().toString(),
    );
    final formKey = GlobalKey<FormState>();

    // warna awal = color dari DB, kalau null pakai fallback dari kategori
    int selectedColor = _accentFromHabit(habit).value;
    final raw = habit['color'];
    if (raw is int && raw != 0) {
      selectedColor = raw;
    } else if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed != 0) {
        selectedColor = parsed;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit habit'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Habit name',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama habit tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: goalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Daily target',
                          hintText: 'contoh: 30',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Target tidak boleh kosong';
                          }
                          final parsed = int.tryParse(v.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Target harus angka > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _kColorOptions.map((c) {
                          final isSelected = selectedColor == c.value;
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedColor = c.value;
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.black, width: 2)
                                    : Border.all(
                                        color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final newTitle = nameCtrl.text.trim();
    final newGoal = int.parse(goalCtrl.text.trim());

    try {
      await data.updateHabit(
        habitId: habit['id'].toString(),
        title: newTitle,
        goal: newGoal,
        color: selectedColor, // simpan warna baru
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit berhasil diupdate')),
      );
      await _loadHabits();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update habit: $e')),
      );
    }
  }

  Future<void> _onDeleteHabit(Map<String, dynamic> habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus habit'),
          content: const Text(
            'Yakin mau menghapus habit ini? Semua riwayat/log juga akan terhapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await data.deleteHabit(habit['id'].toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit dihapus')),
      );
      await _loadHabits();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus habit: $e')),
      );
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ??
        (user?.email?.split('@').first ?? 'User');

    final totalHabits = habits.length;
    final completedHabits = habits.where(_doneToday).length;

    double sumProgress = 0;
    for (final h in habits) {
      final g = _goal(h);
      final t = _todayValue(h);
      if (g <= 0) continue;
      sumProgress += (t / g).clamp(0.0, 1.0);
    }
    final overallProgress =
        totalHabits == 0 ? 0.0 : (sumProgress / totalHabits);

    final top3 = _pickTop3ForGoals();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5),
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
                    const SizedBox(height: 20),
                    _buildOverviewCard(
                      overallProgress: overallProgress,
                      completedHabits: completedHabits,
                      totalHabits: totalHabits,
                      top3: top3,
                      allHabits: habits,
                    ),
                    const SizedBox(height: 24),
                    _buildTodayGoals(habits),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader(String username) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- OVERVIEW CARD ----------------

  Widget _buildOverviewCard({
    required double overallProgress,
    required int completedHabits,
    required int totalHabits,
    required List<Map<String, dynamic>> top3,
    required List<Map<String, dynamic>> allHabits,
  }) {
    final percent = (overallProgress * 100).round();

    final rings = top3.map((h) {
      final g = _goal(h);
      final t = _todayValue(h);
      final p = g <= 0 ? 0.0 : (t / g).clamp(0.0, 1.0);
      return _RingData(
        progress: p,
        color: _accentFromHabit(h),
      );
    }).toList();

    final forText = allHabits.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(18),
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
                const Text(
                  "Today's overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedHabits of $totalHabits habits completed',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                for (final h in forText) ...[
                  _metricLine(
                    label: _s(h['title']),
                    value: _progressText(h),
                    color: _accentFromHabit(h),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _MultiRingProgress(
            size: 110,
            rings: rings,
            centerLabel: '$percent%',
          ),
        ],
      ),
    );
  }

  Widget _metricLine({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------- TODAY'S GOALS ----------------

  Widget _buildTodayGoals(List<Map<String, dynamic>> habitsList) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: habitsList.map((habit) {
            final cat = _category(habit);
            final accent = _accentFromHabit(habit);
            return _GoalMetricCard(
              icon: _iconFor(cat),
              title: _s(habit['title'], 'Habit'),
              value: _progressText(habit),
              accent: accent,
              onTap: () => _openHabitDetail(habit),
              onEdit: () => _onEditHabit(habit),
              onDelete: () => _onDeleteHabit(habit),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ===================== Widgets kecil =====================

class _RingData {
  final double progress;
  final Color color;
  const _RingData({required this.progress, required this.color});
}

class _MultiRingProgress extends StatelessWidget {
  final double size;
  final List<_RingData> rings;
  final String centerLabel;

  const _MultiRingProgress({
    required this.size,
    required this.rings,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey[200]!;

    final normalized = List<_RingData>.from(rings);
    while (normalized.length < 3) {
      normalized.add(_RingData(progress: 0, color: bg));
    }

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(
            size: size,
            padding: 0,
            stroke: 10,
            value: normalized[0].progress,
            color: normalized[0].color,
            bg: bg,
          ),
          _ring(
            size: size,
            padding: 10,
            stroke: 10,
            value: normalized[1].progress,
            color: normalized[1].color,
            bg: bg,
          ),
          _ring(
            size: size,
            padding: 20,
            stroke: 10,
            value: normalized[2].progress,
            color: normalized[2].color,
            bg: bg,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'completed',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _ring({
    required double size,
    required double padding,
    required double stroke,
    required double value,
    required Color color,
    required Color bg,
  }) {
    final s = size - (padding * 2);
    return SizedBox(
      height: s,
      width: s,
      child: CircularProgressIndicator(
        value: value.clamp(0.0, 1.0),
        strokeWidth: stroke,
        backgroundColor: bg,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _GoalMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _GoalMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (val == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder: (ctx) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
