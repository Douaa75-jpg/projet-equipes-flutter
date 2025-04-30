import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../AuthProvider.dart';
import '../../services/chef_equipe_service.dart';
import '../../screens/employe_pointage_history_screen.dart';


class ChefEquipeDashboard extends StatefulWidget {
  const ChefEquipeDashboard({Key? key}) : super(key: key);

  @override
  _ChefEquipeDashboardScreenState createState() => _ChefEquipeDashboardScreenState();
}

class _ChefEquipeDashboardScreenState extends State<ChefEquipeDashboard> {
  final ChefEquipeService _chefEquipeService = ChefEquipeService();
  List<dynamic> _employes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployes();
  }

  Future<void> _loadEmployes() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employes = await _chefEquipeService.getHeuresTravailTousLesEmployes(authProvider.userId!);
      setState(() {
        _employes = employes['employes'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des employés: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmploye(String employeId) async {
    try {
      // Ici vous devriez implémenter la logique de suppression avec votre API
      // await _chefEquipeService.deleteEmploye(employeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression implémenter avec votre API')),
      );
      _loadEmployes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
      );
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

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
                pw.Padding(child: pw.Text('Date de naissance'), padding: pw.EdgeInsets.all(4)),
              ],
            ),
              ..._employes.map((employe) {
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
                      : '',
                    ),
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
    // Option 1: Directly print/share the PDF without saving
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    
    // Option 2: Save to file (requires proper path_provider setup)
    /*
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/liste_employes_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
    */
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exporté avec succès')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de l\'export PDF: ${e.toString()}')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    final filteredEmployes = _employes.where((employe) {
      final searchTerm = _searchController.text.toLowerCase();
      return employe['employe']['nom'].toLowerCase().contains(searchTerm) ||
          employe['employe']['prenom'].toLowerCase().contains(searchTerm) ||
          employe['employe']['matricule'].toLowerCase().contains(searchTerm) ||
          employe['employe']['email'].toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord - Chef d\'équipe'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEmployes,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Rechercher',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                     Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Prénom')),
                            DataColumn(label: Text('Matricule')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Date naissance')),
                            DataColumn(label: Text('Actions')),
                            DataColumn(label: Text('Détails')),
                          ],
                          rows: filteredEmployes.map((employe) {
                            return DataRow(
                              cells: [
                                DataCell(Text(employe['employe']['nom'] ?? '')),
                                DataCell(Text(employe['employe']['prenom'] ?? '')),
                                DataCell(Text(employe['employe']['matricule'] ?? '')),
                                DataCell(Text(employe['employe']['email'] ?? '')),
                                DataCell(Text(
                                  employe['employe']['datedenaissance'] != null
                                      ? DateFormat('dd/MM/yyyy').format(
                                          DateTime.parse(employe['employe']['datedenaissance']))
                                      : '',
                                )),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showEditDialog(employe);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _showDeleteDialog(employe['employe']['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: Icon(Icons.visibility, color: Colors.green),
                                    onPressed: () {
                                      _showPointageHistory(employe['employe']['id']);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showPointageHistory(String employeId) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EmployePointageHistoryScreen(
        employeId: employeId,
        chefId: authProvider.userId!, // Ajoutez cette ligne
      ),
    ),
  );
}       

  void _showEditDialog(dynamic employe) {
    final nomController = TextEditingController(text: employe['employe']['nom']);
    final prenomController = TextEditingController(text: employe['employe']['prenom']);
    final emailController = TextEditingController(text: employe['employe']['email']);
    final matriculeController = TextEditingController(text: employe['employe']['matricule']);
    final dateNaissanceController = TextEditingController(
      text: employe['employe']['datedenaissance'] != null
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(employe['employe']['datedenaissance']))
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier employé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: prenomController,
                  decoration: InputDecoration(labelText: 'Prénom'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: matriculeController,
                  decoration: InputDecoration(labelText: 'Matricule'),
                ),
                TextField(
                  controller: dateNaissanceController,
                  decoration: InputDecoration(labelText: 'Date de naissance (jj/mm/aaaa)'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      dateNaissanceController.text = DateFormat('dd/MM/yyyy').format(date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Ici vous devriez implémenter la logique de modification avec votre API
                  // await _chefEquipeService.updateEmploye(...);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Modification implémenter avec votre API')),
                  );
                  Navigator.pop(context);
                  _loadEmployes();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la modification: ${e.toString()}')),
                  );
                }
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String employeId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cet employé ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteEmploye(employeId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
} 