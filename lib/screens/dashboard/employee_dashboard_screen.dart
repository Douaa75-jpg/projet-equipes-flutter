import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/pointage_service.dart';
import '../../AuthProvider.dart';
import '../../services/notification_service.dart';
import '../layoutt/employee_layout.dart';
import '../../services/demande_service.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  _EmployeeDashboardScreenState createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late PointageService _pointageService;
  late DemandeService _demandeService;
  late NotificationService _notificationService;
  Map<String, dynamic> _pointageStatus = {};
  Map<String, dynamic> _heuresTravail = {};
  List<dynamic> _historique = [];
  int _soldeConges = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  

   @override
  void initState() {
    super.initState();
    _pointageService = PointageService();
    _demandeService = DemandeService(); // Initialisation du service
    _notificationService = NotificationService();
    _loadDashboardData();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _notificationService.connect(Provider.of<AuthProvider>(context, listen: false).userId!, (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employeId = authProvider.userId!;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final results = await Future.wait([
        _pointageService.calculerHeuresTravail(employeId, dateStr, dateStr),
        _pointageService.getHistorique(employeId, dateStr),
        _demandeService.getSoldeConges(employeId), // Récupération du solde de congés
      ]);

      if (!mounted) return;
      setState(() {
        _heuresTravail = results[0] as Map<String, dynamic>;
        _historique = results[1] as List<dynamic>;
        _soldeConges = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Erreur lors du chargement des données: $e', Colors.red);
    }
  }

  Future<void> _handlePointage() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await _pointageService.enregistrerPointage(authProvider.userId!);
      if (!mounted) return;
      setState(() => _pointageStatus = result);
      await _loadDashboardData();
      _showSnackBar(result['message'], Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur lors du pointage: $e', Colors.red);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadDashboardData();
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return EmployeeLayout(
      title: 'Tableau de bord',
      notificationService: _notificationService,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF8B0000),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tableau de bord, ${authProvider.prenom}!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Matricule: ${authProvider.matricule}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date and Check-in Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE d MMMM y', 'fr_FR').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today_outlined),
                                onPressed: () => _selectDate(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handlePointage,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: _pointageStatus['type'] == 'ENTREE' 
                                    ? Colors.green[600]
                                    : const Color(0xFF8B0000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _pointageStatus['type'] == 'ENTREE' 
                                    ? 'Pointer l\'arrivée' 
                                    : 'Pointer la sortie',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (_pointageStatus['heureLocale'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Dernier pointage: ${_pointageStatus['heureLocale']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Heures travaillées',
                          value: _heuresTravail['totalHeuresFormatted'] ?? '0h 0min',
                          icon: Icons.access_time_outlined,
                          color: const Color(0xFF8B0000),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Solde de congés',
                          value: '$_soldeConges jours', // Affichage du solde
                          icon: Icons.beach_access_outlined, // Icône appropriée
                          color: Colors.green[600]!, // Couleur verte
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // History Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_outlined,
                                color: const Color(0xFF8B0000),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Historique des pointages',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_historique.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Aucun pointage enregistré',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._historique.map((pointage) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: pointage['type'] == 'ENTREE'
                                            ? Colors.green.withAlpha(25)
                                            : const Color(0xFF8B0000).withAlpha(25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        pointage['type'] == 'ENTREE'
                                            ? Icons.login
                                            : Icons.logout,
                                        color: pointage['type'] == 'ENTREE'
                                            ? Colors.green[600]
                                            : const Color(0xFF8B0000),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      pointage['typeLibelle'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      pointage['heure'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: Text(
                                      DateFormat('dd/MM').format(
                                        DateTime.parse(pointage['date']),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}