import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../dashboard/rh_dashboard_screen.dart';
import '../dashboard/employee_dashboard_screen.dart';
import '../dashboard/chef_equipe_dashboard_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../../AuthProvider.dart'; // Import d'AuthProvider
import 'package:gestion_equipe_flutter/screens/auth/registre_screen.dart';
import '../accueil_employe.dart';
enum TypeResponsable { chefEquipe, rh }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

 late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Fonction de validation de l'email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    // Vérification du format de l'email
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  // Fonction de validation du mot de passe
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Utilisation du AuthProvider pour se connecter
      var data = await Provider.of<AuthProvider>(context, listen: false)
          .login(emailController.text, passwordController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Connexion réussie!')));

      // Récupérer le rôle et le sous-rôle du JWT ou des données renvoyées
      String role = data['role'] ?? '';
      String subRole = data['typeResponsable'] ?? '';

      // Si le rôle est EMPLOYE, rediriger vers le dashboard de l'employé
      if (role == 'EMPLOYE') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>  AccueilEmploye()));
      } else if (role == 'RESPONSABLE') {
        // Vérification du sous-rôle uniquement pour les responsables
        if (subRole.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sous-rôle de responsable non défini')));
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
                  MaterialPageRoute(
                      builder: (context) => ChefEquipeDashboard()));
              break;
            case TypeResponsable.rh:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => RHDashboardScreen()));
              break;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Sous-rôle de responsable non défini: $subRole')));
        }
      } else if (role == 'ADMINISTRATEUR') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => AdminDashboardScreen()));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Rôle non défini: $role')));
      }
    } catch (e) {
      if (!mounted) return;

      // Vérification de l'erreur pour un mot de passe ou un email incorrect
      String errorMessage = e.toString();
      
      // Afficher un message d'erreur plus spécifique pour email ou mot de passe incorrect
      if (errorMessage.contains("invalid email") || errorMessage.contains("invalid password")) {
        errorMessage = "Email ou mot de passe incorrect.";
      } else if (errorMessage.contains("Unauthorized")) {
        errorMessage = "Échec de l'authentification. Veuillez vérifier vos informations.";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $errorMessage')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
          // === LOGO ===
          Image.asset(
            'assets/logo.png',
            height: 100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Bienvenue',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connectez-vous à votre compte',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Email',
            controller: emailController,
            validator: validateEmail,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Mot de passe',
            controller: passwordController,
            obscure: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            validator: validatePassword,
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité non implémentée')),
                );
              },
              child: const Text('Mot de passe oublié ?',
                  style: TextStyle(color: Color(0xFFD32F2F))),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Se connecter', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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