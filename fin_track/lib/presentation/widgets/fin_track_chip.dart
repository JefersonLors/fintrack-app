import 'package:flutter/material.dart';

import '../theme/fin_track_theme.dart';

class FinTrackChip extends StatelessWidget {
  const FinTrackChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    this.maxWidth = 180,
    this.textStyle,
    this.scrollable = false,
    this.semanticLabel,
    this.tooltip,
  });

  final IconData? icon;
  final String label;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final TextStyle? textStyle;
  final bool scrollable;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.finTrackColors.textMuted;
    final labelStyle =
        textStyle ??
        Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: color == null ? FontWeight.w500 : FontWeight.w700,
        );
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: scrollable ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: false,
      style: labelStyle,
    );

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: color == null
            ? context.finTrackColors.surfaceAlt
            : color!.withValues(alpha: 0.10),
        border: Border.all(
          color:
              color?.withValues(alpha: 0.34) ??
              context.finTrackColors.borderStrong,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: scrollable
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: labelWidget,
                    )
                  : labelWidget,
            ),
          ],
        ),
      ),
    );
    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(label: semanticLabel ?? label, child: chip),
    );
  }
}

class FinTrackMetricChip extends StatelessWidget {
  const FinTrackMetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.width = 136,
    this.semanticLabel,
    this.tooltip,
  });

  final String label;
  final int value;
  final Color color;
  final double width;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = SizedBox(
      width: width,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  value.toString(),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final description = semanticLabel ?? '$label: $value';
    return Tooltip(
      message: tooltip ?? description,
      child: Semantics(label: description, child: chip),
    );
  }
}
