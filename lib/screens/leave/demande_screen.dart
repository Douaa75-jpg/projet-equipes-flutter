import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../auth_controller.dart';
import 'package:gestion_equipe_flutter/services/demande_service.dart';
import 'package:gestion_equipe_flutter/services/notification_service.dart';
import 'package:gestion_equipe_flutter/screens/layoutt/employee_layout.dart';

class DemandeController extends GetxController {
  final DemandeService demandeService = Get.find();
  final NotificationService notificationService = Get.find();
  final AuthProvider authProvider = Get.find();

  final formKey = GlobalKey<FormState>();
  var typeDemande = Rx<String?>(null);
  var dateDebut = Rx<DateTime?>(null);
  var dateFin = Rx<DateTime?>(null);
  var raison = Rx<String?>(null);
  var soldeConges = 30.obs;
  var isSubmitting = false.obs;
  var showSuccessAnimation = false.obs;
  var lastNotification = Rx<String?>(null);

  final dateDebutController = TextEditingController();
  final dateFinController = TextEditingController();

  final Map<String, String> typeMapping = {
    'congé': 'CONGE',
    'autorization_sortie': 'AUTORISATION_SORTIE'
  };
  String employeId = '';

  @override
  void onInit() {
    super.onInit();
    final authProvider = Get.find<AuthProvider>();
    if (!authProvider.isAuthenticated.value) {
      Get.offAllNamed('/login');
      return;
    }

    employeId = authProvider.userId.value;
    
    if (employeId.isEmpty) {
      Get.offAllNamed('/login');
      return;
    }

    loadSoldeConges();
  }

  Future<void> loadSoldeConges() async {
    try {
      final employeId = Get.parameters['employeId'] ?? '';
      if (employeId.isEmpty) {
        Get.snackbar('Erreur', 'ID employé non disponible');
        return;
      }
      
      final solde = await demandeService.getSoldeConges(employeId);
      soldeConges.value = solde;
    } catch (e) {
      print('Error loading solde: $e');
      soldeConges.value = 30;
    }
  }

  Future<void> selectDateTime(TextEditingController controller, bool isStartDate) async {
    DateTime? date = await showDatePicker(
    context: Get.context!,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2101),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF8B0000),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF8B0000),
          ),
          dialogTheme: DialogTheme(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: Get.context!,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF8B0000),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF8B0000),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (isStartDate) {
          dateDebut.value = selectedDateTime;
        } else {
          dateFin.value = selectedDateTime;
        }
        controller.text = DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
      }
    }
  }

  // Simuler l'approbation d'une demande
  Future<void> simulateApproval(String demandeId) async {
    await Future.delayed(Duration(seconds: 2));
   
  }

  // Simuler le rejet d'une demande
  Future<void> simulateRejection(String demandeId) async {
    await Future.delayed(Duration(seconds: 2));
   
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (employeId.isEmpty) {
      Get.snackbar('Erreur', 'ID employé manquant');
      return;
    }

    if (dateDebut.value == null) {
      Get.snackbar('Erreur', 'Veuillez sélectionner une date de début');
      return;
    }

    final backendType = typeMapping[typeDemande.value!.toLowerCase()];
    if (backendType == null) {
      Get.snackbar('Erreur', 'Type de demande invalide');
      return;
    }

    isSubmitting.value = true;

    try {
      final demande = {
        'employeId': employeId,
        'type': backendType,
        'dateDebut': dateDebut.value!.toIso8601String(),
        'dateFin': dateFin.value?.toIso8601String(),
        'raison': raison.value,
      };

      // Simuler la création d'une demande avec un ID aléatoire
      final demandeId = DateTime.now().millisecondsSinceEpoch.toString();
      final success = await demandeService.createDemande(demande);
      
      if (success) {
        // Notification pour l'employé
        lastNotification.value = "Votre demande a été envoyée avec succès";
        
        // Notification pour le RH (simulée)
        notificationService.addRHNotification(
          'Nouvelle demande de ${authProvider.prenom.value} ${authProvider.nom.value} (${typeDemande.value})',
          demandeId: demandeId,
        );

        Fluttertoast.showToast(
          msg: "Votre demande a été envoyée avec succès",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0
        );

        // Simuler une réponse aléatoire (approbation ou rejet)
        final randomResponse = DateTime.now().second % 2 == 0;
        if (randomResponse) {
          await simulateApproval(demandeId);
        } else {
          await simulateRejection(demandeId);
        }

        formKey.currentState?.reset();
        typeDemande.value = null;
        dateDebut.value = null;
        dateFin.value = null;
        raison.value = null;
        dateDebutController.clear();
        dateFinController.clear();
        
        await Future.delayed(const Duration(seconds: 2));
        Get.back();
      } else {
        Get.snackbar('Erreur', 'Échec de l\'envoi de la demande');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Une erreur est survenue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    dateDebutController.dispose();
    dateFinController.dispose();
    super.onClose();
  }
}

class DemandeScreen extends StatelessWidget {
  final DemandeController controller = Get.put(DemandeController());

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args != null && args['employeId'] != null) {
      controller.employeId = args['employeId'].toString();
    }
    
    return EmployeeLayout(
      title: 'Nouvelle Demande',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nouvelle Demande',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B0000),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(),
                        const SizedBox(height: 16),
                        _buildReasonField(),
                        const SizedBox(height: 16),
                        _buildDateField(controller.dateDebutController, "Date de début *", true),
                        const SizedBox(height: 16),
                        _buildDateField(controller.dateFinController, "Date de fin (optionnelle)", false),
                        Obx(() => controller.typeDemande.value == 'congé'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Solde disponible: ${controller.soldeConges.value} jours',
                                      style: TextStyle(
                                        color: controller.soldeConges.value > 0
                                            ? Color(0xFF8B0000)
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (controller.soldeConges.value <= 0)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Vous n\'avez plus de jours de congé disponibles',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink()),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        Obx(() => controller.lastNotification.value != null
                            ? _buildNotificationBadge()
                            : SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.typeDemande.value,
          onChanged: (newValue) => controller.typeDemande.value = newValue,
          items: const [
            DropdownMenuItem(
              value: 'congé',
              child: Text('Congé'),
            ),
            DropdownMenuItem(
              value: 'autorization_sortie',
              child: Text('Autorisation de sortie'),
            ),
          ],
          decoration: InputDecoration(
            labelText: "Type de Demande *",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) =>
              value == null ? 'Veuillez sélectionner un type de demande' : null,
        ));
  }

  Widget _buildReasonField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Raison *",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: 3,
      onChanged: (value) => controller.raison.value = value,
      validator: (value) =>
          value == null || value.isEmpty ? 'Veuillez fournir une raison' : null,
    );
  }

  Widget _buildDateField(
    TextEditingController textController, String label, bool isStartDate) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () => controller.selectDateTime(textController, isStartDate),
      validator: isStartDate
          ? (value) =>
              value == null || value.isEmpty ? 'Ce champ est obligatoire' : null
          : null,
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => ElevatedButton(
          onPressed: controller.isSubmitting.value ? null : controller.submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8B0000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : controller.showSuccessAnimation.value
                  ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
                  : const Text(
                      'Soumettre La Demande',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
        ));
  }

  Widget _buildNotificationBadge() {
    return Obx(() => AnimatedOpacity(
          opacity: controller.lastNotification.value != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Color(0xFF8B0000)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(controller.lastNotification.value ?? ''),
                ),
              ],
            ),
          ),
        ));
  }
}