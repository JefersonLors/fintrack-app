import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';
import 'configuration_section_widgets.dart';

class ExitTile extends StatelessWidget {
  const ExitTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: SettingsIcon(Icons.logout, color: color),
      title: Text(
        'Sair',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
      ),
      subtitle: Text(
        'Fechar o aplicativo',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({
    super.key,
    required this.lightModeSelected,
    required this.onChanged,
  });

  final bool lightModeSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    final selectedColor = colors.primary;
    return ToggleButtons(
      borderRadius: BorderRadius.circular(999),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
      color: colors.textMuted,
      selectedColor: selectedColor,
      fillColor: selectedColor.withValues(alpha: 0.16),
      borderColor: colors.borderStrong,
      selectedBorderColor: selectedColor.withValues(alpha: 0.72),
      isSelected: [!lightModeSelected, lightModeSelected],
      onPressed: (_) => onChanged(!lightModeSelected),
      children: const [
        Tooltip(
          message: 'Tema escuro',
          child: Icon(Icons.dark_mode_outlined, size: 20),
        ),
        Tooltip(
          message: 'Tema claro',
          child: Icon(Icons.light_mode_outlined, size: 20),
        ),
      ],
    );
  }
}
