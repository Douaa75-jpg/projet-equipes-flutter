import 'package:flutter/material.dart';
import 'dart:ui';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(context),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.black.withAlpha((0.4 * 255).toInt())),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titre avec une ombre portée pour améliorer la lisibilité
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Bienvenue ",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: "ZetaBox",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildLoginButton(context),
                  const SizedBox(height: 20),
                  _buildRegisterButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image de fond avec dégradé
  Widget _buildBackgroundImage(BuildContext context) {
    return MediaQuery.of(context).size.width > 600
        ? Stack(
            children: [
              Image.asset(
                'assets/imgg.jpg', // Assurez-vous que l'image est bien optimisée pour le web
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          )
        : Image.asset(
            'assets/imgg.jpg', // Option mobile
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          );
  }

  // Bouton "Se connecter" avec animation d'ombre
  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: 400,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ),
          );
        },
        style: _redButtonStyle(context),
        child: const Text("Se connecter", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  // Bouton "Créer un compte" avec animation d'ombre
  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: 400,
      child: ElevatedButton(
        onPressed: () {
          _showRoleSelectionDialog(context);
        },
        style: _whiteButtonWithRedBorderStyle(context),
        child: const Text(
          "Créer un compte",
          style: TextStyle(fontSize: 18, color: Color(0xFFD32F2F)),
        ),
      ),
    );
  }

  // Sélection du rôle (Employé / Responsable) avec un fond moderne
  void _showRoleSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue, size: 30),
              title: const Text('Employé', style: TextStyle(fontSize: 20)),
              onTap: () => _navigateToRegister(context, 'employe'),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account, color: Colors.green, size: 30),
              title: const Text('Responsable', style: TextStyle(fontSize: 20)),
              onTap: () => _navigateToRegister(context, 'responsable'),
            ),
          ],
        );
      },
    );
  }

  // Navigation vers l'écran d'inscription
  void _navigateToRegister(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(role: role.toLowerCase()),
      ),
    );
  }

  // Style du bouton "Se connecter"
  ButtonStyle _redButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(400, 50),
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFFD32F2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
    );
  }

  // Style du bouton "Créer un compte"
  ButtonStyle _whiteButtonWithRedBorderStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(400, 50),
      side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      foregroundColor: Color(0xFFD32F2F),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
    );
  }
}
