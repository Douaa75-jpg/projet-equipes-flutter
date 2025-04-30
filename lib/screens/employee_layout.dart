import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../AuthProvider.dart';
import '../screens/leave/HistoriqueDemandesPage.dart';
import '../screens/leave/demande_screen.dart';
import '../screens/tache_screen.dart';
import '../screens/accueil_employe.dart';
import '../screens/dashboard/employee_dashboard_screen.dart';
import '../services/notification_service.dart';

class EmployeeLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final int pendingTasks;
  final NotificationService notificationService;

  const EmployeeLayout({
    super.key,
    required this.child,
    required this.notificationService,
    this.title = 'Accueil',
    this.pendingTasks = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nom = authProvider.nom ?? '';
    final prenom = authProvider.prenom ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 125,
              width: 125,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bienvenue, ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '$prenom $nom',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.person_outline, color: Colors.blue, size: 24),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        toolbarHeight: 90,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color(0xFF8B0000),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildNavItem(context, 'Accueil', '/accueil'),
                _buildNavItem(context, 'Tableau de bord', '/dashboard'),
                _buildNavItemWithAction(
                  context,
                  'Gestion des Demandes',
                  () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                          DemandeScreen(employeId: authProvider.userId!),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _buildNavItemWithAction(
                  context,
                  'Mes Tâches',
                  () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                          TacheScreen(employeId: authProvider.userId!),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _buildNavItemWithAction(
                  context,
                  'Archive',
                  () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                          HistoriqueDemandesPage(employeId: authProvider.userId!),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {},
                ),
                _buildMoreMenu(context),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(Icons.task, '$pendingTasks Tâches en attente'),
                _buildStatusItem(Icons.update, 'Dernière MAJ: ${DateFormat('HH:mm').format(DateTime.now())}'),
                _buildStatusItem(Icons.cloud, 'Services: Online', isOnline: true),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'parametres':
            // Navigation vers paramètres
            break;
          case 'aides':
            // Navigation vers aides
            break;
          case 'deconnexion':
            _showLogoutDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'parametres',
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.black54),
              SizedBox(width: 8),
              Text('Paramètres'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'aide',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.black54),
              SizedBox(width: 8),
              Text('Aide'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'deconnexion',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    return InkWell(
      onTap: () {
        if (route == '/accueil') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccueilEmploye()),
          );
        } else if (route == '/dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeDashboardScreen()),
          );
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithAction(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text, {bool isOnline = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isOnline ? Colors.green : Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}