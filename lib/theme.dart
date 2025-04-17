import 'package:flutter/material.dart';

class AppColors {
  // Couleurs inspirées du logo ZETABOX
  static const Color primary = Color(0xFFB31A1A); // Rouge foncé
  static const Color secondary = Color(0xFF880E4F); // Bordeaux
  static const Color accent = Color(0xFFE53935); // Rouge clair pour boutons
  static const Color surfaceLight = Color(0xFFF5F5F5); // Fond clair
  static const Color surfaceDark = Color(0xFF121212); // Fond sombre
  static const Color textDark = Color(0xFF212121); // Texte sur fond clair
  static const Color textLight = Color(0xFFE0E0E0); // Texte sur fond sombre
}

// Thème clair
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceLight,
    background: AppColors.surfaceLight,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textDark,
  ),
  scaffoldBackgroundColor: AppColors.surfaceLight,
  textTheme: _buildTextTheme(AppColors.textDark),
  appBarTheme: _buildAppBarTheme(AppColors.primary),
  elevatedButtonTheme: _buildButtonTheme(AppColors.accent),
  inputDecorationTheme: _buildInputTheme(AppColors.primary, Colors.grey.shade400),
  cardTheme: _buildCardTheme(),
  drawerTheme: DrawerThemeData(backgroundColor: Colors.white),
);

// Thème sombre
final ThemeData darkTheme = ThemeData.dark().copyWith(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceDark,
    background: AppColors.surfaceDark,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textLight,
  ),
  scaffoldBackgroundColor: AppColors.surfaceDark,
  textTheme: _buildTextTheme(AppColors.textLight),
  appBarTheme: _buildAppBarTheme(AppColors.primary),
  elevatedButtonTheme: _buildButtonTheme(AppColors.accent),
  inputDecorationTheme: _buildInputTheme(AppColors.primary, Colors.grey.shade700),
  cardTheme: _buildCardTheme(),
  drawerTheme: DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),
);

// TextTheme
TextTheme _buildTextTheme(Color textColor) {
  return TextTheme(
    displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
    bodyLarge: TextStyle(fontSize: 16, color: textColor),
    bodyMedium: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
  );
}

// ButtonTheme
ElevatedButtonThemeData _buildButtonTheme(Color color) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      elevation: 4,
      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );
}

// Input Theme
InputDecorationTheme _buildInputTheme(Color primaryColor, Color borderColor) {
  return InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    labelStyle: TextStyle(fontSize: 16),
  );
}

// AppBar Theme
AppBarTheme _buildAppBarTheme(Color color) {
  return AppBarTheme(
    backgroundColor: color,
    foregroundColor: Colors.white,
    elevation: 3,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  );
}

// Card Theme
CardTheme _buildCardTheme() {
  return CardTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    margin: EdgeInsets.all(12),
    clipBehavior: Clip.antiAlias,
  );
}
