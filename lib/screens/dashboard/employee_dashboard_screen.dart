import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../AuthProvider.dart';
import 'package:intl/intl.dart';
import '../../services/pointage_service.dart';
import '../leave/demande_screen.dart';
import '../tache_screen.dart';
import '../leave/HistoriqueDemandesPage.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  late String statut;
  List<Map<String, dynamic>> historique = [];
  int heuresTravail = 0;
  int heuresSupp = 0;
  int nombreAbsences = 0;

  @override
  void initState() {
    super.initState();
    statut = 'ABSENT';
    _verifierStatutActuel();
    _fetchHistorique();
  }

  void _fetchHistorique() async {
    debugPrint('Début de fetchHistorique');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pointageService = PointageService();
    try {
      final historiqueData = await pointageService.getHistorique(auth.userId!);
       debugPrint('Données historiques reçues: ${historiqueData.length} entrées');
      setState(() {
        historique = List<Map<String, dynamic>>.from(historiqueData);
        debugPrint('Historique mis à jour: ${historique.length} entrées');
      });

      // ✅ Appelle le calcul juste après avoir mis à jour historique
      _calculerHeures();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique : $e');
    }
  }

  void _verifierStatutActuel() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final pointageService = PointageService();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final pointage = await pointageService.getPointage(auth.userId!, today);

      debugPrint('Réponse du pointage: $pointage');

      // Si aucun pointage trouvé pour aujourd'hui ou pointage vide
      if (pointage == null || pointage.isEmpty) {
      setState(() => statut = 'ABSENT');
      return;
    }

      // Vérifier si l'employé a pointé aujourd'hui
      final hasPointedToday = pointage['heureArrivee'] != null &&
          DateTime.parse(pointage['heureArrivee']).day == DateTime.now().day;

      if (!hasPointedToday) {
      setState(() => statut = 'ABSENT');
      return;
    }

      // Priorité au statut du pointage actuel plutôt qu'à l'historique
    final statutServeur = pointage['statut'].toString().toUpperCase();
    
       if (statutServeur == 'PRESENT' || statutServeur == 'RETARD') {
      setState(() => statut = statutServeur);
    } else {
      // Déterminer le statut basé sur l'heure d'arrivée si le statut est invalide
      final heureArrivee = DateTime.parse(pointage['heureArrivee']);
      
    }
  } catch (e) {
    debugPrint('Erreur lors de la vérification du statut: $e');
    setState(() => statut = 'ABSENT');
  }
}

  // Calcul des heures de travail, heures supplémentaires et absences
  void _calculerHeures() {
    int totalHeures = 0;
    int totalHeuresSupp = 0;
    int totalAbsences = 0;

    for (var entry in historique.where((e) => e['deletedAt'] == null)) {
      final date = DateTime.parse(entry['date']);
      final isToday = date.day == DateTime.now().day && 
                   date.month == DateTime.now().month && 
                   date.year == DateTime.now().year;

    // Ne pas compter aujourd'hui comme absence si l'employé n'a pas encore pointé
    if (isToday && this.statut == 'ABSENT') continue;

      // Caster les valeurs à int si elles sont de type num
      final heures = (entry['heures'] ?? 0) as int;
      final heuresSupp = (entry['heures_supp'] ?? 0) as int;
      final statut = entry['statut'];

      totalHeures += heures;
      totalHeuresSupp += heuresSupp;

      if (statut == 'ABSENT') {
        totalAbsences++;
      }
    }

    debugPrint('Absences calculées depuis l\'historique: $totalAbsences'); // Vérifie si ce nombre est correct

    setState(() {
      heuresTravail = totalHeures;
      heuresSupp = totalHeuresSupp;
      nombreAbsences = totalAbsences;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    
    final nomComplet =
        '${auth.nom ?? ''} ${auth.prenom ?? ''}'.trim() ?? 'Employé';
    final email = auth.email ?? 'Non disponible';
    final matricule = auth.matricule ?? 'Non disponible';
    final dateNaissance = auth.datedenaissance != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(auth.datedenaissance!))
        : 'Non disponible';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        title: Text('Bienvenue $nomComplet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔷 Statut Card
            _buildStatusCard(statut),
            SizedBox(height: 20),

            // 🔷 4 Info Cards
            _buildInfoCardsRow(),
            SizedBox(height: 20),

            // 🔷 Infos & Boutons de pointage
            _buildProfileAndActionsSection(
                context, auth, nomComplet, email, dateNaissance, matricule),
            SizedBox(height: 20),

            // 🔷 Historique
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
                BoxDecoration(color: const Color.fromARGB(255, 141, 8, 8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.red),
                ),
                SizedBox(height: 10),
                Text('Menu Principal',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.red),
            title: Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.note_add, color: Colors.red),
            title: Text('Demandes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DemandeScreen(employeId: authProvider.userId!),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment, color: Colors.red),
            title: Text('Tâches'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TacheScreen(employeId: authProvider.userId!),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment, color: Colors.red),
            title: Text('Historique des demandes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoriqueDemandesPage(employeId: authProvider.userId!),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey),
            title: Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: Colors.grey),
            title: Text('Aide'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'PRESENT':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'RETARD':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 30),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut actuel',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                SizedBox(height: 4),
                Text(status,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadAbsences(String employeId) async {
    try {
      final pointageService = PointageService();
      final absences = await pointageService.getNombreAbsences(employeId);
      debugPrint('Absences récupérées: $absences');
      setState(() {
        nombreAbsences = absences;
      });
    } catch (e) {
      debugPrint('Erreur lors de la récupération des absences: $e');
    }
  }

  Widget _buildInfoCardsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoCard('Heures totales', '$heuresTravail h', Icons.access_time,
            Colors.blue),
        _buildInfoCard(
            'Heures supp.', '$heuresSupp h', Icons.timer, Colors.orange),
        _buildInfoCard(
            'Absences', '$nombreAbsences', Icons.calendar_today, Colors.red),
        _buildInfoCard('Solde congé', '6j', Icons.beach_access, Colors.teal),
      ],
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.2).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAndActionsSection(BuildContext context, AuthProvider auth,
      String nomComplet, String email, String dateNaissance, String matricule) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Card
        Expanded(
          flex: 2,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: AssetImage('assets/Normal .jpg'),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nomComplet,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            _buildProfileInfoRow(Icons.email, email),
                            _buildProfileInfoRow(Icons.cake, dateNaissance),
                            _buildProfileInfoRow(Icons.badge, matricule),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),

        // Actions Card
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActionButton(
                      context: context,
                      icon: Icons.login,
                      label: "Pointer l'arrivée",
                      color: Colors.green,
                      onPressed: () async {
                        try {
                          final pointageService = PointageService();
                          final now = DateTime.now();
                          final today = DateFormat('yyyy-MM-dd').format(now);

                          final existingPointage = await pointageService.getPointage(auth.userId!, today);
                          

                          if (existingPointage != null &&
                              existingPointage['heureArrivee'] != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Vous avez déjà pointé aujourd\'hui')),
                            );
                            return;
                          }
                          

                          final heureArrivee = now.toIso8601String();

                          String newStatut = 'PRESENT';
                          

                          final data = {
                            'employeId': auth.userId,
                            'date': now.toIso8601String(),
                            'heureArrivee': heureArrivee,
                            'statut': newStatut,
                          };

                          await pointageService.enregistrerPointage(data);

                          setState(() {
                            statut = newStatut;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Pointage enregistré: $newStatut')),
                          );
                        } catch (e) {
                          print('Erreur : $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors du pointage')),
                          );
                        }
                      }),
                  SizedBox(height: 12),
                  _buildActionButton(
                      context: context,
                      icon: Icons.logout,
                      label: "Départ",
                      color: Colors.red,
                      onPressed: () async {
                        try {
                          final pointageService = PointageService();
                          final now = DateTime.now();
                          final today = DateFormat('yyyy-MM-dd').format(now);

                          // Vérifier si l'employé a déjà pointé aujourd'hui
                          final existingPointage = await pointageService .getPointage(auth.userId!, today);
                          print("Existing Pointage: $existingPointage");

                          if (existingPointage['heureArrivee'] == null) {
                            print("Heure d'arrivée est nulle.");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar( content: Text('Veuillez d\'abord enregistrer votre arrivée.')),
                            );
                            return;
                          }

                         
                          // Vérifier que l'employé est présent ou en retard
                         if (existingPointage['statut'] != 'PRESENT' && existingPointage['statut'] != 'RETARD') {
                            print("L'employé n'est ni présent ni en retard.");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('L\'employé doit être présent ou en retard pour enregistrer l\'heure de départ.')),
                            );
                            return;
                          }

                          // Vérifier si l'heure de départ est déjà enregistrée
                          if (existingPointage['heureDepart'] != null) {
                            print("Départ déjà enregistré.");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar( content: Text('Vous avez déjà enregistré votre départ.')),
                            );
                            return;
                          }
                          // Enregistrer l'heure de départ
                          await pointageService.enregistrerHeureDepart(
                            auth.userId!,
                            today,
                            now.toIso8601String(),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Départ enregistré avec succès')),
                          );
                           // Rafraîchir à la fois le statut et l'historique
                          _verifierStatutActuel();
                          _fetchHistorique();
                        } catch (e) {
                          print(
                              'Erreur lors de l\'enregistrement du départ : $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Erreur lors de l\'enregistrement du départ')),
                          );
                        }
                      }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text('Historique de pointage',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(height: 20, thickness: 1),
            if (historique.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Aucun historique disponible',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...historique.map((pointage) {
                final date = DateFormat('dd/MM/yyyy')
                    .format(DateTime.parse(pointage['date']));
                final heureArrivee = pointage['heureArrivee'] != null
                    ? DateFormat('HH:mm')
                        .format(DateTime.parse(pointage['heureArrivee']))
                    : '-';
                final heureDepart = pointage['heureDepart'] != null
                    ? DateFormat('HH:mm')
                        .format(DateTime.parse(pointage['heureDepart']))
                    : '-';
                final statut = pointage['statut'] ?? 'ABSENT';
                return _buildHistoryItem(
                    date, heureArrivee, heureDepart, statut);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
      String date, String heureArrivee, String heureDepart, String statut) {
    Color statusColor;
    switch (statut) {
      case 'PRESENT':
        statusColor = Colors.green;
        break;
      case 'RETARD':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((255 * 0.1).toInt()),

        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withAlpha((255 * 0.3).toInt())),

      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arrivée: $heureArrivee', style: TextStyle(fontSize: 14)),
              Text('Départ: $heureDepart', style: TextStyle(fontSize: 14)),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((255 * 0.2).toInt()),

              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statut,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
