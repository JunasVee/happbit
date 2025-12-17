import 'package:flutter/widgets.dart';

import '../services/app_lock_controller.dart';
import '../services/app_settings.dart';

/// Makes app-wide controllers available to the widget tree
/// without adding external state-management packages.
class AppControllers extends InheritedWidget {
  const AppControllers({
    super.key,
    required this.settings,
    required this.lock,
    required super.child,
  });

  final AppSettings settings;
  final AppLockController lock;

  static AppControllers of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<AppControllers>();
    assert(w != null, 'AppControllers not found in widget tree');
    return w!;
  }

  @override
  bool updateShouldNotify(AppControllers oldWidget) {
    return settings != oldWidget.settings || lock != oldWidget.lock;
  }
}
