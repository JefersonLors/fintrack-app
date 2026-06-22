import 'package:flutter/widgets.dart';

import '../../bootstrap/fin_track_dependencies.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final FinTrackDependencies dependencies;

  static FinTrackDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree.');
    return scope!.dependencies;
  }

  static FinTrackDependencies? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()?.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return oldWidget.dependencies != dependencies;
  }
}
