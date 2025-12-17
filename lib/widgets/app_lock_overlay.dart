import 'package:flutter/material.dart';

import '../services/app_lock_controller.dart';

/// Simple app-wide lock overlay.
///
/// Place this above your whole app (MaterialApp.builder) so that
/// when lock is enabled and currently locked, it blocks all interaction
/// until the correct PIN is entered.
class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({super.key, required this.child, required this.lock});

  final Widget child;
  final AppLockController lock;

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock whenever the app is no longer active. This ensures:
    // - cold start -> locked (handled in controller.load())
    // - resume from background -> locked
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      widget.lock.lockNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.lock,
      builder: (context, _) {
        final showLock = widget.lock.enabled && widget.lock.locked;

        return Stack(
          children: [
            widget.child,
            if (showLock)
              const _LockBarrier(),
            if (showLock)
              Positioned.fill(
                child: _PinUnlockScreen(lock: widget.lock),
              ),
          ],
        );
      },
    );
  }
}

class _LockBarrier extends StatelessWidget {
  const _LockBarrier();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ModalBarrier(
        dismissible: false,
        color: Colors.black.withOpacity(0.45),
      ),
    );
  }
}

class _PinUnlockScreen extends StatefulWidget {
  const _PinUnlockScreen({required this.lock});

  final AppLockController lock;

  @override
  State<_PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<_PinUnlockScreen> {
  final _pinCtrl = TextEditingController();
  bool _wrong = false;
  bool _submitting = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pin = _pinCtrl.text.trim();

    if (pin.length != 4) {
      setState(() => _wrong = true);
      return;
    }

    setState(() {
      _submitting = true;
      _wrong = false;
    });

    final ok = await widget.lock.verifyAndUnlock(pin);

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _wrong = !ok;
    });

    if (ok) {
      _pinCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'App Locked',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your 4-digit PIN to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      errorText: _wrong ? 'Incorrect PIN' : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),

                  const SizedBox(height: 12),

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
                      onPressed: _submitting ? null : _unlock,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Unlock'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Forgot your PIN? You'll need to clear app data / reinstall to reset it.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
