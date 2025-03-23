import 'package:flutter/material.dart';

// Définition des couleurs principales
class AppColors {
  static const Color primary = Color(0xFFD32F2F); // Rouge
  static const Color secondary = Color(0xFFD32F2F); // Bleu
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Colors.black;
  static const Color textLight = Colors.black87;
  static const Color textDark = Colors.white70;
}

// Définition du thème clair
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.lightSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: AppColors.lightSurface,
  textTheme: _buildTextTheme(AppColors.textLight),
  elevatedButtonTheme: _buildButtonTheme(AppColors.primary),
  inputDecorationTheme: _buildInputTheme(AppColors.primary, Colors.grey.shade400),
  appBarTheme: _buildAppBarTheme(AppColors.primary),
);

// Définition du thème sombre
final ThemeData darkTheme = ThemeData.dark().copyWith(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.darkSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.darkSurface,
  textTheme: _buildTextTheme(AppColors.textDark),
  elevatedButtonTheme: _buildButtonTheme(AppColors.primary),
  inputDecorationTheme: _buildInputTheme(AppColors.primary, Colors.grey.shade700),
  appBarTheme: _buildAppBarTheme(AppColors.primary),
);

// Fonction pour générer le TextTheme
TextTheme _buildTextTheme(Color textColor) {
  return TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
    bodyLarge: TextStyle(fontSize: 16, color: textColor),
    bodyMedium: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
  );
}

// Fonction pour générer le ElevatedButtonThemeData
ElevatedButtonThemeData _buildButtonTheme(Color color) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      elevation: 3,
    ),
  );
}

// Fonction pour générer l'InputDecorationTheme
InputDecorationTheme _buildInputTheme(Color primaryColor, Color borderColor) {
  return InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    labelStyle: TextStyle(color: Colors.white70, fontSize: 16),
  );
}

// Fonction pour générer l'AppBarTheme
AppBarTheme _buildAppBarTheme(Color color) {
  return AppBarTheme(
    backgroundColor: color,
    elevation: 2,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  );
}
