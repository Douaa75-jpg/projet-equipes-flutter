import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthProvider.dart';  // Assurez-vous d'importer AuthProvider
import 'theme_notifier.dart';
import 'theme.dart' as app_theme; // Utilisation d'un alias pour le thème
import 'splash_screen.dart';
import './screens/dashboard/employee_dashboard_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),  // Ajout d'AuthProvider
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageNotifier()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Provider.of<ThemeNotifier>(context).isDarkMode
                ? app_theme.darkTheme // Utilisation du thème sombre
                : app_theme.lightTheme, // Utilisation du thème clair
            routes: {
              '/': (context) => const SplashScreen(), // Page d'accueil (SplashScreen)
              '/employee_dashboard': (context) =>
                  const EmployeeDashboardScreen(), // Dashboard pour l'employé
            },
            locale: Provider.of<LanguageNotifier>(context).locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ar', 'AE'),
            ],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
