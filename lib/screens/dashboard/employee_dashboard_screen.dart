import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Importer pour le graphique
import '../../theme_notifier.dart';  // Créer ce fichier pour la gestion du thème (voir plus bas)

class EmployeeDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> pointageData = {
    'statut': 'Présent',
    'heureArrivee': '08:15',
    'heureDepart': '17:30',
    'heuresTravail': 8.5,
    'heuresSup': 0.5,
    'absences': 2,
    'retards': 3,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Employee Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Ouvrir la fenêtre de recherche
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Afficher les notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context), // Menu avec les options
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatutCard(),
              SizedBox(height: 20),
              _buildGraphiques(),
              SizedBox(height: 20),
              _buildDetails(),
              SizedBox(height: 20),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status', // Utiliser la localisation
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  pointageData['statut'],
                  style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                ),
              ],
            ),
            Icon(
              pointageData['statut'] == 'Présent'
                  ? Icons.check_circle
                  : Icons.warning,
              color: pointageData['statut'] == 'Présent'
                  ? Colors.green
                  : Colors.red,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphiques() {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: SideTitles(showTitles: false),  // Utilisation de SideTitles au lieu de AxisTitles
              leftTitles: SideTitles(showTitles: false),    // Utilisation de SideTitles au lieu de AxisTitles
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, pointageData['heuresTravail']),
                  FlSpot(1, pointageData['heuresSup']),
                ],
                isCurved: true,
                barWidth: 4,
                colors: [Colors.blue],  // Définir les couleurs
                belowBarData: BarAreaData(show: false),  // Zone sous la ligne, masquée
                dotData: FlDotData(show: false),  // Masquer les points
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Arrival Time', pointageData['heureArrivee']),
        _buildDetailRow('Leave Time', pointageData['heureDepart']),
        _buildDetailRow('Hours Worked', '${pointageData['heuresTravail']} h'),
        _buildDetailRow('Overtime', '${pointageData['heuresSup']} h'),
        _buildDetailRow('Absences', '${pointageData['absences']} days'),
        _buildDetailRow('Delays', '${pointageData['retards']} times'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Clock In'),
          onPressed: () {
            // Implémentation de pointage arrivée
          },
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text('Clock Out'),
          onPressed: () {
            // Implémentation de pointage départ
          },
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.lunch_dining),
          label: Text('Lunch Break'),
          onPressed: () {
            // Implémentation de pause déjeuner
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  _changeLanguage(context, Locale('en', 'US'));
                },
              ),
              ListTile(
                title: Text('العربية'),
                onTap: () {
                  _changeLanguage(context, Locale('ar', 'AE'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeLanguage(BuildContext context, Locale locale) {
    Navigator.of(context).pop();
    MyApp.setLocale(context, locale);
  }

  // Méthode pour le Drawer (Menu)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "John Doe", // Nom de l'utilisateur, à remplacer par les données dynamiques
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  "johndoe@example.com", // Email de l'utilisateur
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text("Demande"),
            onTap: () {
              // Naviguer vers la page des demandes
            },
          ),
          ListTile(
            title: Text("Pointage"),
            onTap: () {
              // Naviguer vers la page de pointage
            },
          ),
          ListTile(
            title: Text("Paramètres"),
            onTap: () {
              // Naviguer vers les paramètres
            },
          ),
          ListTile(
            title: Text("Changer le thème"),
            onTap: () {
              // Changer le thème de l'application
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
          ),
          ListTile(
            title: Text("Suivi des paiements"),
            onTap: () {
              // Naviguer vers la page de suivi des paiements
            },
          ),
          ListTile(
            title: Text("Historique des demandes de congé"),
            onTap: () {
              // Naviguer vers l'historique des demandes de congé
            },
          ),
          ListTile(
            title: Text("Voir mon profil"),
            onTap: () {
              // Naviguer vers le profil
            },
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  static void setLocale(BuildContext context, Locale locale) {
    // Set the locale using a ChangeNotifier or a similar method
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeNotifier>(context).isDarkMode ? darkTheme : appTheme, // Appliquer le thème
      home: EmployeeDashboardScreen(), // Dashboard
      locale: Locale('en', 'US'), // Langue par défaut
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'AE'),
      ],
      localizationsDelegates: [
        // Localisation ici
      ],
    );
  }
}
