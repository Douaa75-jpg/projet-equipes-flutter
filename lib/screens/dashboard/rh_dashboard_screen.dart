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
      final startDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      final endDate = DateFormat('yyyy-MM-dd').format(now);

      final stats = await pointageService.getPresenceByWeekdayForAllEmployees(
        startDate,
        endDate,
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(isMobile, isTablet),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile) ...[
                _buildCalendarSection(isMobile),
                SizedBox(height: 16),
                _buildPresenceChart(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isTablet ? 3 : 2,
                      child: _buildCalendarSection(isMobile),
                    ),
                    SizedBox(width: isTablet ? 12 : 16),
                    Expanded(
                      flex: isTablet ? 5 : 3,
                      child: _buildPresenceChart(),
                    ),
                  ],
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),
              _buildUpcomingLeavesSection(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isMobile, bool isTablet) {
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
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
          trend: '↑ 2% from last month',
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
          title: 'Congés à venir',
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
  return Transform(
    transform: Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(-0.1),
    alignment: FractionalOffset.center,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background decorative element
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withAlpha((0.05 * 255).round()),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with modern design
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
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isMobile ? 22 : 26,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                SizedBox(height: isMobile ? 16 : 20),
                
                // Title with subtle uppercase
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
                
                // Main value with animated counter
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
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          '${snapshot.data ?? 0}',
                          key: ValueKey<int>(snapshot.data ?? 0),
                          style: TextStyle(
                            fontSize: isMobile ? 28 : 36,
                            fontWeight: FontWeight.w800,
                            color: color,
                            height: 1.1,
                          ),
                        ),
                      );
                    }
                  },
                ),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Trend indicator with dynamic arrow
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
        ],
      ),
    ),
  );
}

  Widget _buildCalendarSection(bool isMobile) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.05),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        ),
        shadowColor: Get.theme.primaryColor.withOpacity(0.3),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            children: [
              Text(
                'Calendrier',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: DateTime.now(),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left, 
                    color: Get.theme.primaryColor,
                    size: isMobile ? 20 : 24),
                rightChevronIcon: Icon(Icons.chevron_right, 
                    color: Get.theme.primaryColor,
                    size: isMobile ? 20 : 24),
                titleTextStyle: TextStyle(
                  color: Get.theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
                headerPadding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 12,
                ),
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
                weekendTextStyle: TextStyle( // Déplacé ici depuis DaysOfWeekStyle
                  color: Colors.red.withAlpha((0.8 * 255).toInt()),
                ),
                defaultTextStyle: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Get.theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
                weekendStyle: TextStyle( // Certaines versions utilisent encore weekendStyle ici
                  color: Colors.red.withAlpha((0.8 * 255).toInt()),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
              SizedBox(height: isMobile ? 12 : 16),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Get.theme.primaryColor.withOpacity(0.1),
                      Get.theme.primaryColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(
                    color: Get.theme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, 
                        color: Get.theme.primaryColor,
                        size: isMobile ? 24 : 28),
                    SizedBox(width: isMobile ? 8 : 12),
                    Text(
                      DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Get.theme.textTheme.titleLarge?.color,
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

  Widget _buildPresenceChart() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final data = controller.presenceWeekdayStats.value;
      final labels = List<String>.from(data['labels'] ?? []);
      final datasets = List<Map<String, dynamic>>.from(data['datasets'] ?? []);
      final rawData = Map<String, dynamic>.from(data['rawData'] ?? {});

      if (datasets.isEmpty || labels.isEmpty) {
        return Center(
          child: Text(
            'Aucune donnée de présence disponible',
            style: TextStyle(
              color: Get.theme.textTheme.titleLarge?.color,
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

      return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-0.05),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              ),
              shadowColor: Get.theme.primaryColor.withOpacity(0.3),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Taux de présence par jour',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Get.theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        if (!isMobile)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Faible: ${labels[minIndex]} (${minValue.toInt()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    SizedBox(
                      height: isMobile ? 180 : 250,
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.blueGrey,
                              tooltipRoundedRadius: 8,
                              tooltipPadding: EdgeInsets.all(12),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                if ( rod.toY == 0) return null;
                                final day = labels[group.x.toInt()];
                                final value = rod.toY.toInt();
                                final present = rawData['presence']?[groupIndex] ?? 0;
                                final totalEmployees = controller.rhService.employees.length;
                                
                                return BarTooltipItem(
                                  '$day\nTaux: $value%\nPrésents: $present/$totalEmployees',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[value.toInt()],
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 12,
                                        color: Get.theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: isMobile ? 30 : 42,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      color: Get.theme.textTheme.bodyLarge?.color,
                                    ),
                                  );
                                },
                                reservedSize: isMobile ? 30 : 40,
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Get.theme.dividerColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          barGroups: List.generate(labels.length, (index) {
                            final value = presenceData[index] as double;
                            
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  width: isMobile ? 16 : 22,
                                  gradient: _getBarGradient(
                                    index == minIndex,
                                    value.toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 100,
                                    color: Get.theme.dividerColor.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            );
                          }),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Get.theme.dividerColor.withOpacity(0.3),
                                strokeWidth: 1,
                                dashArray: [4],
                              );
                            },
                            horizontalInterval: 20,
                          ),
                        ),
                      ),
                    ),
                    if (isMobile)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Jour avec faible présence: ${labels[minIndex]} (${minValue.toInt()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  LinearGradient _getBarGradient(bool isMin, int value) {
    if (isMin) {
      return LinearGradient(
        colors: [
          Colors.red.shade400,
          Colors.red.shade600,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else if (value >= 80) {
      return LinearGradient(
        colors: [
          Colors.green.shade400,
          Colors.green.shade600,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else if (value >= 60) {
      return LinearGradient(
        colors: [
          Colors.orange.shade400,
          Colors.orange.shade600,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.blue.shade400,
          Colors.blue.shade600,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    }
  }

  Widget _buildUpcomingLeavesSection(bool isMobile) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.05),
      child: Column(
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
                  color: Get.theme.textTheme.titleLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    color: Get.theme.primaryColor,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            ),
            shadowColor: Get.theme.primaryColor.withOpacity(0.3),
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
                      style: TextStyle(
                        color: Get.theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  );
                } else {
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.upcomingLeaves.length,
                    itemBuilder: (context, index) {
                      final conge = controller.upcomingLeaves[index];
                      final dateDebut = DateTime.parse(conge['dateDebut']);
                      final dateFin = DateTime.parse(conge['dateFin']);
                      final jours = controller.calculateLeaveDays(dateDebut, dateFin);

                      return Container(
                        margin: EdgeInsets.symmetric(
                            vertical: isMobile ? 2 : 4, 
                            horizontal: isMobile ? 4 : 8),
                        decoration: BoxDecoration(
                          color: Get.theme.cardColor,
                          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 4 : 8,
                          ),
                          leading: Container(
                            width: isMobile ? 36 : 40,
                            height: isMobile ? 36 : 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Get.theme.primaryColor.withOpacity(0.7),
                                  Get.theme.primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${conge['employe']['utilisateur']['prenom'][0]}${conge['employe']['utilisateur']['nom'][0]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '${conge['employe']['utilisateur']['prenom']} ${conge['employe']['utilisateur']['nom']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(dateDebut)} - ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 8, 
                                vertical: isMobile ? 2 : 4),
                            decoration: BoxDecoration(
                              color: Get.theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                            ),
                            child: Text(
                              '$jours jours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Get.theme.primaryColor,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
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
      ),
    );
  }
}