import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../auth_controller.dart';
import '../../services/chef_equipe_service.dart';
import '../../services/demande_service.dart';
import '../../screens/employe_pointage_history_screen.dart';
import '../../screens/layoutt/chef_layout.dart';

class ChefEquipeDashboard extends StatefulWidget {
  const ChefEquipeDashboard({Key? key}) : super(key: key);

  @override
  _ChefEquipeDashboardScreenState createState() => _ChefEquipeDashboardScreenState();
}

class _ChefEquipeDashboardScreenState extends State<ChefEquipeDashboard> {
  final ChefEquipeService _chefEquipeService = ChefEquipeService();
  final DemandeService _demandeService = DemandeService();
  List<dynamic> _employes = [];
  List<dynamic> _congesEnCours = [];
  List<dynamic> _congesAVenir = [];
  int _nombreEmployes = 0;
  bool _isLoading = true;
  bool _isLoadingConges = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployes();
    _loadConges();
  }

  Future<void> _loadEmployes() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employes = await _chefEquipeService.getHeuresTravailTousLesEmployes(authProvider.userId.value);
      final nombre = await _chefEquipeService.getNombreEmployesSousResponsable(authProvider.userId.value);
      
      setState(() {
        _employes = employes['employes'];
        _nombreEmployes = nombre;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des employés: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConges() async {
    try {
      setState(() => _isLoadingConges = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final congesEnCours = await _demandeService.getTeamLeaveRequests(authProvider.userId.value);
      final congesAVenir = await _demandeService.getUpcomingTeamLeaveRequests(authProvider.userId.value);
      
      setState(() {
        _congesEnCours = congesEnCours;
        _congesAVenir = congesAVenir;
        _isLoadingConges = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingConges = false;
        _errorMessage = 'Erreur lors du chargement des congés: ${e.toString()}';
      });
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    final List<Map<String, dynamic>> employesWithSolde = [];
    for (var employe in _employes) {
      final solde = await _demandeService.getSoldeConges(employe['employe']['id']);
      employesWithSolde.add({
        'employe': employe['employe'],
        'solde': solde,
      });
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(child: pw.Text('Nom'), padding: pw.EdgeInsets.all(4)),
                  pw.Padding(child: pw.Text('Prénom'), padding: pw.EdgeInsets.all(4)),
                  pw.Padding(child: pw.Text('Matricule'), padding: pw.EdgeInsets.all(4)),
                  pw.Padding(child: pw.Text('Email'), padding: pw.EdgeInsets.all(4)),
                  pw.Padding(child: pw.Text('Date naissance'), padding: pw.EdgeInsets.all(4)),
                  pw.Padding(child: pw.Text('Solde Congé'), padding: pw.EdgeInsets.all(4)),
                ],
              ),
              ...employesWithSolde.map((employe) {
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(employe['employe']['nom'] ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(employe['employe']['prenom'] ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(employe['employe']['matricule'] ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(employe['employe']['email'] ?? '')),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(employe['employe']['datedenaissance'] != null 
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(employe['employe']['datedenaissance'])) 
                        : ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('${employe['solde']} jours'),
                    ),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exporté avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export PDF: ${e.toString()}')),
      );
    }
  }

  void _showPointageHistory(String employeId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployePointageHistoryScreen(
          employeId: employeId,
          chefId: authProvider.userId.value,
        ),
      ),
    );
  }

  void _showLeaveDetails(dynamic demande) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du congé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employé: ${demande['employe']['utilisateur']['nom']} ${demande['employe']['utilisateur']['prenom']}'),
            SizedBox(height: 8),
            Text('Type: ${demande['type']}'),
            SizedBox(height: 8),
            Text('Du: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande['dateDebut']))}'),
            if (demande['dateFin'] != null)
              Text('Au: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande['dateFin']))}'),
            SizedBox(height: 8),
            Text('Statut: ${demande['statut']}'),
            if (demande['raison'] != null && demande['raison'].isNotEmpty)
              Column(
                children: [
                  SizedBox(height: 8),
                  Text('Raison: ${demande['raison']}'),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmployesTab() {
    final filteredEmployes = _employes.where((employe) {
      final searchTerm = _searchController.text.toLowerCase();
      return employe['employe']['nom'].toLowerCase().contains(searchTerm) ||
          employe['employe']['prenom'].toLowerCase().contains(searchTerm) ||
          employe['employe']['matricule'].toLowerCase().contains(searchTerm) ||
          employe['employe']['email'].toLowerCase().contains(searchTerm);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher un employé',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.picture_as_pdf),
                onPressed: _exportToPdf,
                tooltip: 'Exporter en PDF',
                color: Colors.red,
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _loadEmployes();
                  _loadConges();
                },
                tooltip: 'Actualiser',
                color: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Prénom')),
                          DataColumn(label: Text('Matricule')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Solde Congé')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filteredEmployes.map((employe) {
                          return DataRow(
                            cells: [
                              DataCell(Text(employe['employe']['nom'] ?? '')),
                              DataCell(Text(employe['employe']['prenom'] ?? '')),
                              DataCell(Text(employe['employe']['matricule'] ?? '')),
                              DataCell(Text(employe['employe']['email'] ?? '')),
                              DataCell(FutureBuilder<int>(
                                future: _demandeService.getSoldeConges(employe['employe']['id']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }
                                  return Text('${snapshot.data ?? 0} jours');
                                },
                              )),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.visibility, color: Colors.green),
                                      onPressed: () => _showPointageHistory(employe['employe']['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildCongesTab(List<dynamic> conges, String emptyMessage) {
    if (_isLoadingConges) {
      return Center(child: CircularProgressIndicator());
    }

    if (conges.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: conges.length,
      itemBuilder: (context, index) {
        final demande = conges[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(Icons.beach_access, color: Colors.blue),
            title: Text('${demande['employe']['utilisateur']['nom']} ${demande['employe']['utilisateur']['prenom']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${demande['type']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande['dateDebut']))}'),
                if (demande['dateFin'] != null)
                  Text('jusqu\'au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande['dateFin']))}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showLeaveDetails(demande),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChefLayout(
      title: 'Tableau de bord',
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Employés', '$_nombreEmployes', Icons.people),
                    _buildStatCard('Congés en cours', '${_congesEnCours.length}', Icons.beach_access),
                    _buildStatCard('Congés à venir', '${_congesAVenir.length}', Icons.calendar_today),
                  ],
                ),
              ),
            ),
            TabBar(
              tabs: [
                Tab(icon: Icon(Icons.people), text: 'Employés'),
                Tab(icon: Icon(Icons.beach_access), text: 'Congés en cours'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Congés à venir'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEmployesTab(),
                  _buildCongesTab(_congesEnCours, 'Aucun congé en cours'),
                  _buildCongesTab(_congesAVenir, 'Aucun congé à venir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}