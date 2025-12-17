import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _auth = AuthService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  String _timezone = 'Asia/Jakarta';
  bool _loading = false;
  bool _initializing = true;

  final List<String> _timezones = const [
    'Asia/Jakarta',
    'Asia/Makassar',
    'Asia/Jayapura',
    'UTC',
  ];

  @override
  void initState() {
    super.initState();
    // So the avatar letter updates live when the name changes
    _nameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('profiles')
          .select('display_name, email, timezone')
          .eq('id', user.id)
          .maybeSingle();

      final displayName = (data?['display_name'] as String?) ?? '';
      final email = (data?['email'] as String?) ?? user.email ?? '';
      final tz = (data?['timezone'] as String?) ?? _timezone;

      if (!mounted) return;

      _nameCtrl.text = displayName;
      _emailCtrl.text = email;

      setState(() {
        if (tz.isNotEmpty) {
          _timezone = tz;
        }
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (!mounted) return;
      _emailCtrl.text = user.email ?? '';
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is signed in')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': name,
        'email': email,
        'timezone': _timezone,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      // Pop with "true" so SettingsPage knows it should refresh the name
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final cs = theme.colorScheme;
    final fill = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: cs.onBackground,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _initializing
                  ? const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.black,
                            child: Text(
                              (_nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text[0]
                                      : 'A')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Update your personal information',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Display name
                        _ProfileTextField(
                          controller: _nameCtrl,
                          label: 'Display name',
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),

                        // Email (read-only for now)
                        _ProfileTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          prefix: const Icon(Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Timezone dropdown
                        Text(
                          'Time zone',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          elevation: isDark ? 0 : 4,
                          shadowColor: Colors.black12,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _timezones.contains(_timezone)
                                    ? _timezone
                                    : _timezones.first,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                iconEnabledColor: theme.colorScheme.onSurface,
                                items: _timezones
                                    .map(
                                      (tz) =>
                                          DropdownMenuItem<String>(
                                        value: tz,
                                        child: Text(tz),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _timezone = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Save changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.prefix,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fill = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.black87;
    
    return Material(
      elevation: isDark ? 0 : 4,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor),
          filled: true,
          fillColor: fill,
          prefixIcon: prefix,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: border),
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: border),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
