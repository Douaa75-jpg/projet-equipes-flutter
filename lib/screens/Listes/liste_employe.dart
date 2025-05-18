import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../services/Employe_Service.dart';
import '../../services/pointage_service.dart';
import '../../services/demande_service.dart';
import '../layoutt/rh_layout.dart';
import '../../services/notification_service.dart';
import 'HeuresTravailScreen.dart';

class ListeEmployeController extends GetxController {
  final EmployeService _employeService = Get.put(EmployeService());
  final PointageService _pointageService = PointageService();
  final DemandeService _demandeService = DemandeService();

  var employees = <Employe>[].obs;
  var filteredEmployees = <Employe>[].obs;
  var chefsEquipe = <Employe>[].obs;
  var selectedChefs = <String, String?>{}.obs;
  var searchQuery = ''.obs;
  var selectedResponsable = Rxn<String>();
  var isLoading = true.obs;
  var absencesCount = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadAbsencesCount() async {
  try {
    for (var employee in employees) {
      final count = await _employeService.getNombreAbsences(employee.id);
      absencesCount[employee.id] = count;
    }
  } catch (e) {
    Get.snackbar('Erreur', 'Erreur de chargement des absences: ${e.toString()}');
  }
}

  Future<void> loadData() async {
    try {
      isLoading(true);
      await Future.wait([loadEmployees(), loadChefsEquipe()]);
      await loadAbsencesCount();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur de chargement: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadEmployees() async {
    await _employeService.fetchEmployees();
    employees.assignAll(_employeService.employees);
    filterEmployees();
    
    selectedChefs.clear();
    for (var emp in employees) {
      selectedChefs[emp.id] = emp.responsable?.id;
    }
  }

  Future<void> loadChefsEquipe() async {
    try {
      await _employeService.fetchChefsEquipe();
      chefsEquipe.assignAll(_employeService.chefsEquipe);
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur de chargement des chefs d\'équipe: ${e.toString()}',
          duration: const Duration(seconds: 5));
      chefsEquipe.clear();
    }
  }

  Future<void> assignChefEquipe(String employeId, String? chefId) async {
    try {
      await _employeService.assignerResponsable(employeId, chefId);
      Get.snackbar('Succès', 'Chef d\'équipe assigné avec succès');
      await loadEmployees();
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }

  void filterEmployees() {
    filteredEmployees.assignAll(employees.where((employee) {
      final nameMatch = '${employee.prenom} ${employee.nom}'
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase());
      
      final responsableName = employee.responsable != null 
        ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
        : 'Aucun responsable';
        
      final responsableMatch = selectedResponsable.value == null ||
          responsableName == selectedResponsable.value;
          
      return nameMatch && responsableMatch;
    }).toList());
  }

String formatDate(String dateString) {
  try {
    if (dateString.isEmpty || dateString.toLowerCase() == "null") return 'Non spécifié';
    
    // Essayez différents formats de date
    DateTime? date;
    
    // Format ISO 8601 (2023-12-31T00:00:00.000Z)
    date = DateTime.tryParse(dateString);
    if (date != null) return DateFormat('dd/MM/yyyy').format(date);
    
    // Format simple (2023-12-31)
    final parts = dateString.split('-');
    if (parts.length == 3) {
      date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return DateFormat('dd/MM/yyyy').format(date);
    }
    
    return 'Non spécifié';
  } catch (e) {
    debugPrint('Erreur de format de date: $e');
    return 'Non spécifié';
  }
}

  Future<void> exportToPDF() async {
    final soldesConges = <String, int>{};
    for (var employee in filteredEmployees) { 
      soldesConges[employee.id] = await _demandeService.getSoldeConges(employee.id);
    }
    final pdf = pw.Document();

    // Ajout de l'en-tête avec logo et informations
    final imageProvider = await networkImage('assets/logo.png'); // Remplacez par votre logo

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // En-tête avec logo et informations de l'entreprise
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(imageProvider, width: 100, height: 100),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ZETA-BOX',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('B-51, Emna City, Av. Hedi Nouira, Sfax 3027',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Tél: 29 009 390',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Email: contact-tn@zeta-Box.com',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 0,
                child: pw.Text('Liste des Employés',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
              border: pw.TableBorder.all(width: 1),
              columnWidths: {
                0: pw.FlexColumnWidth(1.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(3),
                5: pw.FlexColumnWidth(2),
                6: pw.FlexColumnWidth(2),
                7: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    for (var header in [
                      'Nom',
                      'Prénom',
                      'Email',
                      'Matricule',
                      'Responsable',
                      'Heures Supp',
                      'Solde congés',
                      'Absences'
                    ])
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          header,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                ...filteredEmployees.map(
                  (employee) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(employee.nom, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(employee.prenom, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(employee.email, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(employee.matricule, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          employee.responsable != null
                              ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                              : 'Aucun responsable',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                       pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '${soldesConges[employee.id] ?? 0} jours',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '${absencesCount[employee.id] ?? 0} jours',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

              pw.SizedBox(height: 30),
              // Signature et date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Fait à: sfax',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                      pw.Text(
                          'Le: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.Text('Signature et cachet',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> exportEmployeeToPDF(Employe employee, int solde) async {
    final pdf = pw.Document();
    final imageProvider = await networkImage('assets/logo.png'); // Remplacez par votre logo

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // En-tête avec logo et informations de l'entreprise
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(imageProvider, width: 100, height: 100),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ZETA-BOX',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('B-51, Emna City, Av. Hedi Nouira, Sfax 3027',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Tél: 29 009 390',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Email: contact-tn@zeta-Box.com',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 0,
                child: pw.Text('Fiche Employé', 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${employee.prenom} ${employee.nom}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              buildPdfDetailRow('Nom', employee.nom),
              buildPdfDetailRow('Prénom', employee.prenom),
              buildPdfDetailRow('Email', employee.email),
              buildPdfDetailRow('Matricule', employee.matricule),
              buildPdfDetailRow('Date de naissance', formatDate(employee.datedenaissance)),
              buildPdfDetailRow(
                'Responsable', 
                employee.responsable != null
                  ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                  : 'Aucun responsable'
              ),
               buildPdfDetailRow('Heures supplémentaires', '${employee.heuresSupp} heures'),
              buildPdfDetailRow('Solde congés', '$solde jours'),
              buildPdfDetailRow('Nombre d\'absences', '${absencesCount[employee.id] ?? 0} jours'),
              pw.SizedBox(height: 30),
              // Signature et date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Fait à: sfax',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                      pw.Text(
                          'Le: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.Text('Signature et cachet',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }
}

class ListeEmployeScreen extends StatelessWidget {
  ListeEmployeScreen({super.key});

  final ListeEmployeController controller = Get.put(ListeEmployeController());

  @override
  Widget build(BuildContext context) {
    return RhLayout(
      title: 'Liste des employés',
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : _buildEmployeeTable()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
                    controller.searchQuery.value = value;
                    controller.filterEmployees();
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildResponsableFilter(),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onPressed: controller.exportToPDF,
                tooltip: 'Exporter en PDF',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsableFilter() {
    return Obx(() {
      final responsables = controller.employees
          .map((e) => e.responsable != null 
              ? '${e.responsable!.prenom} ${e.responsable!.nom}' 
              : 'Aucun responsable')
          .toSet()
          .toList();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: DropdownButton<String>(
          value: controller.selectedResponsable.value,
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
            controller.selectedResponsable.value = value;
            controller.filterEmployees();
          },
        ),
      );
    });
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
    return Obx(() => Card(
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
            DataColumn(label: Text('Heures Supp')),
            DataColumn(label: Text('Solde congés')),
            DataColumn(label: Text('Absences')),
            DataColumn(label: Text('Actions')),
          ],
          rows: controller.filteredEmployees.map((employee) {
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

                DataCell(_buildHeuresSupp(employee)),
                DataCell(_buildSoldeConges(employee)),
                DataCell(_buildAbsencesCount(employee)),
                DataCell(_buildActionButtons(employee)),
              ],
            );
          }).toList(),
        ),
      ),
    ));
  }

Widget _buildHeuresSupp(Employe employee) {
  return Text(
    '${employee.heuresSupp} h',
    style: TextStyle(
      color: employee.heuresSupp > 0 ? Colors.green : Colors.grey,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _buildAbsencesCount(Employe employee) {
  return Obx(() {
    final count = controller.absencesCount[employee.id] ?? 0;
    return Text(
      '$count jours',
      style: TextStyle(
        color: count > 3 ? Colors.red : Colors.grey, // تغيير اللون إذا زادت الغيابات عن 3 أيام
        fontWeight: FontWeight.bold,
      ),
    );
  });
}
  Widget _buildSoldeConges(Employe employee) {
    return FutureBuilder<int>(
      future: controller._demandeService.getSoldeConges(employee.id),
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
        icon: const Icon(Icons.access_time),
        color: Colors.blueGrey,
        onPressed: () => Get.to(
          () => HeuresTravailScreen(
            employeId: employee.id,
            employeNom: employee.nom,
            employePrenom: employee.prenom,
          ),
        ),
      ),
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

  void _showEmployeeDetails(Employe employee) async {
    try {
      
      final solde = await controller._demandeService.getSoldeConges(employee.id);

      Get.dialog(
        AlertDialog(
          title: Text('Détails de ${employee.prenom} ${employee.nom}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Nom', employee.nom),
                _buildDetailRow('Prénom', employee.prenom),
                _buildDetailRow('Email', employee.email),
                _buildDetailRow('Matricule', employee.matricule),
                _buildDetailRow('Date naissance', employee.datedenaissance.isNotEmpty 
                  ? controller.formatDate(employee.datedenaissance)
                  : 'Non spécifié'
              ),
                _buildDetailRow('Responsable', employee.responsable != null
                    ? '${employee.responsable!.prenom} ${employee.responsable!.nom}'
                    : 'Aucun responsable'
                ),

                _buildDetailRow(
                'Heures supplémentaires', 
                '${employee.heuresSupp} heures',
                isImportant: true,
                color: employee.heuresSupp > 0 ? Colors.green : Colors.grey,
              ),
               // إضافة سطر لعرض عدد الغيابات
                _buildDetailRow(
                  'Nombre d\'absences', 
                  '${controller.absencesCount[employee.id] ?? 0} jours',
                  isImportant: true,
                  color: (controller.absencesCount[employee.id] ?? 0) > 3 ? Colors.red : Colors.grey,
                ),
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
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () => controller.exportEmployeeToPDF(employee, solde),
              child: const Text('Exporter PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
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

  void _editEmployee(Employe employee) {
    final nomController = TextEditingController(text: employee.nom);
    final prenomController = TextEditingController(text: employee.prenom);
    final emailController = TextEditingController(text: employee.email);
    final matriculeController = TextEditingController(text: employee.matricule);
    DateTime initialDate = employee.datedenaissance.isNotEmpty
        ? DateTime.parse(employee.datedenaissance)
        : DateTime.now();
    String? selectedChefId = employee.responsable?.id;

    Get.dialog(
      StatefulBuilder(
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
                  Obx(() => DropdownButton<String>(
                    value: selectedChefId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucun responsable'),
                      ),
                      ...controller.chefsEquipe.map((chef) => DropdownMenuItem(
                        value: chef.id,
                        child: Text('${chef.prenom} ${chef.nom}'),
                      )).toList(),
                    ],
                    onChanged: (newValue) {
                      setState(() => selectedChefId = newValue);
                    },
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await controller._employeService.updateEmployee(employee.id, {
                      'nom': nomController.text,
                      'prenom': prenomController.text,
                      'email': emailController.text,
                      'matricule': matriculeController.text,
                      'datedenaissance': selectedDate?.toIso8601String(),
                    });
                    
                    if (selectedChefId != employee.responsable?.id) {
                      await controller.assignChefEquipe(
                        employee.id, 
                        selectedChefId
                      );
                    }
                    
                    Get.snackbar('Succès', 'Employé mis à jour',
                        backgroundColor: Colors.green);
                    await controller.loadEmployees();
                    Get.back();
                  } catch (e) {
                    Get.snackbar('Erreur', e.toString(),
                        backgroundColor: Colors.red);
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
    Get.dialog(
      AlertDialog(
        title: Text('Supprimer ${employee.prenom} ${employee.nom}?'),
        content: const Text('Cette action est irréversible. Confirmer?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await controller._employeService.deleteEmployee(employee.id);
                Get.snackbar('Succès', 'Employé supprimé',
                    backgroundColor: Colors.green);
                await controller.loadEmployees();
              } catch (e) {
                Get.snackbar('Erreur', e.toString(),
                    backgroundColor: Colors.red);
              } finally {
                Get.back();
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}