import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gestion_equipe_flutter/auth_controller.dart';
import 'package:gestion_equipe_flutter/services/chef_equipe_service.dart';
import 'package:gestion_equipe_flutter/screens/layoutt/chef_layout.dart';
import '../../screens/employe_pointage_history_screen.dart';

class ChefEquipeDashboardScreen extends StatefulWidget {
  const ChefEquipeDashboardScreen({super.key});

  @override
  State<ChefEquipeDashboardScreen> createState() =>
      _ChefEquipeDashboardScreenState();
}

class _ChefEquipeDashboardScreenState extends State<ChefEquipeDashboardScreen> {
  final AuthProvider authController = Get.find<AuthProvider>();
  final ChefEquipeService chefEquipeService = ChefEquipeService();

  List<dynamic> employes = [];
  Map<String, dynamic> presenceStats = {};
  bool isLoadingPresence = true;
  int nombreEmployes = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPresenceStats();
  }

  Future<void> _loadPresenceStats() async {
    try {
      final chefId = authController.userId.value;
      final stats = await chefEquipeService.getPresencesSousChefAujourdhui(chefId);
      setState(() {
        presenceStats = stats;
        isLoadingPresence = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des stats de présence: $e';
        isLoadingPresence = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final chefId = authController.userId.value;

      final results = await Future.wait([
        chefEquipeService.getHeuresEquipe(chefId),
        chefEquipeService.getNombreEmployesSousResponsable(chefId),
      ]);

      setState(() {
        employes = results[0] as List<dynamic>;
        nombreEmployes = results[1] as int;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des données: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChefLayout(
      title: 'Tableau de bord',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(),
                    const SizedBox(height: 20),
                    _buildEmployesTableSection(),
                  ],
                ),
              );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Statistiques de l\'équipe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              icon: Icons.group,
              title: 'Employés sous responsabilité',
              value: nombreEmployes.toString(),
              color: const Color(0xFF8B0000),
            ),
            if (!isLoadingPresence)
              _buildStatCard(
                icon: Icons.check_circle,
                title: 'Présents aujourd\'hui',
                value: '${presenceStats['count']}/${presenceStats['total']}',
                subtitle: '${presenceStats['percentage']}%',
                color: Colors.green,
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color ?? Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color ?? Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployesTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Liste des employés',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 56,
                  headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) => const Color(0xFF8B0000).withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Matricule', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Prénom', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Absences', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Congés', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Heures supp.', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: employes.map((employe) {
                    return DataRow(
                      cells: [
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.history, color: Color(0xFF8B0000)),
                            onPressed: () {
                              final employeId = employe['id']?.toString() ?? employe['utilisateur']['id']?.toString();
                              if (employeId == null) return;
                              Get.to(
                                () => EmployePointageHistoryScreen(
                                  employeId: employeId,
                                  chefId: authController.userId.value,
                                ),
                              );
                            },
                          ),
                        ),
                        DataCell(Text(employe['utilisateur']['matricule'] ?? 'N/A')),
                        DataCell(Text(employe['utilisateur']['nom'] ?? 'N/A')),
                        DataCell(Text(employe['utilisateur']['prenom'] ?? 'N/A')),
                        DataCell(
                          _buildStatCell(
                            employe['nbAbsences']?.toString() ?? '0',
                            (employe['nbAbsences'] ?? 0) > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                        DataCell(
                          _buildStatCell(
                            employe['soldeConges']?.toString() ?? '0',
                            Colors.blue,
                          ),
                        ),
                        DataCell(
                          _buildStatCell(
                            employe['heuresSupp']?.toStringAsFixed(1) ?? '0.0',
                            (employe['heuresSupp'] ?? 0) > 0 ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCell(String value, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}