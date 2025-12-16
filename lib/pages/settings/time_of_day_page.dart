import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';

class TimeOfDayPage extends StatefulWidget {
  const TimeOfDayPage({super.key});

  @override
  State<TimeOfDayPage> createState() => _TimeOfDayPageState();
}

class _TimeOfDayPageState extends State<TimeOfDayPage> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _saving = false;

  String _timezone = 'Asia/Jakarta';

  // Keep this simple (no extra packages). You can expand later.
  final List<String> _timezones = const [
    'Asia/Jakarta',
    'Asia/Makassar',
    'Asia/Jayapura',
    'UTC',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('timezone')
          .eq('id', user.id)
          .maybeSingle();

      final tz = (data?['timezone'] as String?)?.trim();
      if (tz != null && tz.isNotEmpty) {
        _timezone = tz;
      }
    } catch (e) {
      debugPrint('Failed to load timezone: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'timezone': _timezone})
          .eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timezone updated')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Failed to save timezone: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update timezone')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tileBg = theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time of Day'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timezone',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Used for reminders and day-based tracking.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _timezones.contains(_timezone)
                                ? _timezone
                                : _timezones.first,
                            items: _timezones
                                .map(
                                  (tz) => DropdownMenuItem(
                                    value: tz,
                                    child: Text(tz),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _timezone = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }
}
