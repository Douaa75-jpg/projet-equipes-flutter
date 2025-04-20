import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../AuthProvider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> demandes = [];
  int? expandedIndex;

  Future<void> loadDemands() async {
    final response = await http.get(Uri.parse('http://localhost:3000/demande'));

    if (response.statusCode == 200) {
      final allDemandes = json.decode(response.body)['demandes'];
      setState(() {
        demandes = allDemandes.where((d) => d['statut'] == 'EN_ATTENTE').toList();
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

  Future<void> approveRequest(String demandeId) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final response = await http.patch(
      Uri.parse('http://localhost:3000/demande/$demandeId/approve'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      await loadDemands();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande approuvée avec succès')),
      );
    } else {
      print('Erreur de validation');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'approbation')),
      );
    }
  }

  Future<void> rejectRequest(String demandeId) async {
    TextEditingController raisonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Raison du rejet'),
          content: TextField(
            controller: raisonController,
            decoration: InputDecoration(
              labelText: 'Entrez la raison du rejet',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Confirmer'),
              onPressed: () async {
                Navigator.pop(context);
                final userId = Provider.of<AuthProvider>(context, listen: false).userId;

                final response = await http.patch(
                  Uri.parse('http://localhost:3000/demande/$demandeId/reject'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'userId': userId, 'raison': raisonController.text}),
                );

                if (response.statusCode == 200) {
                  await loadDemands();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Demande rejetée avec succès')),
                  );
                } else {
                  print('Erreur de rejet');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors du rejet')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
                final isExpanded = expandedIndex == index;
                
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '👤 ${demande['employe']['utilisateur']['nom']} ${demande['employe']['utilisateur']['prenom']}', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text('📄 Type: ${demande['type']}'),
                                    SizedBox(height: 4),
                                    Text('📅 Période: ${demande['dateDebut']}${demande['dateFin'] != null ? ' - ${demande['dateFin']}' : ''}'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => approveRequest(demande['id']),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => rejectRequest(demande['id']),
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            SizedBox(height: 10),
                            Text(
                              '📝 Raison de la demande:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              demande['raison'] ?? "Aucune raison spécifiée",
                              style: TextStyle(
                                fontStyle: demande['raison'] == null 
                                    ? FontStyle.italic 
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}