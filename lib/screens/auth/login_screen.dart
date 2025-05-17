import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';
import 'package:gestion_equipe_flutter/screens/acceuil/accueil_chef_.dart';
import 'package:gestion_equipe_flutter/screens/dashboard/admin_dashboard_screen.dart';
import 'package:gestion_equipe_flutter/screens/auth/reset_password_screen.dart';
import 'package:gestion_equipe_flutter/screens/auth/forgot_password_screen.dart';
import 'package:gestion_equipe_flutter/screens/acceuil/accueil_employe.dart';
import '../auth/registre_screen.dart';
import '../acceuil/Accueil_RH.dart';
import '../../auth_controller.dart';
import 'package:flutter/animation.dart';

enum TypeResponsable { chefEquipe, rh }

class LoginController extends GetxController {
  final AuthService authService = Get.put(AuthService());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  final formKey = GlobalKey<FormState>();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    final emailRegExp =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final authService = Get.find<AuthService>();
      var data = await authService.login(
          emailController.text, passwordController.text);

      Get.snackbar(
        'Succès',
        'Connexion réussie!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      final authProvider = Get.find<AuthProvider>();
      await authProvider.checkAuthStatus();

      String role = data['role'] ?? '';
      String subRole = data['typeResponsable'] ?? '';

      if (role == 'EMPLOYE') {
        Get.offAll(() => const AccueilEmploye());
      } else if (role == 'RESPONSABLE') {
        handleResponsableNavigation(subRole);
      } else if (role == 'ADMINISTRATEUR') {
        Get.offAll(() => AdminDashboardScreen());
      } else {
        Get.snackbar(
          'Erreur',
          'Rôle non défini: $role',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      handleLoginError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void handleResponsableNavigation(String subRole) {
    if (subRole.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Sous-rôle de responsable non défini',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    TypeResponsable? responsableType;
    if (subRole == 'CHEF_EQUIPE' || subRole == 'CHEF D\'EQUIPE') {
      responsableType = TypeResponsable.chefEquipe;
    } else if (subRole == 'RH') {
      responsableType = TypeResponsable.rh;
    }

    if (responsableType != null) {
      switch (responsableType) {
        case TypeResponsable.chefEquipe:
          Get.offAll(() => const Accueilchef());
          break;
        case TypeResponsable.rh:
          Get.offAll(() => AccueilRh());
          break;
      }
    } else {
      Get.snackbar(
        'Erreur',
        'Sous-rôle de responsable non défini: $subRole',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void handleLoginError(dynamic e) {
    String errorMessage;

    if (e.toString().contains("Email incorrect")) {
      errorMessage =
          "L'email que vous avez entré est incorrect. Veuillez vérifier et réessayer.";
    } else if (e.toString().contains("Mot de passe incorrect")) {
      errorMessage =
          "Le mot de passe que vous avez entré est incorrect. Veuillez réessayer.";
    } else if (e.toString().contains("invalid email") ||
        e.toString().contains("invalid password")) {
      errorMessage = "Email ou mot de passe incorrect.";
    } else if (e.toString().contains("Unauthorized")) {
      errorMessage =
          "Email ou mot de passe incorrect. Veuillez vérifier vos informations.";
    } else if (e.toString().contains("timeout") ||
        e.toString().contains("socket")) {
      errorMessage = "Problème de connexion. Vérifiez votre accès internet.";
    } else {
      errorMessage =
          "Une erreur s'est produite lors de la connexion. Veuillez réessayer.";
    }

    Get.snackbar(
      'Erreur',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}

class LoginScreen extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());

  LoginScreen({Key? key}) : super(key: key);

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildForm(BuildContext context, bool isSmallScreen) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            height: isSmallScreen ? 100 : 120,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD32F2F),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Connectez-vous à votre compte',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          _buildTextField(
            label: 'Email',
            controller: controller.emailController,
            validator: controller.validateEmail,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Obx(() => _buildTextField(
                label: 'Mot de passe',
                controller: controller.passwordController,
                obscure: !controller.isPasswordVisible.value,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => controller.login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
                validator: controller.validatePassword,
              )),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.to(() => ForgotPasswordScreen()),
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              )),
          SizedBox(height: isSmallScreen ? 12 : 16),
          TextButton(
            onPressed: null,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Vous n'avez pas de compte ? ",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  WidgetSpan(
                    child: InkWell(
                      onTap: () => Get.to(() => RegisterPage()),
                      child: Text(
                        "Créer un compte",
                        style: TextStyle(
                          color: const Color(0xFFD32F2F),
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 239, 241),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? 400 : (isLargeScreen ? 500 : 450),
            ),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 32),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                child: _buildForm(context, isSmallScreen),
              ),
            ),
          ),
        ),
      ),
    );
  }
}