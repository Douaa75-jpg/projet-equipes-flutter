import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../../services/demande_service.dart';
import '../layoutt/employee_layout.dart';
import '../../auth_controller.dart';

class HistoriqueDemandesController extends GetxController {
  final String employeId;
  final DemandeService _demandeService = DemandeService();
  final AuthProvider authProvider = Get.find<AuthProvider>();

  HistoriqueDemandesController(this.employeId);

  var allDemandes = <dynamic>[].obs;
  var filteredDemandes = <dynamic>[].obs;
  var isLoading = true.obs;
  var selectedStatut = 'TOUS'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDemandes();
  }

  Future<void> fetchDemandes() async {
    try {
      isLoading(true);
      final demandes = await _demandeService.getAllDemandes();
      final employeDemandes =
          demandes.where((d) => d['employe']['id'] == employeId).toList();
      allDemandes.assignAll(employeDemandes);
      filterDemandes(selectedStatut.value);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la récupération des demandes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void filterDemandes(String statut) {
    selectedStatut.value = statut;
    if (statut == 'TOUS') {
      filteredDemandes.assignAll(allDemandes);
    } else {
      filteredDemandes
          .assignAll(allDemandes.where((d) => d['statut'] == statut).toList());
    }
  }

  Future<void> updateDemande(
      String demandeId, Map<String, dynamic> updatedData) async {
    try {
      final success =
          await _demandeService.updateDemande(demandeId, updatedData);
      if (success) {
        Get.snackbar(
          'Succès',
          'Demande modifiée avec succès !',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchDemandes();
      } else {
        Get.snackbar(
          'Erreur',
          'Échec de la modification de la demande',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la modification: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteDemande(String demandeId) async {
    try {
      await _demandeService.supprimerDemande(demandeId, employeId);
      Get.snackbar(
        'Succès',
        'Demande supprimée avec succès !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchDemandes();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la suppression: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class HistoriqueDemandesPage extends StatelessWidget {
  final String employeId;
  final HistoriqueDemandesController controller;

  HistoriqueDemandesPage({super.key, required this.employeId})
      : controller = Get.put(HistoriqueDemandesController(employeId));

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy – HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color getStatusColor(String statut) {
    switch (statut) {
      case 'APPROUVEE':
        return Colors.green;
      case 'REJETEE':
        return Colors.red;
      case 'EN_ATTENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<Uint8List> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      // Return an empty image if the logo can't be loaded
      return Uint8List(0);
    }
  }

  Future<void> _exportToPdf(Map<String, dynamic> demande) async {
    try {
      final pdf = pw.Document();
      final image = await _loadImage();
      final imageProvider = pw.MemoryImage(image);

      // Safely handle null values
      final authProvider = Get.find<AuthProvider>();
      final type = demande['type']?.toString() ?? 'DEMANDE';
      final statut = demande['statut']?.toString() ?? 'INCONNU';
      final dateDebut = demande['dateDebut']?.toString() ?? '';
      final dateFin = demande['dateFin']?.toString();
      final raison = demande['raison']?.toString() ?? 'Non spécifiée';
      final employe = demande['employe'] ?? {};
      final prenom = authProvider.prenom.value.isNotEmpty 
        ? authProvider.prenom.value 
        : 'غير محدد';
       final nom = authProvider.nom.value.isNotEmpty 
        ? authProvider.nom.value 
        : 'غير محدد';
      final employeId = employe['id']?.toString() ?? '';
      final matricule = authProvider.matricule.value.isNotEmpty 
        ? authProvider.matricule.value 
        : 'غير محدد';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Titre du document
                pw.Center(
                  child: pw.Text('DEMANDE ${type.toUpperCase()}',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 30),

                // Informations de la demande
                pw.Text('Référence: ${demande['id'] ?? 'N/A'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                pw.Row(
                  children: [
                    pw.Text('Statut: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(statut,
                        style: pw.TextStyle(
                            color: PdfColors.green,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 15),

                pw.Text('Détails de la demande:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Date de début'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(dateDebut.isNotEmpty
                              ? formatDate(dateDebut)
                              : 'Non spécifiée'),
                        ),
                      ],
                    ),
                    if (dateFin != null)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('Date de fin'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(formatDate(dateFin)),
                          ),
                        ],
                      ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Raison'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(raison),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Informations de l'employé
                pw.Text('Informations employé:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Nom complet'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('$prenom $nom'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Matricule'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(matricule),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('ID Employé'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(employeId),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Signature et date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Fait à: sfax',
                            style:
                                pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                        pw.Text(
                            'Le: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                            style:
                                pw.TextStyle(fontStyle: pw.FontStyle.italic)),
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
                            style:
                                pw.TextStyle(fontStyle: pw.FontStyle.italic)),
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
    } catch (e) {
      print('Error generating PDF: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showModifierDemandeDialog(Map<String, dynamic> demande) {
    final TextEditingController raisonController =
        TextEditingController(text: demande['raison'] ?? '');
    DateTime dateDebut = DateTime.parse(demande['dateDebut']);
    Rx<DateTime?> dateFin =
        (demande['dateFin'] != null ? DateTime.parse(demande['dateFin']) : null)
            .obs;

    Get.dialog(
      AlertDialog(
        title: const Text("Modifier la demande"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: raisonController,
                decoration: const InputDecoration(
                  labelText: 'Raison',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Obx(() => ListTile(
                    title: const Text("Date début"),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: dateDebut,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && picked != dateDebut) {
                        dateDebut = picked;
                      }
                    },
                  )),
              Obx(() => ListTile(
                    title: const Text("Date fin"),
                    subtitle: Text(
                      dateFin.value != null
                          ? DateFormat('dd/MM/yyyy').format(dateFin.value!)
                          : 'Non définie',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: dateFin.value ?? dateDebut,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        dateFin.value = picked;
                      }
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () {
              if (dateFin.value != null && dateFin.value!.isBefore(dateDebut)) {
                Get.snackbar(
                  'Erreur',
                  'La date de fin doit être après la date de début',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final updatedData = {
                'dateDebut': dateDebut.toIso8601String(),
                'dateFin': dateFin.value?.toIso8601String(),
                'raison': raisonController.text,
                'type': demande['type'],
                'userId': employeId,
              };

              controller.updateDemande(demande['id'], updatedData);
              Get.back();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String demandeId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette demande ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () {
              controller.deleteDemande(demandeId);
              Get.back();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      title: 'Historique des Demandes',
      child: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Obx(() => DropdownButton<String>(
                              value: controller.selectedStatut.value,
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: (value) {
                                if (value != null)
                                  controller.filterDemandes(value);
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'TOUS',
                                  child: Text('Toutes les demandes'),
                                ),
                                DropdownMenuItem(
                                  value: 'APPROUVEE',
                                  child: Text('Approuvées'),
                                ),
                                DropdownMenuItem(
                                  value: 'REJETEE',
                                  child: Text('Rejetées'),
                                ),
                                DropdownMenuItem(
                                  value: 'EN_ATTENTE',
                                  child: Text('En attente'),
                                ),
                              ],
                            )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => controller.filteredDemandes.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucune demande trouvée.',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: controller.fetchDemandes,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                itemCount: controller.filteredDemandes.length,
                                itemBuilder: (context, index) {
                                  final demande =
                                      controller.filteredDemandes[index];
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                demande['type']
                                                    .toString()
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Chip(
                                                backgroundColor: getStatusColor(
                                                        demande['statut'])
                                                    .withOpacity(0.2),
                                                label: Text(
                                                  demande['statut'],
                                                  style: TextStyle(
                                                    color: getStatusColor(
                                                        demande['statut']),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Début: ${formatDate(demande['dateDebut'])}',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          if (demande['dateFin'] != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Fin: ${formatDate(demande['dateFin'])}',
                                                    style: const TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (demande['raison'] != null &&
                                              demande['raison']
                                                  .toString()
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10),
                                              child: Text(
                                                'Raison: ${demande['raison']}',
                                                style: const TextStyle(
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (demande['statut'] ==
                                                  'EN_ATTENTE')
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _showModifierDemandeDialog(
                                                        demande);
                                                  },
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.orange),
                                                  label: const Text(
                                                    'Modifier',
                                                    style: TextStyle(
                                                        color: Colors.orange),
                                                  ),
                                                ),
                                              const SizedBox(width: 10),
                                              if (demande['statut'] ==
                                                  'APPROUVEE')
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _exportToPdf(demande);
                                                  },
                                                  icon: const Icon(
                                                      Icons.picture_as_pdf,
                                                      color: Colors.green),
                                                  label: const Text(
                                                    'Exporter PDF',
                                                    style: TextStyle(
                                                        color: Colors.green),
                                                  ),
                                                ),
                                              const SizedBox(width: 10),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  _showDeleteConfirmationDialog(
                                                      demande['id']);
                                                },
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                label: const Text(
                                                  'Supprimer',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
