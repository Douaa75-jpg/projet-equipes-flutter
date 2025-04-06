import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../AuthProvider.dart'; // adapte le chemin si nécessaire

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> demandes = [];

  Future<void> loadDemands() async {
    final response = await http.get(Uri.parse('http://localhost:3000/demande'));

    if (response.statusCode == 200) {
      final allDemandes = json.decode(response.body)['demandes'];
      setState(() {
        // On garde uniquement les demandes avec le statut "SOUMISE"
        demandes = allDemandes.where((d) => d['statut'] == 'SOUMISE').toList();
      });
    } else {
      print('Erreur de chargement des demandes');
    }
  }

  @override
  void initState() {
    super.initState();
    loadDemands();
  }

  void showDemandeDetails(dynamic demande) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController raisonController = TextEditingController();

        return AlertDialog(
          title: Text('Détails de la demande'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👤 Employé : ${demande['employe']['utilisateur']['nom']}'),
                Text('📌 Type : ${demande['type']}'),
                Text('📄 Statut : ${demande['statut']}'),
                Text('📝 Raison : ${demande['raison'] ?? "Aucune"}'),
                Text('📅 Date Début : ${demande['dateDebut']}'),
                if (demande['dateFin'] != null)
                  Text('📅 Date Fin : ${demande['dateFin']}'),
                SizedBox(height: 10),
                TextField(
                  controller: raisonController,
                  decoration: InputDecoration(
                    labelText: 'Raison de rejet',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Rejeter'),
              onPressed: () {
                rejectRequest(demande['id'], raisonController.text);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Approuver'),
              onPressed: () {
                approveRequest(demande['id']);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> approveRequest(String demandeId) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final response = await http.patch(
      Uri.parse('http://localhost:3000/demande/$demandeId/approve'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      await loadDemands(); // recharge les demandes pour mettre à jour la liste
    } else {
      print('Erreur de validation');
    }
  }

  Future<void> rejectRequest(String demandeId, String raison) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final response = await http.patch(
      Uri.parse('http://localhost:3000/demande/$demandeId/reject'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'raison': raison}),
    );

    if (response.statusCode == 200) {
      await loadDemands(); // recharge les demandes pour mettre à jour la liste
    } else {
      print('Erreur de rejet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📢 Notifications RH')),
      body: demandes.isEmpty
          ? Center(child: Text("Aucune demande soumise."))
          : ListView.builder(
              itemCount: demandes.length,
              itemBuilder: (context, index) {
                final demande = demandes[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text('👤 ${demande['employe']['utilisateur']['nom']}'),
                    subtitle: Text('📄 Statut: ${demande['statut']}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => showDemandeDetails(demande),
                  ),
                );
              },
            ),
    );
  }
}
