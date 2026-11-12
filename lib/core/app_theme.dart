import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const green = Color(0xFF205C4A);
  static const background = Color(0xFFFAF8F2);
  static const gold = Color(0xFFB58A45);

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(seedColor: green, surface: background),
    scaffoldBackgroundColor: background,
  );
}
