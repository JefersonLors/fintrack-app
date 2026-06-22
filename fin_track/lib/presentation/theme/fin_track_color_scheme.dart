part of 'fin_track_theme.dart';

class FinTrackColors {
  const FinTrackColors._();

  static const background = Color(0xFF171C26);
  static const surface = Color(0xFF202736);
  static const surfaceAlt = Color(0xFF293142);
  static const border = Color(0xFF3D4658);
  static const primary = Color(0xFF5F8FA3);
  static const income = Color(0xFF6FAF7A);
  static const expense = Color(0xFFC47A4A);
  static const receiptType = primary;
  static const paymentMethod = Color(0xFF9CB6E8);
  static const backup = Color(0xFF8ED1C6);
  static const info = Color(0xFF7F9BAE);
  static const danger = Color(0xFFD56B6B);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFFD2D8E3);
  static const textMuted = Color(0xFFA8B0BE);
}

@immutable
class FinTrackColorScheme extends ThemeExtension<FinTrackColorScheme> {
  const FinTrackColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.income,
    required this.expense,
    required this.receiptType,
    required this.paymentMethod,
    required this.backup,
    required this.info,
    required this.danger,
    required this.neutralAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const dark = FinTrackColorScheme(
    background: FinTrackColors.background,
    surface: FinTrackColors.surface,
    surfaceAlt: FinTrackColors.surfaceAlt,
    border: FinTrackColors.border,
    borderStrong: FinTrackColors.border,
    primary: FinTrackColors.primary,
    income: FinTrackColors.income,
    expense: FinTrackColors.expense,
    receiptType: FinTrackColors.receiptType,
    paymentMethod: FinTrackColors.paymentMethod,
    backup: FinTrackColors.backup,
    info: FinTrackColors.info,
    danger: FinTrackColors.danger,
    neutralAccent: FinTrackColors.textSecondary,
    textPrimary: FinTrackColors.textPrimary,
    textSecondary: FinTrackColors.textSecondary,
    textMuted: FinTrackColors.textMuted,
  );

  static const light = FinTrackColorScheme(
    background: Color(0xFFF6F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE8EDF4),
    border: Color(0xFFD4DCE8),
    borderStrong: Color(0xFFB8C5D6),
    primary: Color(0xFF456F82),
    income: Color(0xFF2F8F6B),
    expense: Color(0xFFB85C5C),
    receiptType: Color(0xFF456F82),
    paymentMethod: Color(0xFF506FA9),
    backup: Color(0xFF328D80),
    info: Color(0xFF58798D),
    danger: Color(0xFFB84F4F),
    neutralAccent: Color(0xFF5F8FA3),
    textPrimary: Color(0xFF243647),
    textSecondary: Color(0xFF344154),
    textMuted: Color(0xFF647184),
  );

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color income;
  final Color expense;
  final Color receiptType;
  final Color paymentMethod;
  final Color backup;
  final Color info;
  final Color danger;
  final Color neutralAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  @override
  FinTrackColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? income,
    Color? expense,
    Color? receiptType,
    Color? paymentMethod,
    Color? backup,
    Color? info,
    Color? danger,
    Color? neutralAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return FinTrackColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      receiptType: receiptType ?? this.receiptType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      backup: backup ?? this.backup,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      neutralAccent: neutralAccent ?? this.neutralAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  FinTrackColorScheme lerp(
    ThemeExtension<FinTrackColorScheme>? other,
    double t,
  ) {
    if (other is! FinTrackColorScheme) {
      return this;
    }
    return FinTrackColorScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      receiptType: Color.lerp(receiptType, other.receiptType, t)!,
      paymentMethod: Color.lerp(paymentMethod, other.paymentMethod, t)!,
      backup: Color.lerp(backup, other.backup, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      neutralAccent: Color.lerp(neutralAccent, other.neutralAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension FinTrackThemeContext on BuildContext {
  FinTrackColorScheme get finTrackColors {
    return Theme.of(this).extension<FinTrackColorScheme>() ??
        FinTrackColorScheme.dark;
  }
}
