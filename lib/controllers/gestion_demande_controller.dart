import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/demande_service.dart';
import '../services/notification_service.dart';
import '../auth_controller.dart';

class GestionDemandeController extends GetxController {
  final DemandeService demandeService = Get.find();
  final NotificationService notificationService = Get.find();
  final AuthProvider authProvider = Get.find();
  
  final RxList<dynamic> demandes = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final TextEditingController reasonController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDemandes();
  }

  Future<void> loadDemandes() async {
    try {
      isLoading.value = true;
      final allDemandes = await demandeService.getAllDemandes();
      demandes.value = allDemandes.where((d) => d['statut'] == 'EN_ATTENTE').toList();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur de chargement: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveDemande(String demandeId, String type, String dateDebut, String? dateFin) async {
    try {
      await demandeService.approveDemande(
        demandeId, 
        authProvider.userId.value,
        days: type == 'CONGE' ? _calculateDays(dateDebut, dateFin) : null,
      );
      
      final demande = demandes.firstWhere((d) => d['id'] == demandeId);
      notificationService.addEmployeeNotification(
        'Votre demande de ${_getTypeName(type)} a été approuvée',
        demandeId: demandeId,
      );

      demandes.removeWhere((d) => d['id'] == demandeId);
      Get.snackbar('Succès', 'Demande approuvée');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }

  Future<void> rejectDemande(String demandeId, String raison, String type) async {
    try {
      await demandeService.rejectDemande(
        demandeId, 
        authProvider.userId.value,
        raison: raison,
        type: type,
      );
      
      final demande = demandes.firstWhere((d) => d['id'] == demandeId);
      notificationService.addEmployeeNotification(
        'Votre demande de ${_getTypeName(type)} a été rejetée. Raison: $raison',
        demandeId: demandeId,
      );

      demandes.removeWhere((d) => d['id'] == demandeId);
      Get.snackbar('Succès', 'Demande rejetée');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }

  int _calculateDays(String start, String? end) {
    final startDate = DateTime.parse(start);
    final endDate = end != null ? DateTime.parse(end) : startDate;
    return endDate.difference(startDate).inDays + 1;
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'CONGE': return 'congé';
      case 'ABSENCE': return 'absence';
      case 'AUTORISATION_SORTIE': return 'autorisation de sortie';
      default: return type;
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}