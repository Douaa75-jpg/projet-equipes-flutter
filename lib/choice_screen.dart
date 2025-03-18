import 'package:flutter/material.dart';
import 'dart:ui';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import './screens/dashboard/employee_dashboard_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ صورة الخلفية
          Image.asset(
            'assets/imgg.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // ✅ خلفية مفلترة مع شفافية أنعم
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.black.withAlpha((0.3 * 255).toInt())),
          ),
          // ✅ محتوى الصفحة
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Bienvenue",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✅ زر "Se connecter"
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  EmployeeDashboardScreen(),
                        ),
                      );
                    },
                    style: _buttonStyle(context),
                    child: const Text("Se connecter", style: TextStyle(fontSize: 18)),
                  ),

                  const SizedBox(height: 20),

                  // ✅ زر "Créer un compte"
                  ElevatedButton(
                    onPressed: () {
                      _showRoleSelectionDialog(context);
                    },
                    style: _whiteButtonStyle(context),
                    child: const Text(
                      "Créer un compte",
                      style: TextStyle(fontSize: 18, color: Colors.black),
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

  // ✅ طريقة حديثة لعرض اختيار الدور
  void _showRoleSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Employé'),
              onTap: () => _navigateToRegister(context, 'employe'),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account, color: Colors.green),
              title: const Text('Responsable'),
              onTap: () => _navigateToRegister(context, 'responsable'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Navigation vers l'écran d'inscription avec le rôle sélectionné
  void _navigateToRegister(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(role: role.toLowerCase()),
      ),
    );
  }

  // ✅ Style des boutons (version moderne)
  ButtonStyle _buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      foregroundColor: Colors.white,
      backgroundColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _whiteButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
