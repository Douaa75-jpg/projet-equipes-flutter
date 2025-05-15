import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeNotifier extends GetxController {
  // Instance de GetStorage pour la persistance
  final _storage = GetStorage();
  final String _storageKey = 'isDarkMode';

  // Observable pour le mode sombre
  final RxBool _isDarkMode = false.obs;

  // Getter pour accéder à la valeur
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }

  // Charger la préférence de thème depuis le stockage local
  Future<void> _loadThemePreference() async {
    try {
      _isDarkMode.value = _storage.read<bool>(_storageKey) ?? false;
    } catch (e) {
      // En cas d'erreur, utiliser le mode clair par défaut
      _isDarkMode.value = false;
      await _storage.write(_storageKey, false);
    }
  }

  // Basculer entre les thèmes et sauvegarder la préférence
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveThemePreference();
  }

  // Sauvegarder la préférence dans le stockage local
  Future<void> _saveThemePreference() async {
    await _storage.write(_storageKey, _isDarkMode.value);
  }

  // Méthode pour initialiser explicitement (optionnelle)
  Future<void> initialize() async {
    await _loadThemePreference();
  }
}