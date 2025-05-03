import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthProvider.dart';
import 'theme_notifier.dart';
import 'theme.dart' as app_theme;
import 'screens/splash_screen.dart';
import './screens/dashboard/employee_dashboard_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'DeconnexionScreen.dart';
import 'package:gestion_equipe_flutter/screens/auth/forgot_password_screen.dart';
import 'package:gestion_equipe_flutter/screens/auth/reset_password_screen.dart';
import 'screens/auth/registre_screen.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:uni_links/uni_links.dart'; // Add this package for deep linking
import 'dart:async'; // For StreamSubscription

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> initUniLinks() async {
    // Handle links when app is initially opened
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle links when app is already running
    _sub = linkStream.listen((String? link) {
      if (link != null) _handleDeepLink(link);
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    if (uri.pathSegments.contains('reset-password')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        // Navigate to reset password screen
        Navigator.of(context).pushNamed(
          '/reset-password',
          arguments: {'token': token},
        );
      }
    }
  }

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
                ? app_theme.darkTheme
                : app_theme.lightTheme,
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/employee_dashboard': (context) => EmployeeDashboardScreen(),
              '/deconnexion': (context) => const DeconnexionScreen(),
              '/register': (context) => RegisterPage(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/reset-password': (context) {
                final args = ModalRoute.of(context)!.settings.arguments 
                    as Map<String, dynamic>?;
                final token = args?['token'] as String?;
                if (token == null) {
                  // Handle error case - maybe redirect to login
                  return const LoginScreen();
                }
                return ResetPasswordScreen(token: token);
              },
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
            onGenerateRoute: (settings) {
              // Handle web URLs when app is opened from a browser
              if (settings.name?.startsWith('/reset-password') ?? false) {
                final uri = Uri.parse(settings.name!);
                final token = uri.queryParameters['token'];
                if (token != null) {
                  return MaterialPageRoute(
                    builder: (context) => ResetPasswordScreen(token: token),
                    settings: settings,
                  );
                }
              }
              // Default case - show 404 or redirect
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}