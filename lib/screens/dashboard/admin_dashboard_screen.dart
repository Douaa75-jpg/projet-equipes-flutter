import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Administrateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section : Statistiques de base
            Text(
              'Performance de l\'entreprise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 5,
              child: ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Heures Totales Travaillées'),
                subtitle: Text('1200h'),
              ),
            ),
            Card(
              elevation: 5,
              child: ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Congés Validés'),
                subtitle: Text('45 demandes'),
              ),
            ),
            SizedBox(height: 20),

            // Section : Actions rapides
            Text(
              'Actions rapides',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Action pour ajouter un employé
              },
              child: Text('Ajouter un Employé'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Action pour gérer les superviseurs
              },
              child: Text('Gérer les Superviseurs'),
            ),
          ],
        ),
      ),
    );
  }
}
