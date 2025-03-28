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
                builder: (context) =>  EmployeeDashboard()));
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
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
