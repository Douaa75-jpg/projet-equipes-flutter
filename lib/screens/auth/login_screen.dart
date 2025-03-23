import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../dashboard/rh_dashboard_screen.dart';
import '../dashboard/employee_dashboard_screen.dart';
import '../dashboard/chef_equipe_dashboard_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../../theme.dart'; // Import du thème
import '../../AuthProvider.dart'; // Import d'AuthProvider

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

  void login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
  });

  try {
    var data = await authService.login(
        emailController.text, passwordController.text);

    String role = data['role']?.trim().toUpperCase() ?? '';
    String subRole = data['typeResponsable']?.trim().toUpperCase() ?? '';

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Connexion réussie!')));

    // Enregistrer les données d'authentification dans AuthProvider
    Provider.of<AuthProvider>(context, listen: false)
        .setAuthData(data['access_token'], data['employeeId'], role);

    // Si le rôle est EMPLOYE, rediriger vers le dashboard de l'employé
    if (role == 'EMPLOYE') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const EmployeeDashboardScreen()));
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
                    builder: (context) => ChefEquipeDashboardScreen()));
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 209, 16, 16),
              const Color.fromARGB(255, 231, 209, 209)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  minHeight: 400,
                  maxHeight: 600,
                ),
                child: Card(
                  color: AppColors.lightSurface.withOpacity(0.9),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/zeta.png',
                            height: 120,
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email,
                                  color: Colors.black),
                              labelStyle: TextStyle(color: AppColors.textLight),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock,
                                  color: Colors.black),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              labelStyle: TextStyle(color: AppColors.textLight),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Fonctionnalité "Mot de passe oublié" à implémenter')),
                                );
                              },
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(300, 50),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Se connecter',
                                    style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
