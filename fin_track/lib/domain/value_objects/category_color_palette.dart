class CategoryColorPalette {
  const CategoryColorPalette._();

  static const primary = 0xFF5F8FA3;
  static const noColor = 0xFFD2D8E3;
  static const info = 0xFF7F9BAE;
  static const blue = 0xFF7AA7E8;
  static const mint = 0xFF8ED1C6;

  static const values = <int>[noColor, primary, info, blue, mint];
}

int normalizeCategoryColorArgb(int argb) {
  return switch (argb) {
    0xFFC47A4A => CategoryColorPalette.noColor,
    0xFFDFA85B => CategoryColorPalette.noColor,
    0xFF74C69D => CategoryColorPalette.mint,
    0xFFB98CE8 => CategoryColorPalette.info,
    0xFFA9A7D9 => CategoryColorPalette.noColor,
    0xFFD6B86F => CategoryColorPalette.noColor,
    0xFFE88AA2 => CategoryColorPalette.noColor,
    0xFFB08AC7 => CategoryColorPalette.noColor,
    0xFFD56B6B => CategoryColorPalette.noColor,
    0xFF6FD6C4 => CategoryColorPalette.mint,
    0xFFA8B0BE => CategoryColorPalette.info,
    0xFF6FAF7A => CategoryColorPalette.mint,
    _ when CategoryColorPalette.values.contains(argb) => argb,
    _ => CategoryColorPalette.noColor,
  };
}
