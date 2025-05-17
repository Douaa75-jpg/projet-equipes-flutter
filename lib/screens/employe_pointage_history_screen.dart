import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/chef_equipe_service.dart';
import '../screens/layoutt/chef_layout.dart';
import '../../auth_controller.dart';

class EmployePointageHistoryController extends GetxController {
  final ChefEquipeService _chefEquipeService = ChefEquipeService();
  final AuthProvider authController = Get.find<AuthProvider>();

  var pointages = <dynamic>[].obs;
  var isLoading = true.obs;
  var errorMessage = RxString('');
  var selectedDateRange = Rxn<DateTimeRange>();

  var nom = ''.obs;
  var prenom = ''.obs;
  var email = ''.obs;
  var matricule = ''.obs;
  var dateNaissance = ''.obs;

  final String employeId;
  final String chefId;

  EmployePointageHistoryController({
    required this.employeId,
    required this.chefId,
  });

  @override
  void onInit() {
    super.onInit();
    loadPointageHistory();
  }

Future<void> loadPointageHistory() async {
  try {
    if (employeId.isEmpty) {
      throw Exception('ID employé non valide');
    }

    isLoading(true);
    errorMessage('');

    final employeInfo = await _chefEquipeService.getEmployeInfo(employeId);
    
    if (employeInfo == null || employeInfo.isEmpty) {
      throw Exception('Employé non trouvé (ID: $employeId)');
    }

    nom(employeInfo['nom'] ?? '');
    prenom(employeInfo['prenom'] ?? '');
    email(employeInfo['email'] ?? '');
    matricule(employeInfo['matricule'] ?? '');
    dateNaissance(employeInfo['datedenaissance'] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(employeInfo['datedenaissance']))
        : '');

    // 2. الحصول على سجل الحضور
    final history = await _chefEquipeService.getHistoriqueEquipe(
      chefId,
      employeId: employeId,
    );

    if (history == null || history['items'] == null) {
      throw Exception('Aucune donnée de pointage disponible');
    }

    pointages.assignAll(history['items']);
  } catch (e) {
    errorMessage(e.toString());
    Get.snackbar(
      'Erreur',
      e.toString(),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  } finally {
    isLoading(false);
  }
}

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange.value ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      selectedDateRange(picked);
      await loadPointageHistoryWithDates();
    }
  }

  Future<void> loadPointageHistoryWithDates() async {
    if (selectedDateRange.value == null) return;

    try {
      isLoading(true);
      errorMessage('');

      final history = await _chefEquipeService.getHistoriqueEquipe(
        chefId,
        employeId: employeId,
        dateDebut: DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start),
        dateFin: DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end),
      );

      if (history != null && history['items'] != null) {
        pointages.assignAll(history['items']);
      } else {
        errorMessage('Aucune donnée pour cette période');
        pointages.clear();
      }
    } catch (e) {
      errorMessage('Erreur: ${e.toString()}');
      pointages.clear();
    } finally {
      isLoading(false);
    }
  }

  Future<void> generateAndExportPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Historique de Pointage',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  padding: pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Informations Employé',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfInfoRow('Nom', nom.value),
                      _buildPdfInfoRow('Prénom', prenom.value),
                      _buildPdfInfoRow('Matricule', matricule.value),
                      _buildPdfInfoRow('Email', email.value),
                      _buildPdfInfoRow('Date Naissance', dateNaissance.value),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                if (selectedDateRange.value != null)
                  pw.Row(
                    children: [
                      pw.Text('Période: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${DateFormat('dd/MM/yyyy').format(selectedDateRange.value!.start)} - '
                          '${DateFormat('dd/MM/yyyy').format(selectedDateRange.value!.end)}'),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Text('Historique des Pointages',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pointages.isEmpty
                    ? pw.Text('Aucun pointage trouvé')
                    : pw.Table.fromTextArray(
                        context: context,
                        border: pw.TableBorder.all(),
                        headerStyle:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.grey300),
                        headers: ['Date', 'Type', 'Heure', 'Statut'],
                        data: pointages.map((pointage) => [
                              DateFormat('dd/MM/yyyy').format(DateTime.parse(
                                  pointage['date'] ?? DateTime.now().toString())),
                              pointage['typeLibelle'] ?? pointage['type'] ?? '',
                              pointage['heure'] ?? '',
                              pointage['statut'] ?? 'Présent',
                            ]).toList(),
                      ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            '$label :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(value.isNotEmpty ? value : 'Non renseigné'),
      ],
    );
  }
}

