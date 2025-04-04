import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../AuthProvider.dart';
import '../../services/pointage_service.dart';
import '../leave/demande_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final PointageService _pointageService = PointageService();
  Map<String, dynamic>? _pointage;
  List<dynamic> _historique = [];
  bool _isLoading = true;
  String _statut = "Chargement...";
  int _totalHeures = 0;
  int _totalHeuresSup = 0;

  @override
  void initState() {
    super.initState();
    _loadPointage();
  }

  Future<void> _loadPointage() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) {
        throw Exception("Utilisateur non authentifié");
      }

      String today =
          DateFormat('yyyy-MM-dd').format(DateTime.now()); // Format ISO
      print('Date envoyée pour le pointage: $today');

      var pointage =
          await _pointageService.getPointage(authProvider.userId!, today);
      var historique =
          await _pointageService.getHistorique(authProvider.userId!) ?? [];
      var result = await _pointageService.calculerHeuresTravail(
          authProvider.userId!, today, today);

      setState(() {
        _pointage = pointage;
        _statut = pointage['statut'] ?? "ABSENT";
        _historique = historique;
        _totalHeures = result['totalHeures'] ?? 0;
        _totalHeuresSup =
            result['totalHeuresSup'] ?? 0;
        _isLoading = false;
      });
      print('Statut chargé: $_statut');
    } catch (e) {
      print("Erreur lors du chargement du pointage : $e");
      setState(() {
        _statut = "Erreur de chargement";
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _pointerArrivee() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) {
        throw Exception("Utilisateur non authentifié");
      }

      String heureArrivee = DateTime.now().toUtc().toIso8601String();
      String today = DateTime.now().toUtc().toIso8601String();

      print('Données envoyées pour le pointage :');
      print('Date : $today');
      print('Heure d\'arrivée : $heureArrivee');

      await _pointageService.enregistrerPointage({
        "employeId": authProvider.userId!,
        "date": today,
        "heureArrivee": heureArrivee,
      });

      _loadPointage();
    } catch (e) {
      print("Erreur lors de l'enregistrement du pointage : $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _pointerDepart() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) {
        throw Exception("Utilisateur non authentifié");
      }

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String heureDepart = DateTime.now().toUtc().toIso8601String();

      print('Données envoyées pour le départ :');
      print('Date : $today');
      print('Heure de départ : $heureDepart');

      await _pointageService.enregistrerHeureDepart(authProvider.userId!, today, heureDepart);
      print('Heure de départ enregistrée avec succès');

      _loadPointage();
    } catch (e) {
      print("Erreur lors de l'enregistrement de l'heure de départ : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // Fonction pour récupérer les notifications (simulation)
  Future<List<String>> fetchNotifications() async {
    // Vous pouvez remplacer cela par un appel à l'API pour récupérer les vraies notifications
    return [
      'Votre demande a été approuvée.',
      'Nouvelle demande soumise pour approbation.',
      'Votre demande a été rejetée.'
    ];
  }

  // Affichage des notifications dans une fenêtre modale
  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notifications'),
          content: FutureBuilder<List<String>>(
            future: fetchNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur lors de la récupération des notifications.'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Aucune notification.'));
              }
              // Affichage des notifications
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index]),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la fenêtre
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.userId == null) {
      // Si l'utilisateur n'est pas authentifié, rediriger vers la page de connexion
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text("Se connecter"),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${authProvider.nom ?? "Utilisateur"}'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _showNotificationsDialog(context); // Afficher les notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text('Demande'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemandeScreen(employeId: authProvider.userId!),
                  ),
                );
              },
            ),
            // Ajoutez d'autres options de menu ici si nécessaire
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tableau de bord de employé', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  Text('Nom: ${authProvider.nom ?? "Non disponible"}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  Text("Statut: $_statut", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _statut == "ABSENT" ? _pointerArrivee : null,
                    child: Text("Pointer l'arrivée"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_statut == "PRÉSENT" || _statut == "RETARD") ? _pointerDepart : null,
                    child: Text("Enregistrer Heure de Départ"),
                  ),
                  SizedBox(height: 20),
                  Text("Heures travaillées: $_totalHeures"),
                  Text("Heures supplémentaires: $_totalHeuresSup"),
                  SizedBox(height: 20),
                  Text("Historique des pointages", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _historique.length,
                      itemBuilder: (context, index) {
                        var pointage = _historique[index];
                        return ListTile(
                          title: Text("Date: ${pointage['date'] ?? 'Inconnue'}"),
                          subtitle: Text("Statut: ${pointage['statut'] ?? 'Non défini'}"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
