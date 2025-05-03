import 'package:flutter/material.dart';
import '../../AuthProvider.dart';
import '../../services/Employe_Service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart'; // Ajout du service des demandes
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../layoutt/rh_layout.dart';
import '../../services/notification_service.dart';

class ListeEmployeScreen extends StatefulWidget {
  const ListeEmployeScreen({Key? key}) : super(key: key);

  @override
  _ListeEmployeScreenState createState() => _ListeEmployeScreenState();
}

class _ListeEmployeScreenState extends State<ListeEmployeScreen> {
  final EmployeService _employeService = EmployeService();
  final PointageService _pointageService = PointageService();
  final DemandeService _demandeService = DemandeService(); // Service des demandes
  List<Employe> _employees = [];
  List<Employe> _filteredEmployees = [];
  String _searchQuery = '';
  String? _selectedResponsable;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();

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

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'Non spécifié';
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
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
                  pw.Text('Solde congés', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              ..._filteredEmployees.map((employee) => pw.TableRow(
                    children: [
                      pw.Text(employee.nom),
                      pw.Text(employee.prenom),
                      pw.Text(employee.email),
                      pw.Text(employee.matricule),
                      pw.Text(_formatDate(employee.datedenaissance)),
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

    return RhLayout(
      title: 'Liste des employés',
      notificationService: _notificationService,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Rechercher par nom',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 181, 63, 63))),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 159, 48, 48)!),
                          ),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterEmployees();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color.fromARGB(255, 181, 63, 63)),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedResponsable,
                        hint: const Text('Filtrer par responsable'),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.filter_list, color: Color.fromARGB(255, 181, 63, 63)),
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Color.fromARGB(255, 210, 25, 25)),
                      onPressed: _exportToPDF,
                      tooltip: 'Exporter en PDF',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 181, 63, 63)))
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Aucun employé trouvé',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: DataTable(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              columns: const [
                                DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Prénom', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Matricule', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Solde congés', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredEmployees.map((employee) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(employee.nom)),
                                    DataCell(Text(employee.prenom)),
                                    DataCell(Text(employee.email)),
                                    DataCell(Text(employee.matricule)),
                                    DataCell(
                                      FutureBuilder<int>(
                                        future: _demandeService.getSoldeConges(employee.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }
                                          final solde = snapshot.data ?? 0;
                                          return Text(
                                            '$solde jours',
                                            style: TextStyle(
                                              color: solde > 5 ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          color: Colors.blue[700],
                                          onPressed: () {
                                            _showEmployeeDetails(employee);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.orange[700],
                                          onPressed: () {
                                            _editEmployee(employee);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          color: Colors.red[700],
                                          onPressed: () {
                                            _deleteEmployee(employee);
                                          },
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Employe employee) async {
    int nombreAbsences = 0;
    int soldeConges = 0;

    try {
      final results = await Future.wait([
        _pointageService.getNombreAbsences(employee.id),
        _demandeService.getSoldeConges(employee.id),
      ]);
      
      nombreAbsences = results[0] as int;
      soldeConges = results[1] as int;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des données: $e')),
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de ${employee.prenom} ${employee.nom}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nom', employee.nom),
              _buildDetailRow('Prénom', employee.prenom),
              _buildDetailRow('Email', employee.email),
              _buildDetailRow('Matricule', employee.matricule),
              _buildDetailRow('Date de naissance', _formatDate(employee.datedenaissance)),
              _buildDetailRow('Responsable', '${employee.responsable.prenom} ${employee.responsable.nom}'),
              _buildDetailRow('Nombre d\'absences', nombreAbsences.toString()),
              _buildDetailRow(
                'Solde de congés restant', 
                '$soldeConges jours',
                isImportant: true,
                color: soldeConges > 5 ? Colors.green : Colors.orange,
              ),
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
              _exportEmployeeToPDF(employee, nombreAbsences, soldeConges);
            },
            child: const Text('Exporter en PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isImportant = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
                fontSize: isImportant ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEmployeeToPDF(Employe employee, int nombreAbsences, int soldeConges) async {
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
              _buildPdfDetailRow('Nom', employee.nom),
              _buildPdfDetailRow('Prénom', employee.prenom),
              _buildPdfDetailRow('Email', employee.email),
              _buildPdfDetailRow('Matricule', employee.matricule),
              _buildPdfDetailRow('Date de naissance', _formatDate(employee.datedenaissance)),
              _buildPdfDetailRow('Responsable', '${employee.responsable.prenom} ${employee.responsable.nom}'),
              _buildPdfDetailRow('Nombre d\'absences', nombreAbsences.toString()),
              _buildPdfDetailRow('Solde de congés restant', '$soldeConges jours',
                isImportant: true),
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

  pw.Widget _buildPdfDetailRow(String label, String value, {bool isImportant = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontWeight: isImportant ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isImportant ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _addEmployee() {
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
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editEmployee(Employe employee) {
    final nomController = TextEditingController(text: employee.nom);
    final prenomController = TextEditingController(text: employee.prenom);
    final emailController = TextEditingController(text: employee.email);
    final matriculeController = TextEditingController(text: employee.matricule);
    DateTime? selectedDate = employee.datedenaissance.isNotEmpty 
        ? DateTime.parse(employee.datedenaissance) 
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Modifier ${employee.prenom} ${employee.nom}'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nomController, decoration: InputDecoration(labelText: 'Nom')),
                  TextField(controller: prenomController, decoration: InputDecoration(labelText: 'Prénom')),
                  TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                  TextField(controller: matriculeController, decoration: InputDecoration(labelText: 'Matricule')),
                  ListTile(
                    title: Text(selectedDate == null 
                        ? 'Sélectionner une date' 
                        : 'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final updatedData = {
                      'nom': nomController.text,
                      'prenom': prenomController.text,
                      'email': emailController.text,
                      'matricule': matriculeController.text,
                      'dateDeNaissance': selectedDate?.toIso8601String(),
                    };

                    await _employeService.updateEmployee(employee.id, updatedData);
                    if (!mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${prenomController.text} ${nomController.text} mis à jour'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadEmployees();
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteEmployee(Employe employee) {
    print('Tentative de suppression de l\'employé ID: ${employee.id}');
    
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
            onPressed: () async {
              try {
                print('Envoi de la suppression pour ID: ${employee.id}');
                final success = await _employeService.deleteEmployee(employee.id);
                if (success) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${employee.prenom} ${employee.nom} supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadEmployees();
                }
              } catch (e) {
                print('Erreur de suppression: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}