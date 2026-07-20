import 'package:flutter/material.dart';

class AppTheme {
  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF6F7F8);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        height: 1.3,
        color: Colors.black,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _bg,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      // 👇 hint
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
      ),

      // 👇 cursor
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
      ),

      // 👇 النص كله أسود
      textTheme: textTheme,

      primaryTextTheme: textTheme,
    );
  }
}