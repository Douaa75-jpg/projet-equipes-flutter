import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart' as themeNotifier;  // Ajout d'un alias
import 'theme.dart' as theme;  // Ajout d'un alias
import 'splash_screen.dart'; // Importer le SplashScreen
import 'theme_notifier.dart'; // Assurez-vous que vous avez aussi importé theme_notifier.dart pour LanguageNotifier
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeNotifier.ThemeNotifier(),
      child: ChangeNotifierProvider(
        create: (_) => LanguageNotifier(), // Fournir LanguageNotifier
        child: Builder(
          builder: (context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: Provider.of<themeNotifier.ThemeNotifier>(context).isDarkMode
                  ? theme.darkTheme  // Utiliser l'alias "theme" pour le darkTheme
                  : theme.appTheme, // Utiliser l'alias "theme" pour l'appTheme
              home: const SplashScreen(), // Afficher le SplashScreen en premier
              locale: Provider.of<LanguageNotifier>(context).locale, // Langue dynamique
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
      ),
    );
  }
}
