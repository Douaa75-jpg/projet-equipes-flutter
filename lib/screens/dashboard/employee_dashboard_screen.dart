import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth_controller.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/pointage_service.dart';
import '../../services/notification_service.dart';
import '../../services/demande_service.dart';
import '../layoutt/employee_layout.dart';
import '../../services/Employe_Service.dart';

class EmployeeDashboardController extends GetxController {
  final PointageService _pointageService = Get.find();
  final DemandeService _demandeService = Get.find();
  final NotificationService _notificationService = Get.find();

  final RxMap<String, dynamic> pointageStatus = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> heuresTravail = <String, dynamic>{}.obs;
  final RxList<dynamic> historique = <dynamic>[].obs;
  final RxInt soldeConges = 0.obs;
  final RxInt nbAbsences = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool chartsLoading = true.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxMap<String, dynamic> weeklyChartData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> attendanceDistribution = <String, dynamic>{}.obs;
  final RxInt absences = 0.obs;
  final RxMap<DateTime, String> holidays = <DateTime, String>{}.obs;
  final Color primaryColor = const Color(0xFF8B0000);
  final Color secondaryColor = const Color(0xFFDAA520);

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
    loadDashboardData();
    loadHolidays(DateTime.now().year);
  }

  void initializeNotifications() {
    // Initialisation des notifications
  }

  Future<void> calculateAndUpdateAbsences() async {
  try {
    final authProvider = Get.find<AuthProvider>();
    if (!authProvider.isAuthenticated.value) return;

    final result = await Get.find<EmployeService>()
        .calculerEtMettreAJourAbsences(authProvider.userId.value);

    nbAbsences.value = result['nbAbsences'] ?? 0;
    
    // Optionnel: Afficher un message de succès
    if (Get.isSnackbarOpen) Get.back();
    Get.snackbar(
      'Succès',
      'Absences mises à jour: ${result['nbAbsences']} jours',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    debugPrint('Error calculating absences: $e');
    if (Get.isSnackbarOpen) Get.back();
    Get.snackbar(
      'Erreur',
      'Échec du calcul des absences: ${e.toString().replaceAll('Exception: ', '')}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

  Future<void> loadHolidays(int year) async {
    try {
      final response = await _demandeService.getJoursFeries(year);
      final holidaysMap = <DateTime, String>{};

      for (var holiday in response) {
        final date = DateTime.parse(holiday['date']);
        holidaysMap[DateTime(date.year, date.month, date.day)] = holiday['nom'];
      }

      holidays.value = holidaysMap;
    } catch (e) {
      debugPrint('Error loading holidays: $e');
    }
  }

 Future<void> loadDashboardData() async {
  isLoading.value = true;
  chartsLoading.value = true;

  try {
    final authProvider = Get.find<AuthProvider>();
    if (!authProvider.isAuthenticated.value) return;

    final employeId = authProvider.userId.value;

     final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dateStrr = DateFormat('yyyy-MM-dd').format(monday);
    
    // حساب وتحديث الغيابات أولاً
    await calculateAndUpdateAbsences(); // Changé de controller.calculateAndUpdateAbsences() à calculateAndUpdateAbsences()
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final date7Jours = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 7)));

    final results = await Future.wait([
      _pointageService.calculerHeuresTravail(employeId, dateStr, dateStr),
      _pointageService.getHistorique(employeId, dateStr),
      _demandeService.getSoldeConges(employeId),
      _pointageService.getWeeklyHoursChartData(employeId, dateStrr),
      _pointageService.getAttendanceDistribution(employeId, date7Jours, dateStr),
    ]);

    heuresTravail.value = results[0] as Map<String, dynamic>? ?? {};
    historique.value = results[1] as List<dynamic>? ?? [];
    soldeConges.value = results[2] as int? ?? 0;
    weeklyChartData.value = results[3] as Map<String, dynamic>? ?? {};
    attendanceDistribution.value = results[4] as Map<String, dynamic>? ?? {};
    
  } catch (e) {
    showSnackBar('Erreur lors du chargement des données: $e', Colors.red);
  } finally {
    isLoading.value = false;
    chartsLoading.value = false;
  }
}

  Future<void> handlePointage() async {
    try {
      final result = await _pointageService
          .enregistrerPointage(Get.find<AuthProvider>().userId.value);
      pointageStatus.value = result;
      await loadDashboardData();
      showSnackBar(result['message'], Colors.green);
    } catch (e) {
      showSnackBar('Erreur lors du pointage: $e', Colors.red);
    }
  }

  void showSnackBar(String message, Color color) {
  if (Get.isSnackbarOpen) Get.back();
  
  Get.snackbar(
    color == Colors.red ? 'Erreur' : 'Succès',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: color,
    colorText: Colors.white,
    borderRadius: 10,
    margin: const EdgeInsets.all(10),
    duration: const Duration(seconds: 3),
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
}

  void onDaySelected(DateTime day, DateTime focusedDay) {
    selectedDate.value = day;
    if (holidays.containsKey(DateTime(day.year, day.month, day.day))) {
      Get.defaultDialog(
        title: 'Jour férié',
        content: Text(
          holidays[DateTime(day.year, day.month, day.day)]!,
          textAlign: TextAlign.center,
        ),
        confirm: TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      );
    }
    loadDashboardData();
  }
}

class EmployeeDashboardScreen extends StatelessWidget {
  final EmployeeDashboardController controller =
      Get.put(EmployeeDashboardController());

  EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      title: 'Tableau de bord',
      child: Obx(() => controller.isLoading.value
          ? _buildLoadingIndicator()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isTablet = constraints.maxWidth < 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 10 : 16),
                  child: Column(
                    children: [
                      // Stats Cards - Responsive layout
                      if (isMobile) ...[
                        _buildMobileStatsGrid(),
                      ] else ...[
                        _buildDesktopStatsGrid(isTablet),
                      ],
                      SizedBox(height: isMobile ? 6 : 12),

                      // Main Content - Responsive layout
                      if (isMobile) ...[
                        _buildMobileContent(),
                      ] else ...[
                        _buildDesktopContent(isTablet),
                      ],
                      SizedBox(height: isMobile ? 6 : 12),

                      // History Table (full width)
                      _buildHistoryCard(isMobile),
                    ],
                  ),
                );
              },
            )),
    );
  }

  Widget _buildMobileStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 120), // Hauteur minimale
                child: _buildStatCard(
                  title: 'Heures travaillées',
                  value: controller.heuresTravail['totalHeuresFormatted'] ??
                      '0h 0min',
                  icon: Icons.access_time,
                  color: controller.primaryColor,
                  subtitle: 'Aujourd\'hui',
                  isMobile: true,
                ),
              ),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _buildStatCard(
                title: 'Absences',
                value: '${controller.nbAbsences.value} jours',
                icon: Icons.warning_amber_rounded,
                color: controller.nbAbsences.value > 3 ? Colors.red : Colors.orange,
                subtitle: 'Total absences', 
                isMobile: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: 120), // Même hauteur
          child: _buildStatCard(
            title: 'Solde de congés',
            value: '${controller.soldeConges.value} jours',
            icon: Icons.beach_access,
            color: Colors.blue.shade600,
            isMobile: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatsGrid(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Heures travaillées',
            value:
                controller.heuresTravail['totalHeuresFormatted'] ?? '0h 0min',
            icon: Icons.access_time,
            color: controller.primaryColor,
            subtitle: 'Aujourd\'hui',
            isMobile: false,
          ),
        ),
        SizedBox(width: isTablet ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            title: 'Absences',
            value:
                '${controller.nbAbsences.value} jours', // استخدم nbAbsences هنا
            icon: Icons.warning_amber_rounded,
            color: controller.nbAbsences.value > 3 ? Colors.red : Colors.orange,
            subtitle: '30 derniers jours',
            isMobile: true,
          ),
        ),
        SizedBox(width: isTablet ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            title: 'Solde de congés',
            value: '${controller.soldeConges.value} jours',
            icon: Icons.beach_access,
            color: Colors.blue.shade600,
            subtitle: 'Aujourd\'hui',
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    required bool isMobile,
  }) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.1),
      alignment: FractionalOffset.center,
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(isMobile ? 12 : 16), // تصغير نصف القطر
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 12, // تصغير التمويه
              spreadRadius: 1,
              offset: const Offset(0, 6), // تصغير الإزاحة
            ),
          ],
          border: Border.all(
            color: Colors.grey.withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15, // تصغير الموضع
              top: -15, // تصغير الموضع
              child: Container(
                width: 60, // تصغير الحجم
                height: 60, // تصغير الحجم
                decoration: BoxDecoration(
                  color: color.withAlpha((0.05 * 255).round()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16), // تصغير الحشوة
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 36 : 44, // تصغير الحجم
                    height: isMobile ? 36 : 44, // تصغير الحجم
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withAlpha(230),
                          color.withAlpha(179),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(10), // تصغير نصف القطر
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6, // تصغير التمويه
                          offset: const Offset(0, 3), // تصغير الإزاحة
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: isMobile ? 18 : 22, // تصغير حجم الأيقونة
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 12 : 16), // تصغير المسافة

                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12, // تصغير حجم الخط
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: isMobile ? 4 : 6), // تصغير المسافة

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 28, // تصغير حجم الخط
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),

                  if (subtitle != null) ...[
                    SizedBox(height: isMobile ? 6 : 8), // تصغير المسافة

                    Row(
                      children: [
                        Icon(
                          subtitle.contains('↑')
                              ? Icons.trending_up
                              : subtitle.contains('↓')
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: isMobile ? 14 : 16, // تصغير حجم الأيقونة
                          color: subtitle.contains('↑')
                              ? Colors.green
                              : subtitle.contains('↓')
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11, // تصغير حجم الخط
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reste du code inchangé...
  Widget _buildMobileContent() {
    return Column(
      children: [
        _buildPointageCard(isMobile: true),
        SizedBox(height: 6),
        _buildCalendarCard(isMobile: true),
        SizedBox(height: 6),
        controller.chartsLoading.value
            ? _buildChartLoading(isMobile: true)
            : _buildWeeklyHoursChart(controller.weeklyChartData.value,
                isMobile: true),
        SizedBox(height: 6),
        controller.chartsLoading.value
            ? _buildChartLoading(isMobile: true)
            : _buildAttendancePieChart(controller.attendanceDistribution.value,
                isMobile: true),
      ],
    );
  }

  Widget _buildDesktopContent(bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isTablet ? 3 : 2,
          child: Column(
            children: [
              _buildPointageCard(isMobile: false),
              SizedBox(height: isTablet ? 8 : 12),
              _buildCalendarCard(isMobile: false),
            ],
          ),
        ),
        SizedBox(width: isTablet ? 8 : 12),
        Expanded(
          flex: isTablet ? 5 : 3,
          child: Column(
            children: [
              controller.chartsLoading.value
                  ? _buildChartLoading(isMobile: false)
                  : _buildWeeklyHoursChart(controller.weeklyChartData.value,
                      isMobile: false),
              SizedBox(height: isTablet ? 8 : 12),
              controller.chartsLoading.value
                  ? _buildChartLoading(isMobile: false)
                  : _buildAttendancePieChart(
                      controller.attendanceDistribution.value,
                      isMobile: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(controller.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHoursChart(Map<String, dynamic> chartData,
      {required bool isMobile}) {
    final List<String> labels = List<String>.from(chartData['labels'] ?? []);
    final List<double> hours = List<double>.from(
        (chartData['datasets'][0]['data'] as List).map((e) => e.toDouble()) ??
            []);

    if (labels.isEmpty || hours.isEmpty) {
      return _buildEmptyChart('Aucune donnée disponible', isMobile: isMobile);
    }

    Widget semaineIndicator() {
    final semaine = chartData['semaine'] as Map<String, dynamic>? ?? {};
    return Text(
      'Semaine du ${semaine['debut']} au ${semaine['fin']}',
      style: TextStyle(
        fontSize: isMobile ? 10 : 12,
        color: Colors.grey.shade600,
      ),
    );
  }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        height: isMobile ? 220 : 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HEURES TRAVAILLÉES',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              'Cette semaine',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: hours.isNotEmpty
                      ? hours.reduce((a, b) => a > b ? a : b) + 2
                      : 8,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      tooltipBorder: BorderSide(color: Colors.grey.shade300),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY} h',
                          TextStyle(
                            color: controller.primaryColor,
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
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontSize: isMobile ? 8 : 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              fontSize: isMobile ? 8 : 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                        reservedSize: isMobile ? 25 : 30,
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      left: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  barGroups: hours
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: controller.primaryColor,
                                width: isMobile ? 16 : 20,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY:
                                      hours.reduce((a, b) => a > b ? a : b) + 2,
                                  color: Colors.grey.shade50,
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message, {required bool isMobile}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        height: isMobile ? 220 : 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendancePieChart(Map<String, dynamic> chartData, {required bool isMobile}) {
  final rawData = chartData['rawData'] as Map<String, dynamic>? ?? {};

  // Cas spécial où l'employé n'était pas encore en poste
  // Vérification du message spécial
if (rawData['message'] != null && rawData['message'].contains("n'était pas encore en poste")) {
  return Card(
    child: Center(
      child: Column(
        children: [
          Icon(Icons.info_outline),
          Text(rawData['message']),
          Text('Période: ${chartData['periode']['startDate']} au ${chartData['periode']['endDate']}'),
        ],
      ),
    ),
  );
}

  // Cas normal avec données
  final List<String> labels = List<String>.from(chartData['labels'] ?? []);
  final List<double> values = List<double>.from(
      (chartData['datasets'][0]['data'] as List).map((e) => e.toDouble()) ?? []);

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
    ),
    child: Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      height: isMobile ? 220 : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉPARTITION DES PRÉSENCES',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            'Statut (7 derniers jours)',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            '${rawData['joursOuvresTotal'] ?? 0} jours ouvrés cette semaine',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: isMobile ? 40 : 50,
                      sections: values
                          .asMap()
                          .entries
                          .map((e) => PieChartSectionData(
                                value: e.value,
                                color: _getPieChartColor(e.key),
                                radius: isMobile ? 20 : 26,
                                title: '${e.value.toInt()}%',
                                titleStyle: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(0, 'Présent', rawData['present'] ?? 0, isMobile),
                      _buildLegendItem(1, 'Retard', rawData['retard'] ?? 0, isMobile),
                      _buildLegendItem(2, 'Absent', rawData['absent'] ?? 0, isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLegendItem(int index, String label, dynamic value, bool isMobile) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 6.0),
    child: Row(
      children: [
        Container(
          width: isMobile ? 12 : 14,
          height: isMobile ? 12 : 14,
          decoration: BoxDecoration(
            color: _getPieChartColor(index),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value jours',
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _getPieChartColor(int index) {
  switch (index) {
    case 0:
      return Colors.green; // Présent
    case 1:
      return Colors.orange; // Retard
    case 2:
      return Colors.red; // Absent
    default:
      return Colors.grey;
  }
}

  String _getRawDataValue(Map<String, dynamic> rawData, int index) {
    switch (index) {
      case 0:
        return rawData['present']?.toString() ?? '0';
      case 1:
        return rawData['retard']?.toString() ?? '0';
      case 2:
        return rawData['absent']?.toString() ?? '0';
      default:
        return '0';
    }
  }

  Widget _buildPointageCard({required bool isMobile}) {
    return Obx(() {
      final isEntry = controller.pointageStatus['type'] == 'ENTREE';
      final buttonColor = isEntry ? Colors.green : controller.primaryColor;
      final buttonText = isEntry ? "Pointer l'arrivée" : "Pointer la sortie";

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          height: isMobile ? 120 : 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Icon(
                      isEntry ? Icons.login : Icons.logout,
                      size: isMobile ? 14 : 15,
                      color: buttonColor,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 28 : 30,
                child: ElevatedButton(
                  onPressed: controller.handlePointage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    elevation: 2,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (controller.pointageStatus['heureLocale'] != null) ...[
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  'Dernier: ${controller.pointageStatus['heureLocale']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isMobile ? 8 : 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCalendarCard({required bool isMobile}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 4 : 6),
                  decoration: BoxDecoration(
                    color: controller.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: isMobile ? 16 : 18,
                    color: controller.secondaryColor,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  'Calendrier',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Obx(() => TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: controller.selectedDate.value,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      size: isMobile ? 14 : 16,
                      color: controller.primaryColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      size: isMobile ? 14 : 16,
                      color: controller.primaryColor,
                    ),
                    headerPadding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                    headerMargin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: controller.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: controller.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    holidayTextStyle: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                    holidayDecoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(
                      color: Colors.red.shade400,
                    ),
                    defaultTextStyle: TextStyle(
                      fontSize: isMobile ? 8 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                    outsideTextStyle: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                    cellPadding: EdgeInsets.all(isMobile ? 2 : 4),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontSize: isMobile ? 8 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendStyle: TextStyle(
                      fontSize: isMobile ? 8 : 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (controller.holidays.containsKey(
                          DateTime(date.year, date.month, date.day))) {
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: isMobile ? 4 : 6,
                            height: isMobile ? 4 : 6,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  selectedDayPredicate: (day) =>
                      isSameDay(controller.selectedDate.value, day),
                  onDaySelected: controller.onDaySelected,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(bool isMobile) {
    return Obx(() => Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: controller.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      ),
                      child: Icon(
                        Icons.history,
                        size: isMobile ? 18 : 20,
                        color: controller.primaryColor,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Text(
                      'Historique des pointages',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                if (controller.historique.isEmpty)
                  _buildEmptyHistory(isMobile: isMobile)
                else
                  _buildHistoryTable(isMobile: isMobile),
              ],
            ),
          ),
        ));
  }

  Widget _buildEmptyHistory({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off,
              size: isMobile ? 40 : 48,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Aucun pointage enregistré',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable({required bool isMobile}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: isMobile ? 12 : 24,
            horizontalMargin: isMobile ? 8 : 16,
            columns: [
              DataColumn(
                label: SizedBox(
                  width: constraints.maxWidth * 0.4,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.primaryColor,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: constraints.maxWidth * 0.3,
                  child: Text(
                    'Heure',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.primaryColor,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: constraints.maxWidth * 0.3,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.primaryColor,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
            ],
            rows: controller.historique
                .map((pointage) => DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: constraints.maxWidth * 0.4,
                            child: Row(
                              children: [
                                Icon(
                                  pointage['type'] == 'ENTREE'
                                      ? Icons.login
                                      : Icons.logout,
                                  size: isMobile ? 14 : 16,
                                  color: pointage['type'] == 'ENTREE'
                                      ? Colors.green
                                      : controller.primaryColor,
                                ),
                                SizedBox(width: isMobile ? 4 : 8),
                                Text(
                                  pointage['typeLibelle'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: constraints.maxWidth * 0.3,
                            child: Text(
                              pointage['heure'] ?? '',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: constraints.maxWidth * 0.3,
                            child: Text(
                              pointage['date'] != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(DateTime.parse(pointage['date']))
                                  : '',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildChartLoading({required bool isMobile}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        height: isMobile ? 220 : 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? 20 : 24,
                height: isMobile ? 20 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(controller.primaryColor),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Chargement des données...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
