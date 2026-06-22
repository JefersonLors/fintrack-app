import 'package:flutter/material.dart';

import '../theme/fin_track_theme.dart';

class FinTrackPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const FinTrackPageHeader({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.automaticallyImplyLeading = false,
  });

  final Widget title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = context.finTrackColors.textMuted;
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      foregroundColor: foreground,
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      title: title,
      actions: actions,
    );
  }
}
