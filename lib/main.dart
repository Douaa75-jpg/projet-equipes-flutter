import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:universal_html/html.dart' as html;
import './screens/acceuil/accueil_employe.dart';
import 'services/RH_service.dart';
import 'auth_controller.dart';
import 'theme_notifier.dart';
import 'theme.dart' as app_theme;
import 'screens/dashboard/employee_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/acceuil/accueil_chef_.dart';
import 'screens/acceuil/Accueil_RH.dart';
import 'DeconnexionScreen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/registre_screen.dart';
import 'services/auth_service.dart';
import 'services/pointage_service.dart';
import 'services/demande_service.dart';
import 'services/notification_service.dart';
import './screens/leave/gestion_demande__Screen.dart';
import 'locales/translation_service.dart'; // Import du service de traduction
import './services/Employe_Service.dart';
import './screens/choice_screen.dart';
import './services/chef_equipe_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialisation des dépendances
    await GetStorage.init();
    setPathUrlStrategy();

    // Initialisation des services
    await initializeServices();

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Erreur d\'initialisation: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'initialization_error'.tr,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: Text('try_again'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> initializeServices() async {
  try {
    tz.initializeTimeZones();

    Get.put(AuthService());
    Get.put(PointageService());
    Get.put(RhService());
    Get.put(DemandeService());
    Get.put(EmployeService());
    Get.put(ChefEquipeService());

    // Initialiser NotificationService
    final notificationService = NotificationService();
    await notificationService.initNotifications();
    Get.put(notificationService, permanent: true);

    Get.put(AuthProvider());

    final themeNotifier = Get.put(ThemeNotifier());
    await themeNotifier.initialize();
  } catch (e) {
    debugPrint('Erreur d\'initialisation des services: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: Get.find<ThemeNotifier>().isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: app_theme.lightTheme,
      darkTheme: app_theme.darkTheme,
      translations: TranslationService(), // Ajout du service de traduction
      locale: _getLocale(), // Langue par défaut ou celle sauvegardée
      fallbackLocale: const Locale('fr', 'FR'), // Langue de repli
      home: const ChoiceScreen(),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'AE'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(
            name: '/employee_dashboard', page: () => EmployeeDashboardScreen()),
        GetPage(name: '/deconnexion', page: () => const DeconnexionScreen()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/forgot-password', page: () => ForgotPasswordScreen()),
        GetPage(
          name: '/reset-password',
          page: () {
            final args = Get.parameters;
            final token = args['token'];
            return token != null
                ? ResetPasswordScreen(token: token)
                : LoginScreen();
          },
        ),
        GetPage(
          name: '/demandes',
          page: () => GestionDemandeScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<GestionDemandeController>(
                () => GestionDemandeController());
          }),
        ),
      ],
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: Center(child: Text('page_not_found'.tr)),
        ),
      ),
    );
  }

  Locale _getLocale() {
    final box = GetStorage();
    final locale = box.read('locale');
    if (locale != null) {
      return Locale(locale['languageCode'], locale['countryCode']);
    }
    return Get.deviceLocale ?? const Locale('fr', 'FR');
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService authService = Get.find<AuthService>();
  final AuthProvider authProvider = Get.find<AuthProvider>();
  final NotificationService notificationService =
      Get.find<NotificationService>();
  bool _initialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _handleWebDeepLink();
    _setupNotificationListener();
  }

  Future<void> _initializeAuth() async {
    try {
      await authService.verifyTokenStorage();

      if (authService.token.value.isNotEmpty) {
        await authProvider.checkAuthStatus();
        notificationService.setupListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
    } finally {
      setState(() {
        _initialCheckComplete = true;
      });
    }
  }

  void _handleWebDeepLink() {
    try {
      final uri = Uri.parse(html.window.location.href);
      if (uri.pathSegments.contains('reset-password')) {
        final token = uri.queryParameters['token'];
        if (token != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.toNamed(
              '/reset-password',
              arguments: {'token': token},
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur de traitement du deep link: $e');
    }
  }

  void _setupNotificationListener() {
    ever(authProvider.userId, (userId) {
      if (userId.isNotEmpty) {
        notificationService.setupListeners();
      }
    });

    notificationService.lastNotification.listen((message) {
      if (message.isNotEmpty) {
        Get.snackbar(
          'notification'.tr,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialCheckComplete) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authService.token.value.isNotEmpty ||
        authProvider.isAuthenticated.value) {
      final role = authService.role.value.isNotEmpty
          ? authService.role.value
          : authProvider.role.value;

      final typeResponsable = authService.typeResponsable.value.isNotEmpty
          ? authProvider.typeResponsable.value
          : authProvider.typeResponsable.value;
      switch (role) {
        case 'EMPLOYE':
          return const AccueilEmploye();
        case 'RESPONSABLE':
          if (typeResponsable == 'CHEF_EQUIPE' ||
              typeResponsable == 'CHEF D\'EQUIPE') {
            return const Accueilchef();
          } else if (typeResponsable == 'RH') {
            return const AccueilRh();
          } else {
            return LoginScreen();
          }
        default:
          return LoginScreen();
      }
    } else {
      return LoginScreen();
    }
  }
}
