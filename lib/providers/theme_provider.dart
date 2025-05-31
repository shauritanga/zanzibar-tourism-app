import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  bool isDarkMode() {
    return state == ThemeMode.dark;
  }

  bool isLightMode() {
    return state == ThemeMode.light;
  }
}

// class AppTheme {
//   static final lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primarySwatch: Colors.blue,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black,
//     ),
//     scaffoldBackgroundColor: Colors.white,
//     colorScheme: ColorScheme.fromSwatch().copyWith(
//       primary: Colors.blue,
//       secondary: Colors.green,
//     ),
//   );

//   static final darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primarySwatch: Colors.blue,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.black,
//       foregroundColor: Colors.white,
//     ),
//     scaffoldBackgroundColor: Colors.black,
//     colorScheme: ColorScheme.fromSwatch().copyWith(
//       primary: Colors.blue,
//       secondary: Colors.green,
//     ),
//   );
// }
