import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../AuthProvider.dart';
import '../../services/pointage_service.dart';

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

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var pointage = await _pointageService.getPointage(authProvider.userId!, today);
      var historique = await _pointageService.getHistorique(authProvider.userId!);
      var result = await _pointageService.calculerHeuresTravail(authProvider.userId!, today, today);

      setState(() {
        _pointage = pointage;
        _statut = pointage['statut'] ?? "ABSENT"; // Si "statut" est absent, par défaut "ABSENT"
        _historique = historique;
        _totalHeures = result['totalHeures'] ?? 0; // Si 'totalHeures' est absent, mettre à 0
        _totalHeuresSup = result['totalHeuresSup'] ?? 0; // Pareil pour 'totalHeuresSup'
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statut = "Erreur de chargement";
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _pointerArrivee() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) {
        throw Exception("Utilisateur non authentifié");
      }
      
      String heureArrivee = DateFormat('HH:mm:ss').format(DateTime.now());
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _pointageService.enregistrerPointage({
        "employeId": authProvider.userId!,
        "date": today,
        "heureArrivee": heureArrivee,
      });
      
      _loadPointage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${authProvider.nom ?? "Utilisateur"}'),
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
