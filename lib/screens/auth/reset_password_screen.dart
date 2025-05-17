// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';
import 'package:gestion_equipe_flutter/screens/auth/login_screen.dart';

class ResetPasswordScreen extends StatelessWidget {
  final AuthService authService = Get.find();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  final String token;

  ResetPasswordScreen({Key? key, required this.token}) : super(key: key);

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    
    try {
      await authService.resetPassword(
        token,
        passwordController.text,
      );
      
      Get.snackbar(
        'Succès',
        'Votre mot de passe a été réinitialisé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Créer un nouveau mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre nouveau mot de passe doit être différent des précédents',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Obx(() => TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => isPasswordVisible.toggle(),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: validatePassword,
              )),
              const SizedBox(height: 20),
              Obx(() => TextFormField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => isConfirmPasswordVisible.toggle(),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: validateConfirmPassword,
              )),
              const SizedBox(height: 30),
              Obx(() => ElevatedButton(
                onPressed: isLoading.value ? null : resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFD32F2F),
                ),
                child: isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Réinitialiser le mot de passe',
                        style: TextStyle(color: Colors.white),
                      ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}