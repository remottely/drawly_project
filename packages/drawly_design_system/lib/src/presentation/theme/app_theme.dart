import 'package:drawly_design_system/src/src.dart';
import 'package:flutter/material.dart';

const Color kCanvasColor = Color(0xfff2f3f7);

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.lightPrimary,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: AppColors.lightAccent,
    brightness: Brightness.light,
  ),
  // scaffoldBackgroundColor: lightBG,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightPrimary.withOpacity(0.7),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: InputBorder.none,
    focusedBorder: InputBorder.none,
  ),
);
