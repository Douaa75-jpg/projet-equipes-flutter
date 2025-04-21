import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../AuthProvider.dart';
import '../../services/RH_service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import '../../services/notification_service.dart';
import '../Notification_Screen.dart';
import '../Listes/liste_employe.dart';
import '../Listes/liste_chef.dart';

class RHDashboardScreen extends StatefulWidget {
  RHDashboardScreen({super.key});

  @override
  _RHDashboardScreenState createState() => _RHDashboardScreenState();
}

class _RHDashboardScreenState extends State<RHDashboardScreen> {
  final RhService rhService = RhService();
  final PointageService pointageService = PointageService();
  final DemandeService demandeService = DemandeService();
  Widget _currentScreen = Container();
  late AuthProvider authProvider;
  late ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);
    theme = Theme.of(context);
    _currentScreen = _buildBody(context, authProvider, theme);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(context, authProvider, isDarkMode),
      appBar: _buildAppBar(context, theme),
      body: _currentScreen,
    );
  }

  Widget _buildDrawer(
      BuildContext context, AuthProvider authProvider, bool isDarkMode) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [Colors.blueGrey[800]!, Colors.blueGrey[900]!]
                    : [
                        const Color.fromARGB(255, 210, 25, 25),
                        const Color.fromARGB(255, 192, 21, 21)
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('ZETABOX RH',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (authProvider.nom != null && authProvider.prenom != null)
                  Text(
                    '${authProvider.prenom} ${authProvider.nom}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                const SizedBox(height: 4),
                Text(
                  'HR Manager',
                  style: TextStyle(
                     color: Colors.white.withAlpha(204),fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Tableau de bord', () {
             setState(() => _currentScreen = RHDashboardScreen());
            Navigator.pop(context);
          }),
          _buildDrawerItem(context, Icons.people_alt, 'Liste Employees', () {
             setState(() => _currentScreen = ListeEmployeScreen());
            Navigator.pop(context);
          }),
          _buildDrawerItem(
              context, Icons.supervisor_account, 'Liste Chef Equipe', () {
                setState(() => _currentScreen = ListeChefScreen());
            Navigator.pop(context);
              }),
          _buildDrawerItem(
              context, Icons.notifications_active, 'Notifications', () {
                 setState(() => _currentScreen = NotificationScreen());
            Navigator.pop(context);

              }),
          _buildDrawerItem(context, Icons.request_page, 'Requests', () {}),
          const Divider(height: 20, thickness: 1),
          _buildDrawerItem(context, Icons.settings, 'Paramètres', () {}),
          _buildDrawerItem(
              context, Icons.help_outline, 'Aide et assistance', () {}),
          _buildDrawerItem(context, Icons.logout, 'Déconnexion', () {
            // Add logout functionality
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      horizontalTitleGap: 8,
      minLeadingWidth: 24,
      onTap: onTap,
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: const Text('HR Tableau de bord',
          style: TextStyle(fontWeight: FontWeight.w600)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {},
          tooltip: 'Profile',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
         color: theme.dividerColor.withAlpha(26),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(authProvider, theme),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 32),
          _buildRecentRequestsSection(theme),
          const SizedBox(height: 32),
          _buildNotificationsSection(theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(AuthProvider authProvider, ThemeData theme) {
  final isDarkMode = theme.brightness == Brightness.dark;
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.blueGrey[800] : Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Partie gauche avec l'icône
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.blueGrey[700] : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            size: 30,
            color: isDarkMode ? Colors.white : Colors.blue[700],
          ),
        ),
        const SizedBox(width: 16),
        
        // Partie droite avec le texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue,',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${authProvider.prenom ?? ''} ${authProvider.nom ?? ''}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.blueGrey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Voici votre tableau de bord RH',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white60 : Colors.blueGrey[500],
                ),
              ),
            ],
          ),
        ),
        
        // Optionnel: Badge ou indicateur
        if (authProvider.role != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[600] : Colors.blue[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              authProvider.role!.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildStatsGrid(BuildContext context) {
    
    final screenWidth = MediaQuery.of(context).size.width;
    final rhService = RhService();
    
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth < 600) {
      // هواتف (عرض أقل من 600px)
      crossAxisCount = 1;
      childAspectRatio = 2;
    } else if (screenWidth < 900) {
      // أجهزة لوحية صغيرة (عرض بين 600px و900px)
      crossAxisCount = 2;
      childAspectRatio = 2;
    } else if (screenWidth < 1200) {
      // أجهزة لوحية كبيرة/حواسيب صغيرة
      crossAxisCount = 3;
      childAspectRatio = 2;
    } else {
      
      crossAxisCount = 4;
      childAspectRatio = 2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          title: 'Total Employees',
          valueFuture: rhService.getEmployesCount(), // Utilisez le service
          icon: Icons.people_outline,
          color: Colors.blue,
          trend: '↑ 2% from last month',
        ),
        StatCard(
          title: 'Total Chef Equipe',
          valueFuture: rhService.getResponsablesCount(),
          icon: Icons.supervisor_account,
          color: Colors.green,
          trend: 'No change',
        ),
        StatCard(
          title: 'absences aujourd\'hui',
          valueFuture: pointageService.getNombreEmployesAbsentAujourdhui()
        .catchError((e) {
          log('Error fetching absences: $e');
          return 0; // Valeur par défaut en cas d'erreur
        }),
          icon: Icons.pending_actions,
          color: Colors.orange,
          trend: 'Dernière mise à jour:',
        ),
        StatCard(
          title: 'Présent aujourd\'hui',
          valueFuture: pointageService.getNombreEmployesPresentAujourdhui(),
          icon: Icons.check_circle_outline,
          color: Colors.purple,
         trend: 'Dernière mise à jour: ${DateTime.now().hour}:${DateTime.now().minute}',
        ),
      ],
    );
  }

  Widget _buildRecentRequestsSection(ThemeData theme) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Demandes récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('View All'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          height: 300, // Hauteur fixe pour le cadre
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<List<dynamic>>(
            future: demandeService.getAllDemandes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || 
                        (snapshot.data is! List) || 
                        snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucune demande récente'));
              } else {
                final demandes = snapshot.data is Map 
                    ? (snapshot.data as Map)['demandes'] ?? []
                    : snapshot.data as List;
                
                return ListView.builder(
                  physics: const BouncingScrollPhysics(), // Effet de rebond
                  itemCount: demandes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildRequestItem(
                        _getEmployeeName(demandes[index]),
                        _formatType(demandes[index]['type']?.toString() ?? 'Type inconnu'),
                        _formatDate(demandes[index]['dateDebut']),
                        _getStatusText(demandes[index]['statut']?.toString() ?? 'EN_ATTENTE'),
                        _getStatusColor(demandes[index]['statut']?.toString() ?? 'EN_ATTENTE'),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    ],
  );
}
String _getEmployeeName(Map<String, dynamic> demande) {
  if (demande['employe'] != null && 
      demande['employe']['utilisateur'] != null) {
    return '${demande['employe']['utilisateur']['prenom']} ${demande['employe']['utilisateur']['nom']}';
  }
  return 'Employé inconnu';
}
String _formatDate(dynamic date) {
  if (date == null) return 'Date inconnue';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(date.toString()));
  } catch (e) {
    return 'Date invalide';
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'APPROUVEE':
      return Colors.green;
    case 'REJETEE':
      return Colors.red;
    case 'EN_ATTENTE':
    default:
      return Colors.orange;
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'APPROUVEE':
      return 'Approuvée';
    case 'REJETEE':
      return 'Rejetée';
    case 'EN_ATTENTE':
    default:
      return 'En attente';
  }
}
String _formatType(String type) {
  switch (type) {
    case 'congé':
      return 'Congé';
    case 'absence':
      return 'Absence';
    case 'autorization_sortie':
      return 'Autorisation de sortie';
    default:
      return type;
  }
}
 Widget _buildRequestItem(
    String name, String type, String date, String status, Color statusColor) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey[50], // Fond légèrement gris pour chaque item
    ),
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 20,
          child: Icon(Icons.person, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, 
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  )),
              const SizedBox(height: 4),
              Text(type,
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 12,
                  )),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(date, 
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 12,
                )),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildNotificationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.dividerColor.withValues(alpha: 26),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildNotificationItem(
                Icons.notification_important,
                'Nouvelle demande de Salim - Autorisation de sortie',
                'il y a 2 heures',
                true,
              ),
              const Divider(height: 1),
              _buildNotificationItem(
                Icons.event_available,
                '3 employés fêtent leur anniversaire aujourd''hui',
                'il y a 5 heures',
                false,
              ),
              const Divider(height: 1),
              _buildNotificationItem(
                Icons.assignment_turned_in,
                'Séance d''entraînement prévue pour demain',
                'il y a 1 jour',
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
      IconData icon, String text, String time, bool isUnread) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue.withAlpha(26) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isUnread ? Colors.blue : Colors.grey,
        ),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(time, style: const TextStyle(fontSize: 12)),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minLeadingWidth: 8,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final Future<int> valueFuture;
  final IconData icon;
  final Color color;
  final String trend;

  const StatCard({
    super.key,
    required this.title,
    required this.valueFuture,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
         color: Theme.of(context).dividerColor.withValues(alpha: 26),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                FutureBuilder<int>(
                  future: valueFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error', style: TextStyle(fontSize: 24));
                    } else {
                      return Text(
                        '${snapshot.data ?? 0}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            if (trend != null)
              FutureBuilder<int>(
                future: RhService().getEmployesCount(),
                builder: (context, employeCountSnapshot) {
                  if (employeCountSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  return FutureBuilder<int>(
                    future: valueFuture,
                    builder: (context, presentCountSnapshot) {
                      if (presentCountSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }
                      final present = presentCountSnapshot.data ?? 0;
                      final total = employeCountSnapshot.data ?? 1;
                      final percentage = (present / total * 100).toStringAsFixed(1);
                      
                      return Text(
                        '$percentage% attendance',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}