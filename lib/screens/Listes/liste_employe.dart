import 'package:flutter/material.dart';
import '../../services/Employe_Service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../layoutt/rh_layout.dart';
import '../../services/notification_service.dart';

class ListeEmployeScreen extends StatefulWidget {
  const ListeEmployeScreen({super.key});

  @override
  State<ListeEmployeScreen> createState() => _ListeEmployeScreenState();
}

class _ListeEmployeScreenState extends State<ListeEmployeScreen> {
  final EmployeService _employeService = EmployeService();
  final PointageService _pointageService = PointageService();
  final DemandeService _demandeService = DemandeService();
  final NotificationService _notificationService = NotificationService();

  List<Employe> _employees = [];
  List<Employe> _filteredEmployees = [];
  List<Employe> _chefsEquipe = [];
  Map<String, String?> _selectedChefs = {};
  String _searchQuery = '';
  String? _selectedResponsable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedChefs = {};
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadEmployees(),
        _loadChefsEquipe(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    final employees = await _employeService.getEmployees();
    if (mounted) {
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _selectedChefs = {
          for (var emp in employees) 
            emp.id: emp.responsable?.id
        };
      });
    }
  }

Future<void> _loadChefsEquipe() async {
  try {
    final chefs = await _employeService.getChefsEquipe();
    if (mounted) {
      setState(() => _chefsEquipe = chefs);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des chefs d\'équipe: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    }
    setState(() => _chefsEquipe = []);
  }
}

  Future<void> _assignChefEquipe(String employeId, String? chefId) async {
    try {
      await _employeService.assignerResponsable(employeId, chefId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chef d\'équipe assigné avec succès')),
        );
        await _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _filterEmployees() {
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final nameMatch = '${employee.prenom} ${employee.nom}'
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        
        final responsableName = employee.responsable != null 
          ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
          : 'Aucun responsable';
          
        final responsableMatch = _selectedResponsable == null ||
            responsableName == _selectedResponsable;
            
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

  @override
  Widget build(BuildContext context) {
    final responsables = _employees
        .map((e) => e.responsable != null 
            ? '${e.responsable!.prenom} ${e.responsable!.nom}' 
            : 'Aucun responsable')
        .toSet()
        .toList();

    return RhLayout(
      title: 'Liste des employés',
      notificationService: _notificationService,
      child: Column(
        children: [
          _buildSearchBar(responsables),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : _buildEmployeeTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List<String> responsables) {
    return Padding(
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
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterEmployees();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildResponsableFilter(responsables),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onPressed: _exportToPDF,
                tooltip: 'Exporter en PDF',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsableFilter(List<String> responsables) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red),
      ),
      child: DropdownButton<String>(
        value: _selectedResponsable,
        hint: const Text('Filtrer par responsable'),
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list, color: Colors.red),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  Widget _buildEmployeeTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Prénom')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Matricule')),
            DataColumn(label: Text('Responsable')),
            DataColumn(label: Text('Solde congés')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _filteredEmployees.map((employee) {
            return DataRow(
              cells: [
                DataCell(Text(employee.nom)),
                DataCell(Text(employee.prenom)),
                DataCell(Text(employee.email)),
                DataCell(Text(employee.matricule)),
                DataCell(
                  Text(
                    employee.responsable != null
                      ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                      : 'Aucun responsable',
                  ),
                ),
                DataCell(_buildSoldeConges(employee)),
                DataCell(_buildActionButtons(employee)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResponsableDropdown(Employe employee) {
    return DropdownButton<String>(
      value: _selectedChefs[employee.id],
      hint: const Text('Sélectionner'),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Aucun responsable'),
        ),
        ..._chefsEquipe.map((chef) => DropdownMenuItem(
              value: chef.id,
              child: Text('${chef.prenom} ${chef.nom}'),
            ))
      ],
      onChanged: (newValue) async {
        setState(() => _selectedChefs[employee.id] = newValue);
        await _assignChefEquipe(employee.id, newValue);
      },
    );
  }

  Widget _buildSoldeConges(Employe employee) {
    return FutureBuilder<int>(
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
    );
  }

  Widget _buildActionButtons(Employe employee) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          color: Colors.blue,
          onPressed: () => _showEmployeeDetails(employee),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          color: Colors.orange,
          onPressed: () => _editEmployee(employee),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
          onPressed: () => _deleteEmployee(employee),
        ),
      ],
    );
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
                      pw.Text(
                        employee.responsable != null
                          ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                          : 'Aucun responsable'
                      ),
                      pw.Text('${_demandeService.getSoldeConges(employee.id)} jours'),
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

  void _showEmployeeDetails(Employe employee) async {
    try {
      final [absences, solde] = await Future.wait([
        _pointageService.getNombreAbsences(employee.id),
        _demandeService.getSoldeConges(employee.id),
      ]);

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
                _buildDetailRow('Date naissance', _formatDate(employee.datedenaissance)),
                _buildDetailRow(
                  'Responsable', 
                  employee.responsable != null
                    ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                    : 'Aucun responsable'
                ),
                _buildDetailRow('Absences', absences.toString()),
                _buildDetailRow(
                  'Solde congés', 
                  '$solde jours',
                  isImportant: true,
                  color: solde > 5 ? Colors.green : Colors.orange,
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
              onPressed: () => _exportEmployeeToPDF(employee, absences, solde),
              child: const Text('Exporter PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isImportant = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isImportant ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEmployeeToPDF(Employe employee, int absences, int solde) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
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
              _buildPdfDetailRow(
                'Responsable', 
                employee.responsable != null
                  ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                  : 'Aucun responsable'
              ),
              _buildPdfDetailRow('Absences', absences.toString()),
              _buildPdfDetailRow('Solde congés', '$solde jours'),
              pw.SizedBox(height: 20),
              pw.Text('Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:'),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  void _editEmployee(Employe employee) {
  final nomController = TextEditingController(text: employee.nom);
  final prenomController = TextEditingController(text: employee.prenom);
  final emailController = TextEditingController(text: employee.email);
  final matriculeController = TextEditingController(text: employee.matricule);
  DateTime initialDate = employee.datedenaissance.isNotEmpty
      ? DateTime.parse(employee.datedenaissance)
      : DateTime.now();
  String? selectedChefId = employee.responsable?.id;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        DateTime? selectedDate = initialDate;
        
        return AlertDialog(
          title: Text('Modifier ${employee.prenom} ${employee.nom}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: matriculeController,
                  decoration: const InputDecoration(labelText: 'Matricule'),
                ),
                ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Responsable (Chef d\'équipe):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedChefId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Aucun responsable'),
                    ),
                    ..._chefsEquipe.map((chef) => DropdownMenuItem(
                      value: chef.id,
                      child: Text('${chef.prenom} ${chef.nom}'),
                    )).toList(),
                  ],
                  onChanged: (newValue) {
                    setState(() => selectedChefId = newValue);
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
                  // Mettre à jour les informations de base
                  await _employeService.updateEmployee(employee.id, {
                    'nom': nomController.text,
                    'prenom': prenomController.text,
                    'email': emailController.text,
                    'matricule': matriculeController.text,
                    'datedenaissance': selectedDate?.toIso8601String(),
                  });
                  
                  // Mettre à jour le responsable si nécessaire
                  if (selectedChefId != employee.responsable?.id) {
                    await _employeService.assignerResponsable(
                      employee.id, 
                      selectedChefId
                    );
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employé mis à jour'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadEmployees();
                  Navigator.pop(context);
                } catch (e) {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${employee.prenom} ${employee.nom}?'),
        content: const Text('Cette action est irréversible. Confirmer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _employeService.deleteEmployee(employee.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Employé supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadEmployees();
              } catch (e) {
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