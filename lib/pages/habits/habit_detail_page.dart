import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class HabitDetailPage extends StatefulWidget {
  final AuthService auth;
  final DataService data;
  final Map<String, dynamic> habit;

  const HabitDetailPage({
    super.key,
    required this.auth,
    required this.data,
    required this.habit,
  });

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  bool _loading = true;
  bool _working = false;
  bool _changed = false;

  late Map<String, dynamic> _habit;
  List<Map<String, dynamic>> _todayLogs = [];
  List<Map<String, dynamic>> _recentLogs = [];

  double _todayValue = 0;
  double _goal = 1;

  @override
  void initState() {
    super.initState();
    _habit = Map<String, dynamic>.from(widget.habit);
    _load();
  }

  String _s(dynamic v, [String f = '']) => (v == null) ? f : v.toString();

  double _dnum(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String get _unit => _s(_habit['unit'], '');
  String get _cat => _s(_habit['category'], '');
  String get _title => _s(_habit['title'], 'Habit');
  String get _description => _s(_habit['description'], '');

  /// Warna accent:
  /// - kalau ada kolom `color` (int) → pakai itu
  /// - kalau tidak → fallback berdasarkan kategori
  Color get _accent {
    final raw = _habit['color'];
    if (raw is int && raw != 0) {
      return Color(raw);
    }

    switch (_cat) {
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

  ({DateTime fromUtc, DateTime toUtc}) _todayUtcRange() {
    final now = DateTime.now();
    final startLocal = DateTime(now.year, now.month, now.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    return (fromUtc: startLocal.toUtc(), toUtc: endLocal.toUtc());
  }

  String _formatShortTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatValue(double v) {
    if (_unit == 'ml') {
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}L';
      return '${v.toInt()}ml';
    }
    if (_unit == 'kcal') return '${v.toInt()}kcal';
    if (_unit == 'g') return '${v.toInt()}g';
    if (_unit == 'hr') return '${v.toInt()}h';
    if (_unit == 'steps') return v.toInt().toString();
    if (_unit.isEmpty) return v.toInt().toString();
    return '${v.toInt()}$_unit';
  }

  /// Quick add sesuai unit
  List<num> _quickAdds() {
    switch (_unit) {
      case 'min':
        return [5, 10, 15];
      case 'ml':
        return [250, 500, 750];
      case 'steps':
        return [500, 1000, 2000];
      case 'kcal':
        return [100, 250, 500];
      case 'g':
        return [10, 20, 30];
      case 'hr':
        return [1, 2];
      case 'session':
      case 'dose':
      case 'serving':
      case 'pages':
      default:
        return [1, 2, 3];
    }
  }

  Future<void> _load() async {
    final user = widget.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      // refresh habit dari DB (termasuk color terbaru, dll)
      _habit = await widget.data.fetchHabit(
        habitId: _s(_habit['id']),
        userId: user.id,
      );

      _goal = _dnum(_habit['goal'], fallback: 1);
      if (_goal <= 0) _goal = 1;

      // status (today_value/done/streak)
      final status = await widget.data.getHabitStatus(
        _s(_habit['id']),
        user.id,
        goal: _goal,
      );
      _habit.addAll(status);

      _todayValue = _dnum(_habit['today_value'], fallback: 0);

      // logs hari ini
      final range = _todayUtcRange();
      _todayLogs = await widget.data.fetchHabitInstances(
        habitId: _s(_habit['id']),
        userId: user.id,
        fromUtc: range.fromUtc,
        toUtc: range.toUtc,
        limit: 200,
        ascending: true,
      );

      // recent logs (global)
      _recentLogs = await widget.data.fetchHabitInstances(
        habitId: _s(_habit['id']),
        userId: user.id,
        limit: 20,
        ascending: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _doneToday => (_habit['done_today'] == true);

  /// Tambah progress dengan value (dipakai quick add & custom)
  Future<void> _addValue(num v) async {
    final user = widget.auth.currentUser;
    if (user == null) return;

    setState(() => _working = true);
    try {
      // ⬇️ DI SINI value dikirim ke DB, jadi +15 min beneran nambah 15, dst.
      await widget.data.markHabitDone(
        _s(_habit['id']),
        user.id,
        value: v,
      );
      _changed = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add error: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Tombol "Complete today" → langsung set ke goal (atau +1 kalau sudah lewat)
  Future<void> _completeToday() async {
    final remaining = (_goal - _todayValue);
    final add = remaining > 0 ? remaining : 1;
    await _addValue(add);
  }

  Future<void> _undo() async {
    final user = widget.auth.currentUser;
    if (user == null) return;

    final range = _todayUtcRange();
    setState(() => _working = true);

    try {
      await widget.data.removeLatestHabitInstanceInRange(
        habitId: _s(_habit['id']),
        userId: user.id,
        fromUtc: range.fromUtc,
        toUtc: range.toUtc,
      );
      _changed = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Undo error: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearToday() async {
    final user = widget.auth.currentUser;
    if (user == null) return;

    final range = _todayUtcRange();
    setState(() => _working = true);

    try {
      await widget.data.clearHabitInstancesInRange(
        habitId: _s(_habit['id']),
        userId: user.id,
        fromUtc: range.fromUtc,
        toUtc: range.toUtc,
      );
      _changed = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear error: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _customAddDialog() async {
    final ctrl = TextEditingController();
    final res = await showDialog<num>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add progress'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter value',
              suffixText: _unit,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = num.tryParse(ctrl.text.trim());
                if (v == null || v <= 0) return;
                Navigator.pop(ctx, v);
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );

    if (res != null) _addValue(res);
  }

  @override
  Widget build(BuildContext context) {
    final streak = (_habit['streak'] is int) ? _habit['streak'] as int : 0;
    final ratio = (_todayValue / _goal).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearToday();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear today logs'),
              ),
            ],
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_working || _todayLogs.isEmpty) ? null : _undo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _working ? null : _completeToday,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_doneToday ? 'Add more' : 'Complete today'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's progress",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatValue(_todayValue)} / ${_formatValue(_goal)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _doneToday
                                    ? 'Completed today ✅'
                                    : 'Not completed yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _doneToday
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: 1,
                                strokeWidth: 8,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.grey[200]!,
                                ),
                              ),
                              CircularProgressIndicator(
                                value: ratio,
                                strokeWidth: 8,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(_accent),
                              ),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick add chips
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick add',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final v in _quickAdds())
                              ActionChip(
                                label: Text(
                                  '+$v${_unit.isEmpty ? '' : ' $_unit'}',
                                ),
                                onPressed:
                                    _working ? null : () => _addValue(v),
                              ),
                            ActionChip(
                              label: const Text('Custom'),
                              onPressed:
                                  _working ? null : _customAddDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // About / detail habit
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About this habit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_description.isNotEmpty)
                          Text(
                            _description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          )
                        else
                          Text(
                            'No description. You can add notes when editing this habit.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _kv(
                                'Category',
                                _cat.isEmpty ? '-' : _cat,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kv('Streak', '${streak}d'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Today logs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_todayLogs.isEmpty)
                    _emptyBox(
                      'No logs today. Use quick add to record progress.',
                    )
                  else
                    ..._todayLogs.map((log) {
                      final time =
                          _formatShortTime(_s(log['occured_at']));
                      final value =
                          _dnum(log['value'], fallback: 1);
                      return _logTile(
                        'Logged',
                        _formatValue(value),
                        time,
                      );
                    }),

                  const SizedBox(height: 16),

                  const Text(
                    'Recent activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_recentLogs.isEmpty)
                    _emptyBox('No history yet.')
                  else
                    ..._recentLogs.take(8).map((log) {
                      final ts = _s(log['occured_at']);
                      final value =
                          _dnum(log['value'], fallback: 1);
                      // untuk riwayat, tampilkan tanggal raw (atau bisa di-format lagi kalau mau)
                      return _logTile(
                        'Activity',
                        _formatValue(value),
                        ts,
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            v,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

  Widget _emptyBox(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      );

  Widget _logTile(String title, String value, String subtitle) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 18,
              color: _accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}
