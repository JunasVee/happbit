import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local app-lock controller.
///
/// This does NOT use Supabase. We store the PIN locally using
/// Keychain (iOS) / Keystore (Android) via flutter_secure_storage.
///
/// Behavior:
/// - If enabled: the app starts "locked" each launch.
/// - When app goes to background, it becomes locked again.
/// - User must enter the PIN to unlock.
class AppLockController extends ChangeNotifier {
  static const String _kEnabledKey = 'happbit_app_lock_enabled';
  static const String _kPinKey = 'happbit_app_lock_pin';

  // flutter_secure_storage options are platform-default and secure.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _enabled = false;
  bool _locked = false;
  String? _pin; // stored in-memory for quick compares

  bool get enabled => _enabled;
  bool get locked => _locked;
  bool get hasPin => (_pin != null && _pin!.isNotEmpty);

  /// Load stored state.
  ///
  /// Call once before runApp.
  Future<void> load() async {
    final enabledStr = await _storage.read(key: _kEnabledKey);
    _enabled = enabledStr == '1';

    _pin = await _storage.read(key: _kPinKey);

    // On cold start: if enabled, require unlock.
    _locked = _enabled;

    notifyListeners();
  }

  /// Enable/disable app lock.
  ///
  /// When disabling, we also mark the current session as unlocked.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _storage.write(key: _kEnabledKey, value: value ? '1' : '0');

    if (!value) {
      _locked = false;
    } else {
      // If enabling and a PIN already exists, do not force an immediate lock.
      // The lock will trigger on next background/foreground cycle (and next launch).
      // If you want to lock instantly, call lockNow().
      _locked = _locked || false;
    }

    notifyListeners();
  }

  /// Set or replace the PIN.
  ///
  /// This does NOT automatically enable lock; call setEnabled(true) separately.
  Future<void> setPin(String pin) async {
    _pin = pin;
    await _storage.write(key: _kPinKey, value: pin);
    notifyListeners();
  }

  /// Verify a PIN attempt.
  ///
  /// Returns true if correct and unlocks the app.
  Future<bool> verifyAndUnlock(String pinAttempt) async {
    // Always read from memory (loaded at startup / updated on setPin)
    final ok = (_pin != null && _pin == pinAttempt);
    if (ok) {
      _locked = false;
      notifyListeners();
    }
    return ok;
  }

  /// Lock immediately (only if enabled).
  void lockNow() {
    if (!_enabled) return;
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  /// Unlock without verifying (use sparingly; usually only after setting a new PIN).
  void unlockNow() {
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }

  /// Optional: remove saved PIN (also disables lock).
  Future<void> clearPinAndDisable() async {
    _pin = null;
    _enabled = false;
    _locked = false;
    await _storage.delete(key: _kPinKey);
    await _storage.write(key: _kEnabledKey, value: '0');
    notifyListeners();
  }
}
