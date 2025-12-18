import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'subscription_page.dart';
import 'edit_profile_page.dart';
import 'display_settings_page.dart';
import 'privacy_lock_page.dart';
import 'time_of_day_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _auth = AuthService();
  String? _displayName;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _loadingProfile = true;
    });

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _displayName = (data?['display_name'] as String?)?.trim();
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    // If EditProfilePage popped with "true", reload the name
    if (updated == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';

    String username;
    if (email.contains('@')) {
      username = '@${email.split('@').first}';
    } else if (email.isNotEmpty) {
      username = '@$email';
    } else {
      username = '@username';
    }

    final name = (_displayName != null && _displayName!.isNotEmpty)
        ? _displayName!
        : 'Your name';

    final theme = Theme.of(context);
    
        // Keep the original light style, but make it readable in dark mode.
    final tileBg = theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.grey.shade300;

    final onTileText = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black,
                    child: Text(
                      (name.isNotEmpty ? name[0] : 'A').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap:_openEditProfile,
                              child : Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Get Premium',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '60% off',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Limited offer!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPage(),
                          ),
                        );
                      },
                      child: const Text('Go Premium'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Free Account',
                onTap: () {
                  Navigator.of(context).push(
                  MaterialPageRoute(
                  builder: (_) => const SubscriptionPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Application',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy Lock',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyLockPage()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.display_settings_rounded,
                label: 'Display',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DisplaySettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.access_time_rounded,
                label: 'Time of Day',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TimeOfDayPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                backgroundColor: tileBg,
                color: theme.colorScheme.error,
                onTap: () async {
                  await _auth.signOut();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                },
              ),
              if (_loadingProfile) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? Colors.black;

    return Material(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: effectiveColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

