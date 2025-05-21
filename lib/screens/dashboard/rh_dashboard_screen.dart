import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import '../../auth_controller.dart';
import '../../services/RH_service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart';
import '../../services/notification_service.dart';
import '../layoutt/rh_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

class RHDashboardController extends GetxController {
  final RhService rhService = Get.find<RhService>();
  final PointageService pointageService = PointageService();
  final DemandeService demandeService = DemandeService();
  final NotificationService notificationService = Get.find<NotificationService>();
  final AuthProvider authProvider = Get.find<AuthProvider>();

  final RxBool isLoading = false.obs;
  final RxList<dynamic> upcomingLeaves = <dynamic>[].obs;

  final Rx<Map<String, dynamic>> attendanceStats = Rx<Map<String, dynamic>>({});
  final Rx<Map<String, dynamic>> presenceWeekdayStats = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    loadUpcomingLeaves();
    loadPresenceWeekdayStats();
  }

  Future<void> loadUpcomingLeaves() async {
    try {
      isLoading.value = true;
      final leaves = await demandeService.getUpcomingLeaves();
      upcomingLeaves.assignAll(leaves);
    } catch (e) {
      log('Error loading upcoming leaves: $e');
    } finally {
      isLoading.value = false;
    }
  }

Future<void> loadPresenceWeekdayStats() async {
  try {
    isLoading.value = true;
    final now = DateTime.now();
    
    // حساب تاريخ بداية الأسبوع الحالي (الإثنين)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // استخدام تنسيق التاريخ
    final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final endDate = DateFormat('yyyy-MM-dd').format(now);

    final stats = await pointageService.getPresenceByWeekdayForAllEmployees(
      startDate,
      endDate,
    );
     // التأكد من أن البيانات تحتوي فقط على 5 أيام (من الاثنين إلى الجمعة)
    if (stats['labels'] != null && stats['labels'].length > 5) {
      stats['labels'] = stats['labels'].sublist(0, 5);
      stats['datasets'][0]['data'] = stats['datasets'][0]['data'].sublist(0, 5);
    }
    
    
    presenceWeekdayStats.value = stats;
  } catch (e) {
    log('Error loading presence weekday stats: $e');
  } finally {
    isLoading.value = false;
  }
}

  int calculateLeaveDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
}

class RHDashboardScreen extends StatelessWidget {
  final RHDashboardController controller = Get.put(RHDashboardController());

  RHDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RhLayout(
      title: 'Tableau de bord RH',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(isMobile, isTablet, constraints.maxWidth),
                SizedBox(height: isMobile ? 16 : 24),
                if (isMobile) ...[
                  _buildCalendarSection(isMobile, height: 380),
                  SizedBox(height: 16),
                  _buildPresenceChart(height: 380),
                ] else ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: isTablet ? 3 : 2,
                          child: _buildCalendarSection(isMobile, height: 450),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        Expanded(
                          flex: isTablet ? 5 : 3,
                          child: _buildPresenceChart(height: 450),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: isMobile ? 16 : 24),
                _buildUpcomingLeavesSection(isMobile),
                SizedBox(height: 16), // Extra space at bottom
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isMobile, bool isTablet, double maxWidth) {
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = maxWidth < 400 ? 1 : 2;
      childAspectRatio = maxWidth < 400 ? 1.8 : 1.3;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.5;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: isMobile ? 10 : 16,
      mainAxisSpacing: isMobile ? 10 : 16,
      children: [
        _build3DStatCard(
          title: 'Total Employees',
          valueFuture: controller.rhService.getEmployesCount(),
          icon: Icons.people_outline,
          color: const Color.fromARGB(255, 91, 127, 154),
          trend: 'No change',
          isMobile: isMobile,
        ),
        _build3DStatCard(
          title: 'Total Chef Equipe',
          valueFuture: controller.rhService.getResponsablesCount(),
          icon: Icons.supervisor_account,
          color: const Color.fromARGB(255, 96, 152, 99),
          trend: 'No change',
          isMobile: isMobile,
        ),
        _build3DStatCard(
          title: 'Présent aujourd\'hui',
          valueFuture: controller.pointageService.getNombreEmployesPresentAujourdhui(),
          icon: Icons.check_circle_outline,
          color: const Color.fromARGB(255, 162, 105, 171),
          trend: 'Dernière mise à jour: ${DateFormat('HH:mm').format(DateTime.now())}',
          isMobile: isMobile,
        ),
        _build3DStatCard(
          title: 'Prochain congé',
          valueFuture: controller.demandeService.getUpcomingLeaves().then((conges) => conges.length).catchError((e) {
            log('Error fetching upcoming leaves: $e');
            return 0;
          }),
          icon: Icons.event_available,
          color: Colors.teal,
          trend: 'Prochain congé',
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _build3DStatCard({
    required String title,
    required Future<int> valueFuture,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isMobile,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isMobile ? 44 : 52,
              height: isMobile ? 44 : 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha(230),
                    color.withAlpha(179),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: isMobile ? 22 : 26,
                  color: Colors.white,
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            
            SizedBox(height: isMobile ? 4 : 8),
            
            FutureBuilder<int>(
              future: valueFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: isMobile ? 28 : 36,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    '--',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[400],
                    ),
                  );
                } else {
                  return Text(
                    '${snapshot.data ?? 0}',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  );
                }
              },
            ),
            
            SizedBox(height: isMobile ? 8 : 12),
            
            Row(
              children: [
                Icon(
                  trend.contains('↑') ? Icons.trending_up : 
                  trend.contains('↓') ? Icons.trending_down : Icons.trending_flat,
                  size: isMobile ? 16 : 18,
                  color: trend.contains('↑') ? Colors.green : 
                        trend.contains('↓') ? Colors.red : Colors.grey,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(bool isMobile, {double? height}) {
  return SizedBox(
    height: height,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajouté pour éviter l'expansion
          children: [
            Text(
              'Calendrier',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: DateTime.now(),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left, 
                      size: isMobile ? 18 : 22),
                  rightChevronIcon: Icon(Icons.chevron_right, 
                      size: isMobile ? 18 : 22),
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  headerPadding: EdgeInsets.only(
                    bottom: isMobile ? 4 : 8, // Réduit encore le padding
                  ),
                  leftChevronMargin: EdgeInsets.only(left: 8), // Ajouté
                  rightChevronMargin: EdgeInsets.only(right: 8), // Ajouté
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Get.theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Get.theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(
                    color: Colors.red.withAlpha((0.8 * 255).toInt()),
                  ),
                  cellPadding: EdgeInsets.all(isMobile ? 2 : 4), // Réduit
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                rowHeight: isMobile ? 32 : 40, // Hauteur réduite
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Container(
              padding: EdgeInsets.symmetric( // Changé à symmetric pour plus de contrôle
                vertical: isMobile ? 6 : 8,
                horizontal: isMobile ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Empêche l'expansion
                children: [
                  Icon(Icons.today, size: isMobile ? 18 : 22), // Taille réduite
                  SizedBox(width: isMobile ? 6 : 8),
                  Flexible( // Permet au texte de s'adapter
                    child: Text(
                      DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14, // Taille réduite
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPresenceChart({double? height}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: height,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final data = controller.presenceWeekdayStats.value;
       final labels = List<String>.from(data['labels'] ?? ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi']);
      final datasets = List<Map<String, dynamic>>.from(data['datasets'] ?? []);
      final rawData = Map<String, dynamic>.from(data['rawData'] ?? {});

      if (datasets.isEmpty || labels.isEmpty) {
        return SizedBox(
          height: height,
          child: Center(
            child: Text(
              'Aucune donnée de présence disponible',
            ),
          ),
        );
      }

      double minValue = 100;
      int minIndex = 0;
      final presenceData = datasets[0]['data'] as List<dynamic>;
      for (int i = 0; i < presenceData.length; i++) {
        final value = presenceData[i] as double;
        if (value < minValue) {
          minValue = value;
          minIndex = i;
        }
      }

      return SizedBox(
        height: height,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taux de présence par jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = labels[group.x.toInt()];
                            final value = rod.toY.toInt();
                            final present = rawData['presence']?[groupIndex] ?? 0;
                            final totalEmployees = controller.rhService.employees.length;
                            
                            return BarTooltipItem(
                              '$day\nTaux: $value%\nPrésents: $present/$totalEmployees',
                              const TextStyle(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                labels[value.toInt()],
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}%');
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(labels.length, (index) {
                        final value = presenceData[index] as double;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              width: 22,
                              color: _getBarColor(index == minIndex, value.toInt()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getBarColor(bool isMin, int value) {
    if (isMin) {
      return Colors.red;
    } else if (value >= 80) {
      return Colors.green;
    } else if (value >= 60) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  Widget _buildUpcomingLeavesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Congés à venir',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          child: Container(
            height: isMobile ? 220 : 300,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (controller.upcomingLeaves.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun congé à venir',
                  ),
                );
              } else {
                return ListView.builder(
                  itemCount: controller.upcomingLeaves.length,
                  itemBuilder: (context, index) {
                    final conge = controller.upcomingLeaves[index];
                    final dateDebut = DateTime.parse(conge['dateDebut']);
                    final dateFin = DateTime.parse(conge['dateFin']);
                    final jours = controller.calculateLeaveDays(dateDebut, dateFin);

                    return Card(
                      margin: EdgeInsets.symmetric(
                          vertical: isMobile ? 4 : 6, 
                          horizontal: isMobile ? 4 : 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            '${conge['employe']['utilisateur']['prenom'][0]}${conge['employe']['utilisateur']['nom'][0]}',
                          ),
                        ),
                        title: Text(
                          '${conge['employe']['utilisateur']['prenom']} ${conge['employe']['utilisateur']['nom']}',
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(dateDebut)} - ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                        ),
                        trailing: Chip(
                          label: Text('$jours jours'),
                        ),
                      ),
                    );
                  },
                );
              }
            }),
          ),
        ),
      ],
    );
  }
}