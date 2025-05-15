import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/demande_service.dart';
import '../services/notification_service.dart';
import '../auth_controller.dart';

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

  final dateDebutController = TextEditingController();
  final dateFinController = TextEditingController();

  final Map<String, String> typeMapping = {
    'congé': 'CONGE',
    'absence': 'ABSENCE',
    'autorization_sortie': 'AUTORISATION_SORTIE'
  };

  @override
  void onInit() {
    super.onInit();
    if (!authProvider.isAuthenticated.value) {
      Get.offAllNamed('/login');
      return;
    }
    loadSoldeConges();
  }

  Future<void> loadSoldeConges() async {
    try {
      final solde = await demandeService.getSoldeConges(authProvider.userId.value);
      soldeConges.value = solde;
    } catch (e) {
      soldeConges.value = 30;
    }
  }

  Future<void> selectDateTime(TextEditingController controller, bool isStartDate) async {
    DateTime? date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: Get.context!,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
        if (isStartDate) {
          dateDebut.value = selectedDateTime;
        } else {
          dateFin.value = selectedDateTime;
        }
        controller.text = DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
      }
    }
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    isSubmitting.value = true;

    try {
      final demande = {
        'employeId': authProvider.userId.value,
        'type': typeMapping[typeDemande.value!.toLowerCase()],
        'dateDebut': dateDebut.value!.toIso8601String(),
        'dateFin': dateFin.value?.toIso8601String(),
        'raison': raison.value,
      };

      final success = await demandeService.createDemande(demande);
      
      if (success) {
        notificationService.addRHNotification(
          'Nouvelle demande de ${authProvider.prenom.value} ${authProvider.nom.value} (${typeDemande.value})',
          demandeId: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        Get.snackbar(
          'Succès', 
          'Demande envoyée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        resetForm();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Échec de l\'envoi: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetForm() {
    formKey.currentState?.reset();
    typeDemande.value = null;
    dateDebut.value = null;
    dateFin.value = null;
    raison.value = null;
    dateDebutController.clear();
    dateFinController.clear();
  }

  @override
  void onClose() {
    dateDebutController.dispose();
    dateFinController.dispose();
    super.onClose();
  }
}