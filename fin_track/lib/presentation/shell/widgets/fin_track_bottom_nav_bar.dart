import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';

class FinTrackBottomNavBar extends StatelessWidget {
  const FinTrackBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.dragProgress,
    required this.captureBusy,
    required this.onSelect,
    required this.onCapture,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final int selectedIndex;
  final double dragProgress;
  final bool captureBusy;
  final ValueChanged<int> onSelect;
  final VoidCallback onCapture;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.finTrackColors;
    final scannerBorderColor = Color.alphaBlend(
      scheme.onPrimary.withValues(alpha: 0.20),
      colors.primary,
    );
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    selected: selectedIndex == 0,
                    icon: Icons.manage_search_outlined,
                    selectedIcon: Icons.manage_search,
                    label: 'Busca',
                    onTap: () => onSelect(0),
                  ),
                  _NavItem(
                    selected: selectedIndex == 1,
                    icon: Icons.category_outlined,
                    selectedIcon: Icons.category,
                    label: 'Categorias',
                    onTap: () => onSelect(1),
                  ),
                  _CaptureButton(
                    progress: dragProgress,
                    busy: captureBusy,
                    borderColor: scannerBorderColor,
                    onTap: onCapture,
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                    onDragCancel: onDragCancel,
                  ),
                  _NavItem(
                    selected: selectedIndex == 2,
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: 'Relatórios',
                    onTap: () => onSelect(2),
                  ),
                  _NavItem(
                    selected: selectedIndex == 3,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Ajustes',
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.finTrackColors;
    final activeColor = colors.info;
    final foreground = selected ? activeColor : colors.textMuted;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 50,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? activeColor.withValues(alpha: 0.36)
                    : scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return activeColor.withValues(alpha: 0.16);
                  }
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)) {
                    return activeColor.withValues(alpha: 0.08);
                  }
                  return Colors.transparent;
                }),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: foreground,
                        size: 35,
                      ),
                      const SizedBox(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontSize: 8.5,
                                  height: 1,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.progress,
    required this.busy,
    required this.borderColor,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final double progress;
  final bool busy;
  final Color borderColor;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.finTrackColors;
    final visualProgress = Curves.easeInOutCubic.transform(progress);
    final cameraOut = ((progress - 0.08) / 0.62).clamp(0.0, 1.0);
    final searchIn = ((progress - 0.32) / 0.68).clamp(0.0, 1.0);
    final cameraOpacity = 1 - Curves.easeIn.transform(cameraOut);
    final searchOpacity = Curves.easeOut.transform(searchIn);
    final buttonSize = 70 + (visualProgress * 5);
    const tapTargetSize = 101.0;

    return Expanded(
      child: Center(
        child: OverflowBox(
          maxWidth: 133,
          maxHeight: 133,
          child: Transform.translate(
            offset: Offset(0, -24 - (visualProgress * 44)),
            child: Tooltip(
              message: 'Escanear comprovante',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: busy ? null : onTap,
                onVerticalDragUpdate: busy ? null : onDragUpdate,
                onVerticalDragEnd: busy ? null : onDragEnd,
                onVerticalDragCancel: busy ? null : onDragCancel,
                child: SizedBox.square(
                  dimension: tapTargetSize,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutQuart,
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          colors.primary,
                          colors.info,
                          visualProgress,
                        ),
                        border: Border.all(color: borderColor, width: 2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(
                              alpha: 0.24 + (visualProgress * 0.10),
                            ),
                            blurRadius: 18 + (visualProgress * 12),
                            offset: Offset(0, 9 + (visualProgress * 7)),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (busy)
                            SizedBox.square(
                              dimension: 29,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: scheme.onPrimary,
                              ),
                            )
                          else ...[
                            Transform.scale(
                              scale: 1 - (cameraOut * 0.18),
                              child: Opacity(
                                opacity: cameraOpacity,
                                child: Icon(
                                  Icons.document_scanner_outlined,
                                  size: 50,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.72 + (searchOpacity * 0.34),
                              child: Opacity(
                                opacity: searchOpacity,
                                child: Icon(
                                  Icons.search,
                                  size: 45,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