class EmployePointageHistoryScreen extends StatelessWidget {
  final String employeId;
  final String chefId;

  const EmployePointageHistoryScreen({
    Key? key,
    required this.employeId,
    required this.chefId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployePointageHistoryController>(
      init: EmployePointageHistoryController(
        employeId: employeId,
        chefId: chefId,
      ),
      builder: (controller) {
        return ChefLayout(
          title: 'Historique de Pointage',
          child: _buildBodyContent(controller),
        );
      },
    );
  }

  Widget _buildBodyContent(EmployePointageHistoryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Chargement en cours...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,color: Colors.red.shade400,size: 50,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF8B0000),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.loadPointageHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF8B0000)),
                  onPressed: controller.generateAndExportPDF,
                  tooltip: 'Exporter en PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Color(0xFF8B0000)),
                  onPressed: () => controller.selectDateRange(Get.context!),
                  tooltip: 'Choisir une période',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF8B0000)),
                  onPressed: controller.loadPointageHistory,
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informations du Employé',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8B0000),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ID: ${controller.employeId}',
                                  style: TextStyle(
                                    color: const Color(0xFF8B0000),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Nom', controller.nom.value),
                          _buildInfoRow('Prénom', controller.prenom.value),
                          _buildInfoRow('Matricule', controller.matricule.value),
                          _buildInfoRow('Email', controller.email.value),
                          _buildInfoRow('Date de naissance', controller.dateNaissance.value),
                        ],
                      ),
                    ),
                  ),
                  if (controller.selectedDateRange.value != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Période: ${DateFormat('dd/MM/yyyy').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd/MM/yyyy').format(controller.selectedDateRange.value!.end)}',
                            style: TextStyle(
                              color: const Color(0xFF8B0000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Text(
                          'Historique des Pointages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B0000),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${controller.pointages.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: controller.pointages.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun pointage trouvé',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin: 16,
                                      headingRowColor:
                                          MaterialStateProperty.resolveWith<Color>(
                                        (states) => Colors.blue.shade50,
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: Container(
                                            width: constraints.maxWidth * 0.25,
                                            child: Center(
                                              child: Text(
                                                'Date',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF8B0000),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            width: constraints.maxWidth * 0.25,
                                            child: Center(
                                              child: Text(
                                                'Type',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF8B0000),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            width: constraints.maxWidth * 0.25,
                                            child: Center(
                                              child: Text(
                                                'Heure',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF8B0000),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            width: constraints.maxWidth * 0.25,
                                            child: Center(
                                              child: Text(
                                                'Statut',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF8B0000),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: controller.pointages.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final pointage = entry.value;
                                        final isAbsent =
                                            (pointage['statut'] ?? 'Présent') == 'Absent';
                                        
                                        return DataRow(
                                          color: MaterialStateProperty.resolveWith<Color>(
                                            (states) => index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                                          ),
                                          cells: [
                                            DataCell(
                                              Center(
                                                child: Text(
                                                  DateFormat('dd/MM/yyyy').format(
                                                    DateTime.parse(pointage['date'] ?? DateTime.now().toString())),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Center(
                                                child: Text(
                                                  pointage['typeLibelle'] ?? pointage['type'] ?? '',
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Center(
                                                child: Text(pointage['heure'] ?? ''),
                                              ),
                                            ),
                                            DataCell(
                                              Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isAbsent
                                                        ? Colors.red.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: isAbsent
                                                          ? Colors.red.shade200
                                                          : Colors.green.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    pointage['statut'] ?? 'Présent',
                                                    style: TextStyle(
                                                      color: isAbsent ? Colors.red : Colors.green,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}