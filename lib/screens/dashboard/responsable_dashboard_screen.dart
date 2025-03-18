import 'package:flutter/material.dart';

class ResponsableDashboardScreen extends StatelessWidget {
  const ResponsableDashboardScreen({Key? key}) : super(key: key); // Ajout du paramètre key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tableau de bord Responsable")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/team-employees');
            },
            child: Text("Voir les employés de mon équipe"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/leave-approval');
            },
            child: Text("Valider les demandes de congé"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/exit-approval');
            },
            child: Text("Valider les demandes d'autorisation de sortie"),
          ),
        ],
      ),
    );
  }
}
