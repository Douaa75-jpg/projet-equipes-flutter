import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../AuthProvider.dart';
import '../leave/HistoriqueDemandesPage.dart';
import '../leave/demande_screen.dart';
import '../tache_screen.dart';
import '../acceuil/accueil_employe.dart';
import '../dashboard/employee_dashboard_screen.dart';
import '../../services/notification_service.dart';

class EmployeeLayout extends StatefulWidget {
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
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout> {
  String _currentRoute = '/accueil';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nom = authProvider.nom ?? '';
    final prenom = authProvider.prenom ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildMobileDrawer(context, authProvider.userId!) : null,
      appBar: AppBar(
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: isMobile ? 60 : 125,
              width: isMobile ? 60 : 125,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            _buildUserInfo(prenom, nom, isMobile: isMobile),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        toolbarHeight: isMobile ? 70 : 90,
        actions: isMobile
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (!isMobile) _buildDesktopNavBar(context, authProvider.userId!),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem(
                      Icons.task, '${widget.pendingTasks} Tâches en attente'),
                  _buildStatusItem(Icons.update,
                      'Dernière MAJ: ${DateFormat('HH:mm').format(DateTime.now())}'),
                  _buildStatusItem(Icons.cloud, 'Services: Online', isOnline: true),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildDesktopNavBar(BuildContext context, String userId) {
    return Container(
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
            () => _navigateToDemandeScreen(context, userId),
          ),
          _buildNavItemWithAction(
            context,
            'Mes Tâches',
            () => _navigateToTacheScreen(context, userId),
          ),
          _buildNavItemWithAction(
            context,
            'Archive',
            () => _navigateToHistorique(context, userId),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          _buildMoreMenu(context),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, String userId) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Menu Employé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMobileNavItem(context, Icons.home, 'Accueil', '/accueil'),
          _buildMobileNavItem(
              context, Icons.dashboard, 'Tableau de bord', '/dashboard'),
          _buildMobileNavItemWithAction(
            context,
            Icons.request_page,
            'Gestion des Demandes',
            () => _navigateToDemandeScreen(context, userId),
          ),
          _buildMobileNavItemWithAction(
            context,
            Icons.task,
            'Mes Tâches',
            () => _navigateToTacheScreen(context, userId),
          ),
          _buildMobileNavItemWithAction(
            context,
            Icons.archive,
            'Archive',
            () => _navigateToHistorique(context, userId),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Aide'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusItem(
                    Icons.task, '${widget.pendingTasks} Tâches en attente'),
                const SizedBox(height: 8),
                _buildStatusItem(Icons.update,
                    'Dernière MAJ: ${DateFormat('HH:mm').format(DateTime.now())}'),
                const SizedBox(height: 8),
                _buildStatusItem(Icons.cloud, 'Services: Online', isOnline: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String prenom, String nom, {bool isMobile = false}) {
    return Container(
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
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline, color: Colors.blue, size: 24),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _navigateToRoute(context, route);
      },
    );
  }

  Widget _buildMobileNavItemWithAction(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    final isActive = _currentRoute == route;
    
    return InkWell(
      onTap: () => _navigateToRoute(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                height: 2,
                width: title.length * 8.0,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithAction(
      BuildContext context, String title, VoidCallback onTap) {
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

  void _navigateToRoute(BuildContext context, String route) {
    setState(() {
      _currentRoute = route;
    });

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
    }
  }

  void _navigateToDemandeScreen(BuildContext context, String userId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DemandeScreen(employeId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToTacheScreen(BuildContext context, String userId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TacheScreen(employeId: userId),
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
  }

  void _navigateToHistorique(BuildContext context, String userId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HistoriqueDemandesPage(employeId: userId),
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
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'parametres':
            break;
          case 'aide':
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
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
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
}