import 'package:flutter/material.dart';

class AppThemePreset {
  final String key;
  final String label;
  final Color seedColor;

  const AppThemePreset({
    required this.key,
    required this.label,
    required this.seedColor,
  });
}

class AppThemes {
  AppThemes._();

  static const String defaultKey = 'default';
  static const String customKey = 'custom';

  static const List<AppThemePreset> presets = [
    AppThemePreset(key: defaultKey, label: 'Default', seedColor: Colors.blueAccent),
    AppThemePreset(key: 'purple', label: 'Purple', seedColor: Color(0xFF8D5CF6)),
    AppThemePreset(key: 'pink', label: 'Pink', seedColor: Color(0xFFFE8BCD)),
    AppThemePreset(key: 'orange', label: 'Orange', seedColor: Color(0xFFD4943A)),
    AppThemePreset(key: 'green', label: 'Green', seedColor: Color(0xFF22C55E)),
  ];

  static Color seedFor({
    required String? themeKey,
    required int? themeSeedColor,
  }) {
    final key = (themeKey ?? '').trim();
    if (key == customKey && themeSeedColor != null) {
      return Color(themeSeedColor);
    }
    final match = presets.where((p) => p.key == key).toList();
    if (match.isNotEmpty) return match.first.seedColor;
    return presets.first.seedColor;
  }

  static String labelFor({
    required String? themeKey,
    required int? themeSeedColor,
  }) {
    final key = (themeKey ?? '').trim();
    if (key == customKey && themeSeedColor != null) {
      return 'Custom';
    }
    final match = presets.where((p) => p.key == key).toList();
    if (match.isNotEmpty) return match.first.label;
    return presets.first.label;
  }

  static ThemeData light({required Color seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey.shade100,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark({required Color seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
    );
  }
}
