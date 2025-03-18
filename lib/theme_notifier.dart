import 'package:flutter/material.dart';

// Fournisseur de gestion du thème
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notifie les consommateurs lorsque le thème change
  }
}

// Fournisseur de gestion de la langue
class LanguageNotifier extends ChangeNotifier {
  Locale _locale = Locale('en', 'US'); // langue par défaut

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners(); // Notifie les consommateurs lorsque la langue change
    }
  }
}

// Thèmes à appliquer
final ThemeData appTheme = ThemeData.light(); // Thème clair
final ThemeData darkTheme = ThemeData.dark();  // Thème sombre
