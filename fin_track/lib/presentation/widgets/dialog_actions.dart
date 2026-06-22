import 'package:flutter/material.dart';

class FinTrackDialogActions extends StatelessWidget {
  const FinTrackDialogActions({
    super.key,
    required this.children,
    this.minButtonWidth = 96,
    this.spacing = 8,
  });

  final List<Widget> children;
  final double minButtonWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      overflowDirection: VerticalDirection.down,
      spacing: spacing,
      overflowSpacing: spacing,
      children: [
        for (final child in children)
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: minButtonWidth),
            child: child,
          ),
      ],
    );
  }
}
