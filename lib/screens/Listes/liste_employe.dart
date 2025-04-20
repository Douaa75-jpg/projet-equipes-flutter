import 'package:flutter/material.dart';
import '../../AuthProvider.dart';
import '../../services/Employe_Service.dart';
import '../../services/pointage_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ListeEmployeScreen extends StatefulWidget {
  const ListeEmployeScreen({Key? key}) : super(key: key);

  @override
  _ListeEmployeScreenState createState() => _ListeEmployeScreenState();
}

class _ListeEmployeScreenState extends State<ListeEmployeScreen> {
  final EmployeService _employeService = EmployeService();
  List<Employe> _employees = [];
  List<Employe> _filteredEmployees = [];
  String _searchQuery = '';
  String? _selectedResponsable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeService.getEmployees();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
      );
    }
  }

  void _filterEmployees() {
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final nameMatch = '${employee.prenom} ${employee.nom}'
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final responsableMatch = _selectedResponsable == null ||
            '${employee.responsable.prenom} ${employee.responsable.nom}' ==
                _selectedResponsable;
        return nameMatch && responsableMatch;
      }).toList();
    });
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Text('Nom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Prénom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Email', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Matricule', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date de naissance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Responsable', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              ..._filteredEmployees.map((employee) => pw.TableRow(
                children: [
                  pw.Text(employee.nom),
                  pw.Text(employee.prenom),
                  pw.Text(employee.email),
                  pw.Text(employee.matricule),
                  pw.Text(employee.datedenaissance),
                  pw.Text('${employee.responsable.prenom} ${employee.responsable.nom}'),
                ],
              )),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsables = _employees
        .map((e) => '${e.responsable.prenom} ${e.responsable.nom}')
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الأعوان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Exporter en PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher par nom',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterEmployees();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedResponsable,
                  hint: const Text('Filtrer par responsable'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tous les responsables'),
                    ),
                    ...responsables.map((responsable) => DropdownMenuItem(
                          value: responsable,
                          child: Text(responsable),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedResponsable = value;
                      _filterEmployees();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? const Center(child: Text('Aucun employé trouvé'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Prénom')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Matricule')),
                            DataColumn(label: Text('Date de naissance')),
                            DataColumn(label: Text('Responsable')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredEmployees.map((employee) {
                            return DataRow(cells: [
                              DataCell(Text(employee.nom)),
                              DataCell(Text(employee.prenom)),
                              DataCell(Text(employee.email)),
                              DataCell(Text(employee.matricule)),
                              DataCell(Text(employee.datedenaissance)),
                              DataCell(Text(
                                  '${employee.responsable.prenom} ${employee.responsable.nom}')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info, color: Colors.blue),
                                    onPressed: () {
                                      // Show details dialog
                                      _showEmployeeDetails(employee);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () {
                                      // Edit employee
                                      _editEmployee(employee);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // Delete employee
                                      _deleteEmployee(employee);
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEmployeeDetails(Employe employee) async {  // Add async here
  final pointageService = PointageService();
  int nombreAbsences = 0;

  try {
    nombreAbsences = await pointageService.getNombreAbsences(employee.id);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la récupération des absences: $e')),
    );
  }

  if (!mounted) return;  // Check if widget is still in the tree

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Détails de ${employee.prenom} ${employee.nom}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${employee.nom}'),
            Text('Prénom: ${employee.prenom}'),
            Text('Email: ${employee.email}'),
            Text('Matricule: ${employee.matricule}'),
            Text('Date de naissance: ${employee.datedenaissance}'),
            Text('Responsable: ${employee.responsable.prenom} ${employee.responsable.nom}'),
            Text('Nombre d\'absences: $nombreAbsences'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
         TextButton(
          onPressed: () {
            Navigator.pop(context);
            _exportEmployeeToPDF(employee, nombreAbsences);
          },
          child: const Text('Exporter en PDF'),
        ),
      ],
    ),
  );
}
Future<void> _exportEmployeeToPDF(Employe employee, int nombreAbsences) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Fiche Employé',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Nom: ${employee.nom}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Prénom: ${employee.prenom}'),
            pw.Text('Email: ${employee.email}'),
            pw.Text('Matricule: ${employee.matricule}'),
            pw.Text('Date de naissance: ${employee.datedenaissance}'),
            pw.Text('Responsable: ${employee.responsable.prenom} ${employee.responsable.nom}'),
            pw.Text('Nombre d\'absences: $nombreAbsences'),
            pw.SizedBox(height: 20),
            pw.Text('Date de génération: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10)),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

  void _addEmployee() {
    // Implement add employee functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un employé'),
        content: const Text('Formulaire d\'ajout d\'employé à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Save new employee
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editEmployee(Employe employee) {
    // Implement edit employee functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${employee.prenom} ${employee.nom}'),
        content: const Text('Formulaire de modification d\'employé à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Save changes
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(Employe employee) {
    // Implement delete employee functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${employee.prenom} ${employee.nom}?'),
        content: const Text('Cette action est irréversible. Voulez-vous continuer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Delete employee
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${employee.prenom} ${employee.nom} supprimé')),
              );
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}