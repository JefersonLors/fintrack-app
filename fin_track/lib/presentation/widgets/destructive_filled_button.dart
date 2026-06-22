import 'package:flutter/material.dart';

import '../theme/fin_track_theme.dart';

ButtonStyle destructiveFilledButtonStyle(BuildContext context) {
  final colors = context.finTrackColors;
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: colors.danger,
    foregroundColor: scheme.onError,
    iconColor: scheme.onError,
  );
}
