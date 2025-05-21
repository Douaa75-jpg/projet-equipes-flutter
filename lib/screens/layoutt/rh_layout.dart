import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../auth_controller.dart';
import '../acceuil/Accueil_RH.dart';
import '../dashboard/rh_dashboard_screen.dart';
import '../../services/notification_service.dart';
import '../leave/gestion_demande__Screen.dart';
import '../Listes/liste_employe.dart';
import '../Listes/liste_chef.dart';
import 'package:get_storage/get_storage.dart';

class RhLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int pendingTasks;

  const RhLayout({
    super.key,
    required this.child,
    this.title = 'Accueil',
    this.pendingTasks = 0,
  });

  @override
  State<RhLayout> createState() => _RhLayoutState();
}

class _RhLayoutState extends State<RhLayout> {
  final NotificationService notificationService = Get.find<NotificationService>();
  final AuthProvider authProvider = Get.find<AuthProvider>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GetStorage box = GetStorage();

  @override
  void initState() {
    super.initState();
    authProvider.checkAuthStatus();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    notificationService.lastNotification.listen((message) {
      if (message.isNotEmpty) {
        Get.snackbar(
          'notification'.tr,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    });
  }

  String get _currentRoute => Get.currentRoute;

  Widget _buildUserInfo({bool isMobile = false}) {
    return Obx(() {
      final displayName = (authProvider.prenom.value.isEmpty && authProvider.nom.value.isEmpty)
          ? 'welcome'.tr
          : '${authProvider.prenom.value} ${authProvider.nom.value}'.trim();

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 6 : 8,
          horizontal: isMobile ? 10 : 12,
        ),
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
                Text(
                  'welcome'.tr,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: isMobile ? 12 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Icon(
              Icons.person_outline,
              color: Colors.blue,
              size: isMobile ? 20 : 24,
            ),
          ],
        ),
      );
    });
  }

 

  void _showNotificationsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('notifications'.tr),
        content: Obx(() {
          if (notificationService.notifications.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('no_notifications'.tr),
            );
          }
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                return ListTile(
                  leading: Icon(
                    notification['type'] == 'rh_response' 
                      ? Icons.work 
                      : Icons.person,
                    size: 20,
                  ),
                  title: Text(
                    notification['message'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      DateTime.parse(notification['createdAt']),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    notificationService.markAsRead(notification['id']);
                    if (notification['type'] == 'rh_response') {
                      Get.to(() => GestionDemandeScreen());
                    }
                  },
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () {
              notificationService.markAllAsRead();
              Get.back();
            },
            child: Text('mark_all_read'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
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
          _buildNavItem(context, 'accueil'.tr, '/accueilRH', _currentRoute == '/accueilRH'),
          _buildNavItem(context, 'Tableau de bord'.tr, '/dashboard', _currentRoute == '/dashboard'),
          _buildNavItem(context, 'employees'.tr, '/liste-employes', _currentRoute == '/liste-employes'),
          _buildNavItem(context, 'chefs_équipe'.tr, '/liste-chefs', _currentRoute == '/liste-chefs'),
          _buildNavItem(context, 'Toutes les demandes'.tr, '/Notifications', _currentRoute == '/Notifications'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            onPressed: () {},
            tooltip: 'search'.tr,
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
                Obx(() => Text(
                  '${authProvider.prenom.value} ${authProvider.nom.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          _buildMobileNavItem(context, Icons.home, 'home'.tr, '/accueilRH'),
          _buildMobileNavItem(context, Icons.dashboard, 'dashboard'.tr, '/dashboard'),
          _buildMobileNavItem(context, Icons.people, 'employees'.tr, '/liste-employes'),
          _buildMobileNavItem(context, Icons.people_outline, 'team_leaders'.tr, '/liste-chefs'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('settings'.tr),
            onTap: () { 
              Navigator.pop(context);
              _showSettingsDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('logout'.tr, style: const TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusItem(Icons.update,
                    'last_update'.trParams({'time': DateFormat('HH:mm').format(DateTime.now())})),
                const SizedBox(height: 8),
                _buildStatusItem(Icons.cloud, 'services_online'.tr, isOnline: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final currentLocale = Get.locale;

    Get.dialog(
      AlertDialog(
        title: Text('settings'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr),
                trailing: DropdownButton<Locale>(
                  value: currentLocale,
                  items: const [
                    DropdownMenuItem(
                      value: Locale('fr', 'FR'),
                      child: Text('Français'),
                    ),
                    DropdownMenuItem(
                      value: Locale('en', 'US'),
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      Get.updateLocale(newLocale);
                      box.write('locale', {
                        'languageCode': newLocale.languageCode,
                        'countryCode': newLocale.countryCode
                      });
                      Get.back();
                      Get.snackbar(
                        'success'.tr,
                        'language_changed'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
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

  Widget _buildNavItem(BuildContext context, String title, String route, bool isActive) {
    return InkWell(
      onTap: () => _navigateToRoute(route),
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

  Widget _buildMobileNavItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _navigateToRoute(route);
      },
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            _showSettingsDialog(context);
            break;
          case 'logout':
            _showLogoutDialog();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings, color: Colors.black54),
              const SizedBox(width: 8),
              Text('settings'.tr),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              Text('logout'.tr, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToRoute(String route) {
    if (route == _currentRoute) return;
    
    switch (route) {
      case '/accueilRH':
        Get.offAll(() => const AccueilRh());
        break;
      case '/dashboard':
        Get.offAll(() => RHDashboardScreen());
        break;
      case '/liste-employes':
        Get.offAll(() =>  ListeEmployeScreen());
        break;
      case '/liste-chefs':
        Get.offAll(() => ListeChefScreen(notificationService: notificationService));
        break;
      case '/Notifications':
        Get.offAll(() => GestionDemandeScreen());
        break;
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('confirm_logout'.tr),
        content: Text('confirm_logout_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authProvider.logout();
              Get.offAllNamed('/login');
            },
            child: Text('logout'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth < 1024;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: isMobile ? _buildMobileDrawer(context) : null,
          appBar: AppBar(
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'menu'.tr,
                  )
                : null,
            title: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: isMobile ? 40 : (isTablet ? 50 : 60),
                  width: isMobile ? 40 : (isTablet ? 50 : 60),
                  fit: BoxFit.contain,
                ),
                if (!isMobile) const Spacer(),
                if (!isMobile) 
                  Row(
                    children: [
                      _buildUserInfo(isMobile: isMobile),
                      const SizedBox(width: 16),
                      _buildStatusItem(Icons.cloud, 'services_online'.tr, isOnline: true),
                    ],
                  ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
            toolbarHeight: isMobile ? 60 : (isTablet ? 70 : 80),
          ),
          body: Column(
            children: [
              if (!isMobile) _buildDesktopNavBar(context),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}