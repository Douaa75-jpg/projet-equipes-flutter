import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';
import 'package:gestion_equipe_flutter/screens/acceuil/accueil_chef_.dart';
import 'package:gestion_equipe_flutter/screens/dashboard/admin_dashboard_screen.dart';
import 'package:gestion_equipe_flutter/AuthProvider.dart';
import 'package:gestion_equipe_flutter/screens/auth/reset_password_screen.dart';
import 'package:gestion_equipe_flutter/screens/auth/forgot_password_screen.dart';
import 'package:gestion_equipe_flutter/screens/acceuil/accueil_employe.dart';
import '../auth/registre_screen.dart';
import '../acceuil/Accueil_RH.dart';

enum TypeResponsable { chefEquipe, rh }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  // Fonction de validation de l'email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  // Fonction de validation du mot de passe
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Utilisation du AuthProvider pour se connecter
      var data = await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passwordController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Connexion réussie!')));

      // Récupérer le rôle et le sous-rôle du JWT ou des données renvoyées
      String role = data['role'] ?? '';
      String subRole = data['typeResponsable'] ?? '';

      // Redirection en fonction du rôle
      if (role == 'EMPLOYE') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AccueilEmploye()),
        );
      } else if (role == 'RESPONSABLE') {
        _handleResponsableNavigation(subRole);
      } else if (role == 'ADMINISTRATEUR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle non défini: $role')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleResponsableNavigation(String subRole) {
    if (subRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sous-rôle de responsable non défini')),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Accueilchef()),
          );
          break;
        case TypeResponsable.rh:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  AccueilRh()),
          );
          break;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sous-rôle de responsable non défini: $subRole')),
      );
    }
  }

  void _handleLoginError(dynamic e) {
    String errorMessage = e.toString();
    
    if (errorMessage.contains("invalid email") || 
        errorMessage.contains("invalid password")) {
      errorMessage = "Email ou mot de passe incorrect.";
    } else if (errorMessage.contains("Unauthorized")) {
      errorMessage = "Échec de l'authentification. Veuillez vérifier vos informations.";
    } else if (errorMessage.contains("timeout") || errorMessage.contains("socket")) {
      errorMessage = "Problème de connexion. Vérifiez votre accès internet.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $errorMessage')),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
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

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Logo
          Image.asset(
            'assets/logo.png',
            height: 100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connectez-vous à votre compte',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Champ Email
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            validator: _validateEmail,
          ),
          const SizedBox(height: 20),

          // Champ Mot de passe
          _buildTextField(
            label: 'Mot de passe',
            controller: _passwordController,
            obscure: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            validator: _validatePassword,
          ),

          const SizedBox(height: 12),
          // Lien Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Bouton de connexion
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Se connecter', 
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 16),
          // Lien vers l'inscription
          TextButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) =>  RegisterPage()),
              );
            },
            child: const Text(
              "Vous n'avez pas de compte ? Créer un compte",
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 239, 241),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
                child: _buildForm(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}