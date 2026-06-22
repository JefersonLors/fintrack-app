import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fin_track_theme.dart';

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.menuMaxHeight,
    this.hint,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final double? menuMaxHeight;
  final Widget? hint;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  final _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;

  bool get _open => _overlayEntry != null;

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open) {
      _closeMenu();
    }
  }

  @override
  void dispose() {
    _closeMenu();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    final enabled = widget.onChanged != null;
    final selected = _selectedItem;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: enabled ? colors.textPrimary : colors.textMuted,
      fontWeight: FontWeight.w600,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: InkWell(
          key: _fieldKey,
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? _toggleMenu : null,
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: widget.decoration.copyWith(
              filled: true,
              fillColor: colors.surface,
              enabled: enabled,
              labelStyle: TextStyle(color: colors.textMuted),
              floatingLabelStyle: TextStyle(color: colors.primary),
              suffixIcon: Icon(
                _open
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
            ),
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              child: selected?.child ?? widget.hint ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.initialValue) {
        return item;
      }
    }
    return null;
  }

  Future<void> _toggleMenu() async {
    if (_open) {
      _closeMenu();
    } else {
      final fieldContext = _fieldKey.currentContext;
      if (fieldContext != null) {
        final availableBelow = _availableBelow();
        final shouldReposition =
            availableBelow != null && availableBelow < _preferredMenuHeight();
        if (shouldReposition) {
          await Scrollable.ensureVisible(
            fieldContext,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: 0.18,
          );
          await WidgetsBinding.instance.endOfFrame;
        }
      }
      if (!mounted) {
        return;
      }
      _openMenu();
    }
  }

  void _openMenu() {
    final overlay = Overlay.of(context);
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final size = renderBox.size;
    final availableBelow = _availableBelow(size) ?? 72.0;
    final maxHeight = math.min(widget.menuMaxHeight ?? 320, availableBelow);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final colors = context.finTrackColors;
        final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: colors.surface,
                elevation: 8,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.borderStrong),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: size.width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: ScrollbarTheme(
                      data: ScrollbarTheme.of(context).copyWith(
                        thumbVisibility: const WidgetStatePropertyAll(true),
                        trackVisibility: const WidgetStatePropertyAll(true),
                        thickness: const WidgetStatePropertyAll(4),
                        radius: const Radius.circular(999),
                        thumbColor: WidgetStatePropertyAll(
                          colors.textMuted.withValues(alpha: 0.62),
                        ),
                        trackColor: WidgetStatePropertyAll(
                          colors.borderStrong.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < widget.items.length;
                                index++
                              ) ...[
                                InkWell(
                                  onTap: () {
                                    _closeMenu();
                                    widget.onChanged?.call(
                                      widget.items[index].value,
                                    );
                                  },
                                  child: SizedBox(
                                    width: size.width,
                                    height: 44,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: DefaultTextStyle.merge(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textStyle,
                                          child: widget.items[index].child,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (index < widget.items.length - 1)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: colors.borderStrong,
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
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  double _preferredMenuHeight() {
    final itemHeight = widget.items.length * 44.0;
    final dividerHeight = math.max(0, widget.items.length - 1).toDouble();
    return math.min(widget.menuMaxHeight ?? 320, itemHeight + dividerHeight);
  }

  double? _availableBelow([Size? fieldSize]) {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return null;
    }
    final size = fieldSize ?? renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final bottomReserved =
        mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom + 16;
    return math.max(
      72.0,
      mediaQuery.size.height - position.dy - size.height - bottomReserved,
    );
  }

  void _closeMenu() {
    final entry = _overlayEntry;
    if (entry == null) {
      return;
    }
    _overlayEntry = null;
    entry.remove();
    if (mounted) {
      setState(() {});
    }
  }
}
