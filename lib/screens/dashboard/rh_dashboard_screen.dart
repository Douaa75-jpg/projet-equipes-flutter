import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../AuthProvider.dart';
import '../Notification_Screen.dart';
import '../../services/RH_service.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';

class RHDashboardScreen extends StatefulWidget {
  @override
  _RHDashboardScreenState createState() => _RHDashboardScreenState();
}

class _RHDashboardScreenState extends State<RHDashboardScreen> {
  int totalEmployes = 0;
  int totalResponsables = 0;
  List<Employe> _employees = [];
  List<Responsable> _responsables = [];
  final RhService rhService = RhService();
  final NotificationService _notificationService = NotificationService(); // NotificationService instance
  Widget _currentScreen = Center(
    child: Text(
      'Bienvenue dans l\'interface de ressource humain',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  @override
  void initState() {
    super.initState();
    _getCounts();
    _fetchEmployees();
    _fetchResponsables();
    
    // Connect to the notification service with user ID
    _connectToNotificationService();
  }

  // Function to connect to Notification Service
  void _connectToNotificationService() {
    Provider.of<AuthProvider>(context, listen: false).getUserData().then((userData) {
      if (userData != null && userData['id'] != null) {
        String userId = userData['id'].toString();
        _notificationService.connect(userId, _handleNotification);
      }
    });
  }

  // Function to get the total counts of employees and responsables
  _getCounts() async {
    try {
      totalEmployes = await rhService.getEmployesCount();
      totalResponsables = await rhService.getResponsablesCount();
      setState(() {});
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des données');
    }
  }

  // Fetch the employees list from the service
  _fetchEmployees() async {
    try {
      _employees = await rhService.getEmployees();
      setState(() {});
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des employés');
    }
  }

  // Fetch the responsables list from the service
  _fetchResponsables() async {
    try {
      _responsables = await rhService.getResponsables();
      setState(() {});
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des responsables');
    }
  }

  // Handle incoming notifications
  void _handleNotification(String message) {
    // Show a Snackbar for new notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔔 Nouvelle demande: $message"),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Show error message
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Disconnect notification service when disposing
  @override
  void dispose() {
    _notificationService.disconnect();  // Disconnect from notification service when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: _buildUserName(),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Employés', totalEmployes, FontAwesomeIcons.user),
                _buildStatCard('Responsables', totalResponsables, FontAwesomeIcons.userTie),
              ],
            ),
            SizedBox(height: 16),
            Expanded(child: _currentScreen),
          ],
        ),
      ),
    );
  }

  // FutureBuilder to load and display user name
  Widget _buildUserName() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<AuthProvider>(context, listen: false).getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Utilisateur non connecté');
        } else {
          String userName = snapshot.data?['nom'] ?? 'Utilisateur';
          return Text('Bienvenue, $userName');
        }
      },
    );
  }

  // Drawer menu to navigate between screens
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildUserHeader(),
          _buildDrawerItem('Gestion des congés', Icons.date_range, () {
            setState(() => _currentScreen = Center(child: Text('إدارة الكونجي هنا')));
            Navigator.pop(context);
          }),
          _buildDrawerItem('Afficher les données des employés', Icons.people, () {
            setState(() => _currentScreen = _buildEmployeesList());
            Navigator.pop(context);
          }),
          _buildDrawerItem('Afficher les données des chefs d\'équipe', Icons.supervisor_account, () {
            setState(() => _currentScreen = _buildResponsablesList());
            Navigator.pop(context);
          }),
          _buildDrawerItem('Notification', Icons.notifications, () {
            setState(() => _currentScreen = NotificationScreen());
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  // Build user header in the drawer
  Widget _buildUserHeader() {
    return FutureBuilder<Map<String, dynamic>?>( 
      future: Provider.of<AuthProvider>(context, listen: false).getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const UserAccountsDrawerHeader(
            accountName: Text('Chargement...'),
            accountEmail: Text('Chargement...'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const UserAccountsDrawerHeader(
            accountName: Text('Utilisateur non connecté'),
            accountEmail: Text('Aucun email disponible'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.black),
            ),
          );
        } else {
          String userName = snapshot.data?['nom'] ?? 'Nom non disponible';
          String userEmail = snapshot.data?['email'] ?? 'Email non disponible';
          return UserAccountsDrawerHeader(
            accountName: Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
          );
        }
      },
    );
  }

  // Drawer items
  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
      title: Text(title, style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
      onTap: onTap,
    );
  }

  // Stat card displaying employee count or responsable count
  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color.fromARGB(255, 0, 0, 0)),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  // Employees list
  Widget _buildEmployeesList() {
    if (_employees.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employe = _employees[index];
        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(employe.nom.substring(0, 1)), // Initiales de l'employé
            ),
            title: Text('${employe.nom} ${employe.prenom}'),
            subtitle: Text(
              'Email: ${employe.email}\nChef d\'équipe: ${employe.responsable.nom} ${employe.responsable.prenom}',
            ),
          ),
        );
      },
    );
  }

  // Responsables list with expandable items
  Widget _buildResponsablesList() {
    if (_responsables.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _responsables.length,
      itemBuilder: (context, index) {
        final responsable = _responsables[index];
        final responsablesEmployes = _employees
            .where((employe) =>
                employe.responsable.nom == responsable.nom && employe.responsable.prenom == responsable.prenom)
            .toList();
        return ExpansionTile(
          title: Text('${responsable.nom} ${responsable.prenom}', style: TextStyle(fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 0, 0, 0))),
          subtitle: Text('Email: ${responsable.email}', style: TextStyle(color: Colors.grey)),
          children: [
            if (responsablesEmployes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Aucun employé dans cette équipe.', style: TextStyle(color: Colors.red)),
              ),
            ...responsablesEmployes.map((employe) {
              return ListTile(
                title: Text('${employe.nom} ${employe.prenom}'),
                subtitle: Text('Email: ${employe.email}'),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
