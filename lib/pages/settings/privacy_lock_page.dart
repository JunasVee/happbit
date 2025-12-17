import 'package:flutter/material.dart';

import '../../services/app_lock_controller.dart';
import '../../widgets/app_controllers.dart';

class PrivacyLockPage extends StatefulWidget {
  const PrivacyLockPage({super.key});

  @override
  State<PrivacyLockPage> createState() => _PrivacyLockPageState();
}

class _PrivacyLockPageState extends State<PrivacyLockPage> {
  late final AppLockController _lock;
  bool _processing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lock = AppControllers.of(context).lock;
  }

  Future<void> _toggle(bool value) async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    try {
      if (value) {
        // Enabling lock
        if (!_lock.hasPin) {
          final pin = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const _SetPinPage()),
          );

          if (pin == null) {
            // User cancelled setting a PIN. Keep lock disabled.
            await _lock.setEnabled(false);
            return;
          }

          await _lock.setPin(pin);
        }

        await _lock.setEnabled(true);

        // Current session stays unlocked.
        _lock.unlockNow();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App lock enabled')),
          );
        }
      } else {
        // Disabling lock
        await _lock.setEnabled(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App lock disabled')),
          );
        }
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _changePin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _ChangePinPage()),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated')),
      );
    }
  }

  Future<void> _resetPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove app lock?'),
          content: const Text(
            'This will disable the app lock and remove your saved PIN on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _lock.clearPinAndDisable();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock removed')),
      );
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
        title: const Text('Privacy Lock'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: AnimatedBuilder(
        animation: _lock,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'App lock',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Require a 4-digit PIN when opening HappBit.',
                  ),
                  value: _lock.enabled,
                  onChanged: _processing ? null : _toggle,
                ),
              ),
              const SizedBox(height: 12),

              if (_lock.enabled) ...[
                Container(
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: const Text(
                      'Change PIN',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _changePin,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: theme.colorScheme.error),
                    title: Text(
                      'Remove app lock',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    onTap: _resetPin,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'When enabled, HappBit will lock whenever the app goes to the background, and it will require your PIN again when you return.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SetPinPage extends StatefulWidget {
  const _SetPinPage();

  @override
  State<_SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<_SetPinPage> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  void _save() {
    final a = _pin1.text.trim();
    final b = _pin2.text.trim();

    if (a.length != 4 || b.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    if (a != b) {
      setState(() => _error = "PINs don't match");
      return;
    }

    Navigator.of(context).pop(a);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set PIN'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Create a 4-digit PIN',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will need this PIN every time you open HappBit when App lock is enabled.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pin1,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin2,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const Spacer(),
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
                onPressed: _save,
                child: const Text('Save PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePinPage extends StatefulWidget {
  const _ChangePinPage();

  @override
  State<_ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<_ChangePinPage> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lock = AppControllers.of(context).lock;

    final current = _current.text.trim();
    final newPin = _newPin.text.trim();
    final confirm = _confirm.text.trim();

    if (newPin.length != 4 || confirm.length != 4) {
      setState(() => _error = 'New PIN must be 4 digits');
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = "New PINs don't match");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await lock.verifyAndUnlock(current);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _saving = false;
        _error = 'Current PIN is incorrect';
      });
      return;
    }

    await lock.setPin(newPin);

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _current,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const Spacer(),
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
      ),
    );
  }
}
