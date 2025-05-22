import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../auth_controller.dart';
import '../acceuil/accueil_chef_.dart';
import '../dashboard/chef_equipe_dashboard_screen.dart';
import '../../services/notification_service.dart';

class ChefLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int pendingTasks;
  final NotificationService? notificationService;

  const ChefLayout({
    super.key,
    required this.child,
    this.notificationService,
    this.title = 'Accueil',
    this.pendingTasks = 0,
  });

  @override
  State<ChefLayout> createState() => _ChefLayoutState();
}

class _ChefLayoutState extends State<ChefLayout> {
  String _currentRoute = '/Accueilchef';
  bool _isDrawerOpen = false;
  final AuthProvider authProvider = Get.find<AuthProvider>();

  @override
  Widget build(BuildContext context) {
    final nom = authProvider.nom.value;
    final prenom = authProvider.prenom.value;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      appBar: AppBar(
        title: isMobile
            ? Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  _buildUserInfo(prenom, nom, isMobile: true),
                ],
              )
            : Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 160,
                    width: 160,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  _buildUserInfo(prenom, nom),
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
          if (!isMobile) _buildDesktopNavBar(context),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem(
                      Icons.update, 'Dernière MAJ: ${DateFormat('HH:mm').format(DateTime.now())}'),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildDesktopNavBar(BuildContext context) {
    return Container(
      height: 50,
      color: const Color(0xFF8B0000),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildNavItem(context, 'Accueil', '/Accueilchef'),
          _buildNavItem(context, 'Tableau de bord', '/dashboard'),
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

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 90,
                  width: 90,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Menu Chef d\'équipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMobileNavItem(context, Icons.home, 'Accueil', '/Accueilchef'),
          _buildMobileNavItem(context, Icons.dashboard, 'Tableau de bord', '/dashboard'),
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
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Get.back(); // Ferme le drawer
        _navigateToRoute(context, route);
      },
    );
  }

  Widget _buildUserInfo(String prenom, String nom, {bool isMobile = false}) {
  final displayName = (prenom.isEmpty && nom.isEmpty) 
      ? 'Bienvenue' 
      : '$prenom $nom'.trim();

  return Container(
    padding: EdgeInsets.symmetric(
      vertical: isMobile ? 8 : 12,
      horizontal: isMobile ? 12 : 16,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar Circle with status indicator
        Container(
          width: isMobile ? 32 : 40,
          height: isMobile ? 32 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[50],
            border: Border.all(
              color: Colors.blue,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.person,
              size: isMobile ? 16 : 20,
              color: Colors.blue[700],
            ),
          ),
        ),

        SizedBox(width: isMobile ? 8 : 12),

        // User Info Column
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bienvenue',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              displayName,
              style: TextStyle(
                color: Colors.black,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(width: isMobile ? 4 : 8),

        // Status Indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _navigateToRoute(BuildContext context, String route) {
  setState(() {
    _currentRoute = route;
  });

  if (route == '/Accueilchef') {
    Get.offAll(() => const Accueilchef());
  } else if (route == '/dashboard') {
    Get.offAll(() => ChefEquipeDashboardScreen()); // Changed from Controller to Screen
  }
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
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authProvider.logout();
              Get.offAllNamed('/login');
            },
            child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}