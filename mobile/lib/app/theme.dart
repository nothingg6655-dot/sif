import 'package:flutter/material.dart';

ThemeData appTheme(Brightness brightness) {
  final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF), brightness: brightness);
  return ThemeData(useMaterial3: true, colorScheme: colors,
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF8FAFC) : const Color(0xFF090D16),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
    cardTheme: CardThemeData(elevation: 0, margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colors.outlineVariant))),
  );
}
