import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeconnexionScreen extends StatelessWidget {
  const DeconnexionScreen({Key? key}) : super(key: key);

  // Fonction pour supprimer le JWT et rediriger vers la page de connexion
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Remplace 'jwt_token' si tu as un autre nom

    // Redirection vers la page de connexion
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déconnexion'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }
}