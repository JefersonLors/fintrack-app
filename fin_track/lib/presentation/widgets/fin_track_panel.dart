import 'package:flutter/material.dart';

import '../theme/fin_track_theme.dart';

class FinTrackPanel extends StatelessWidget {
  const FinTrackPanel({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.padding,
    this.material = false,
  });

  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool material;

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (material) {
      content = Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        border: Border.all(color: borderColor ?? colors.borderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}

class FinTrackDividedPanel extends StatelessWidget {
  const FinTrackDividedPanel({
    super.key,
    required this.children,
    this.borderColor,
    this.backgroundColor,
    this.material = false,
  });

  final List<Widget> children;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool material;

  @override
  Widget build(BuildContext context) {
    return FinTrackPanel(
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      material: material,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
