import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../AuthProvider.dart';
import '../../services/pointage_service.dart';
import '../leave/demande_screen.dart';
import '../../services/notification_service.dart';
import '../tache_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final PointageService _pointageService = PointageService();
  final NotificationService _notificationService = NotificationService();

  Map<String, dynamic>? _pointage;
  List<dynamic> _historique = [];
  bool _isLoading = true;
  String _statut = "Chargement...";
  int _totalHeures = 0;
  int _totalHeuresSup = 0;

  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadPointage();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      _notificationService.connect(authProvider.userId!, (message) {
        setState(() {
          _notifications.add(message);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _notificationService.disconnect();
    super.dispose();
  }

  Future<void> _loadPointage() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) throw Exception("Utilisateur non authentifié");

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var pointage = await _pointageService.getPointage(authProvider.userId!, today);
      var historique = await _pointageService.getHistorique(authProvider.userId!) ?? [];
      var result = await _pointageService.calculerHeuresTravail(authProvider.userId!, today, today);

      setState(() {
        _pointage = pointage;
        _statut = pointage['statut'] ?? "ABSENT";
        _historique = historique;
        _totalHeures = result['totalHeures'] ?? 0;
        _totalHeuresSup = result['totalHeuresSup'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement du pointage : $e");
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
      if (authProvider.userId == null) throw Exception("Utilisateur non authentifié");

      DateTime now = DateTime.now().toUtc();  // Convertir à l'heure UTC
      String heureArrivee = now.toIso8601String();
      String today = now.toIso8601String();

      DateTime limitTime = DateTime(now.year, now.month, now.day, 10, 0);
      if (now.isAfter(limitTime)) {
        throw Exception("Le pointage est interdit après 10h00.");
      }

      await _pointageService.enregistrerPointage({
        "employeId": authProvider.userId!,
        "date": today,
        "heureArrivee": heureArrivee,
      });

      _loadPointage();
    } catch (e) {
      String messageErreur = e.toString();
      if (messageErreur.contains("Le pointage est interdit après 10h00.")) {
        messageErreur = "Le pointage est interdit après 10h00.";
      } else if (messageErreur.contains("a déjà pointé")) {
        messageErreur = "a déjà pointé ce jour.";
      } else if (messageErreur.contains("Échec de l’enregistrement du pointage")) {
        messageErreur = "Échec de l’enregistrement du pointage";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageErreur),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pointerDepart() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null) throw Exception("Utilisateur non authentifié");

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String heureDepart = DateTime.now().toUtc().toIso8601String();

      var pointageArrivee = await _pointageService.getPointage(authProvider.userId!, today);
      if (pointageArrivee == null ||  (pointageArrivee['statut'] != "PRÉSENT" && pointageArrivee['statut'] != "RETARD")){
        throw Exception("Vous devez pointer l'arrivée avant de pointer le départ.");
      }

      await _pointageService.enregistrerHeureDepart(authProvider.userId!, today, heureDepart);
      _loadPointage();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Succès", style: TextStyle(color: Colors.green)),
            ],
          ),
          content: Text(
            "Heure de départ enregistrée avec succès.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: Colors.green)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      String messageErreur = e.toString();
      if (messageErreur.contains("départ ne peut pas être avant")) {
        messageErreur = "Vous ne pouvez pas pointer le départ avant 8h du matin.";
      } else if (messageErreur.contains("Pointage non trouvé")) {
        messageErreur = "Vous devez pointer l'arrivée avant de pointer le départ.";
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text("Erreur", style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(
            messageErreur,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text("Fermer", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notifications'),
          content: _notifications.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _notifications
                      .map((notification) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(notification),
                          ))
                      .toList(),
                )
              : Text("Aucune notification reçue"),
           actions: [
            if (_notifications.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _notifications.clear();
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Vider'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(Exception e) {
    String messageErreur = e.toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Erreur", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(messageErreur, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: Text("Fermer", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Succès", style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: Text("OK", style: TextStyle(color: Colors.green)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.userId == null) {
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

     // Icônes et couleurs associées aux statuts
    IconData statutIcon;
    Color statutColor;
    String statutText;

    switch (_statut) {
      case 'PRÉSENT':
        statutIcon = Icons.check_circle;  // Icône pour présent
        statutColor = Colors.green;
        statutText = 'Présent';
        break;
      case 'RETARD':
        statutIcon = Icons.access_time;  // Icône pour retard
        statutColor = Colors.orange;
        statutText = 'Retard';
        break;
      case 'ABSENT':
        statutIcon = Icons.cancel;  // Icône pour absent
        statutColor = Colors.red;
        statutText = 'Absent';
        break;
      default:
        statutIcon = Icons.help;  // Icône par défaut
        statutColor = Colors.grey;
        statutText = 'Statut inconnu';
        break;
    }

        return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${authProvider.nom ?? "Utilisateur"}'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  _showNotificationsDialog(context);
                },
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                       child: Text(
                      '${_notifications.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
       drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color.fromARGB(255, 141, 8, 8)),
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
            ListTile(
              title: Text('Tache'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TacheScreen(employeId: authProvider.userId!),
                  ),
                );
              },
            ),
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
                  Text("Statut: $_statut", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(statutIcon, color: statutColor, size: 30),
                      SizedBox(width: 10),
                      Text(
                        statutText,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statutColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                   Text("Heures de travail totales : $_totalHeures h", style: TextStyle(fontSize: 18)),
                  Text("Heures supplémentaires : $_totalHeuresSup h", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 30),
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
                  Text("Historique des pointages", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 Expanded(
                child: ListView.builder(
                  itemCount: _historique.length,
                  itemBuilder: (context, index) {
                    var pointage = _historique[index];
                    String statut = pointage['statut'] ?? 'Non défini';
                    DateTime? date = pointage['date'] != null
                        ? DateTime.tryParse(pointage['date'])
                        : null;
                    String formattedDate =
                        date != null ? DateFormat('dd MMM yyyy').format(date) : 'Inconnue';

                    IconData statutIcon;
                    Color statutColor;
                    
                    switch (statut) {
                      case 'PRÉSENT':
                        statutIcon = Icons.check_circle;
                        statutColor = Colors.green;
                        break;
                      case 'RETARD':
                        statutIcon = Icons.access_time;
                        statutColor = Colors.orange;
                        break;
                      case 'ABSENT':
                        statutIcon = Icons.cancel;
                        statutColor = Colors.red;
                        break;
                      default:
                        statutIcon = Icons.help;
                        statutColor = Colors.grey;
                        break;
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: Icon(statutIcon, color: statutColor),
                        title: Text(
                          formattedDate,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          "Statut: $statut",
                          style: TextStyle(color: statutColor),
                        ),
                      ),
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
