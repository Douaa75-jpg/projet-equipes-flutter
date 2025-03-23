import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../AuthProvider.dart';
import '../leave/demande_congé.dart';
import '../leave/demande_sortie.dart';
import '../leave/HistoriqueDemandesPage.dart';
import '../pointage/HistoriquePointagesScreen.dart';
import '../pointage/PointagePage.dart';
import '../../DeconnexionScreen.dart';
import '../../ParametresScreen.dart';
import '../../theme.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  _EmployeeDashboardScreenState createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late String employeId;
  Map<String, dynamic> pointageData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    employeId = authProvider.employeeId ?? ''; // Récupération de l'ID de l'utilisateur connecté
    
    try {
      var data = await ApiService().getPointage(employeId);
      setState(() {
        pointageData = data;
        isLoading = false;
      });
    } catch (error) {
      print("Erreur lors du chargement des données : $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tableau de bord"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bonjour, ${pointageData['nom'] ?? 'Employé'} !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _buildStatutCard(),
                  SizedBox(height: 20),
                  _buildStatsGrid(MediaQuery.of(context).size.width),
                  SizedBox(height: 20),
                  _buildGraphique(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.check),
        tooltip: "Pointer l'arrivée",
      ),
    );
  }

  Widget _buildStatutCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatInfo("Statut", pointageData['statut'] ?? "Inconnu"),
            _buildStatInfo("Arrivée", pointageData['heureArrivee'] ?? "--:--"),
            _buildStatInfo("Départ", pointageData['heureDepart'] ?? "--:--"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(double screenWidth) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: screenWidth > 600 ? 3 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard("Heures de travail", "${pointageData['heuresTravail'] ?? 0} h", Icons.access_time),
        _buildStatCard("Heures sup.", "${pointageData['heuresSup'] ?? 0} h", Icons.timer),
        _buildStatCard("Absences", "${pointageData['absences'] ?? 0}", Icons.event_busy),
        _buildStatCard("Retards", "${pointageData['retards'] ?? 0}", Icons.schedule),
      ],
    );
  }

  Widget _buildGraphique() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 2)],
                  isCurved: true,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
