// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';
import 'package:gestion_equipe_flutter/screens/auth/login_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final AuthService authService = Get.find();
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  Future<void> sendResetLink() async {
  if (!formKey.currentState!.validate()) return;
  
  isLoading.value = true;
  
  try {
    final response = await authService.forgotPassword(emailController.text);
    
    Get.snackbar(
      'Succès',
      response['message'] ?? 'Lien de réinitialisation envoyé avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    await Future.delayed(const Duration(seconds: 2));
    Get.offAll(() => LoginScreen());
  } catch (e) {
    Get.snackbar(
      'Erreur',
      e.toString().replaceAll('Exception: ', ''),
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
        title: const Text('Mot de passe oublié'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
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
                'Réinitialisation du mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Entrez votre adresse email pour recevoir un lien de réinitialisation',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                onPressed: isLoading.value ? null : sendResetLink,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFD32F2F),
                ),
                child: isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Envoyer le lien de réinitialisation',
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