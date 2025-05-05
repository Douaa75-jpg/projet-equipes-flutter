import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import '../../AuthProvider.dart';
import '../../services/RH_service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart';
import '../../services/notification_service.dart';
import '../layoutt/rh_layout.dart';

class RHDashboardScreen extends StatefulWidget {
  final NotificationService notificationService;
  
  const RHDashboardScreen({
    super.key,
    required this.notificationService,
  });

  @override
  _RHDashboardScreenState createState() => _RHDashboardScreenState();
}

class _RHDashboardScreenState extends State<RHDashboardScreen> {
  final RhService rhService = RhService();
  final PointageService pointageService = PointageService();
  final DemandeService demandeService = DemandeService();
  late AuthProvider authProvider;
  late ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);
    theme = Theme.of(context);
  }

  int _calculateLeaveDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return RhLayout(
      notificationService: widget.notificationService,
      title: 'Tableau de bord RH',
      child: _buildBody(context, authProvider, theme),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(authProvider, theme),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 32),
          _buildUpcomingLeavesSection(theme),
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
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
      childAspectRatio = 2;
    } else if (screenWidth < 1200) {
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
          valueFuture: rhService.getEmployesCount(),
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
          title: 'Présent aujourd\'hui',
          valueFuture: pointageService.getNombreEmployesPresentAujourdhui(),
          icon: Icons.check_circle_outline,
          color: Colors.purple,
          trend: 'Dernière mise à jour: ${DateFormat('HH:mm').format(DateTime.now())}',
        ),
        StatCard(
          title: 'Congés à venir',
          valueFuture: demandeService.getUpcomingLeaves()
              .then((conges) => conges.length)
              .catchError((e) {
            log('Error fetching upcoming leaves: $e');
            return 0;
          }),
          icon: Icons.event_available, // Changed from event_upcoming to event_available
          color: Colors.teal,
          trend: 'Prochain congé',
        ),
      ],
    );
  }

  Widget _buildUpcomingLeavesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Congés à venir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Voir tout'),
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
            height: 300,
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<List<dynamic>>(
              future: demandeService.getUpcomingLeaves(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun congé à venir'));
                } else {
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final conge = snapshot.data![index];
                      final dateDebut = DateTime.parse(conge['dateDebut']);
                      final dateFin = DateTime.parse(conge['dateFin']);
                      final jours = _calculateLeaveDays(dateDebut, dateFin);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              '${conge['employe']['utilisateur']['prenom'][0]}${conge['employe']['utilisateur']['nom'][0]}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${conge['employe']['utilisateur']['prenom']} ${conge['employe']['utilisateur']['nom']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(dateDebut)} - ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Text(
                            '$jours jours',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.dividerColor.withAlpha(26),
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
                '3 employés fêtent leur anniversaire aujourd\'hui',
                'il y a 5 heures',
                false,
              ),
              const Divider(height: 1),
              _buildNotificationItem(
                Icons.assignment_turned_in,
                'Séance d\'entraînement prévue pour demain',
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
    IconData icon, 
    String text, 
    String time, 
    bool isUnread
  ) {
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
          color: Theme.of(context).dividerColor.withAlpha(26),
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
            Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}