import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/demande_service.dart';
import '../../auth_controller.dart';
import '../layoutt/rh_layout.dart';

class GestionDemandeController extends GetxController {
  final DemandeService _demandeService = Get.find();
  final AuthProvider _authProvider = Get.find();
  
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
      final allDemandes = await _demandeService.getAllDemandes();
      demandes.value = allDemandes.where((d) => d['statut'] == 'EN_ATTENTE').toList();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showRejectionDialog(String demandeId, String type) async {
    return Get.defaultDialog(
      title: 'Raison du rejet',
      titleStyle: TextStyle(color: Color(0xFF8B0000)),
      content: TextField(
        controller: reasonController,
        decoration: InputDecoration(
          hintText: 'Entrez la raison du rejet',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          child: Text('Annuler', style: TextStyle(color: Colors.grey[700])),
          onPressed: () => Get.back(),
        ),
        ElevatedButton(
          child: const Text('Confirmer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
          ),
          onPressed: () async {
            if (reasonController.text.isEmpty) {
              Get.snackbar(
                'Attention',
                'Veuillez entrer une raison',
                backgroundColor: Colors.orange,
              );
              return;
            }
            Get.back();
            await rejectDemande(demandeId, reasonController.text, type);
            reasonController.clear();
          },
        ),
      ],
    );
  }

  Future<void> approveDemande(String demandeId, String type, String dateDebut, String? dateFin) async {
    try {
      if (type == 'CONGE') {
        final days = calculateLeaveDays(dateDebut, dateFin);
        await _demandeService.approveDemande(
          demandeId, 
          _authProvider.userId.value,
          days: days,
        );
      } else {
        await _demandeService.approveDemande(
          demandeId, 
          _authProvider.userId.value,
        );
      }
      
      Get.snackbar(
        'Succès',
        'Demande approuvée avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      loadDemandes();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> rejectDemande(String demandeId, String raison, String type) async {
    try {
      await _demandeService.rejectDemande(
        demandeId, 
        _authProvider.userId.value,
        raison: raison,
        type: type,
      );
      
      Get.snackbar(
        'Succès',
        'Demande rejetée avec succès',
        backgroundColor: Color(0xFF8B0000),
        colorText: Colors.white,
      );
      loadDemandes();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  int calculateLeaveDays(String dateDebut, String? dateFin) {
    final start = DateTime.parse(dateDebut);
    final end = dateFin != null ? DateTime.parse(dateFin) : start;
    return end.difference(start).inDays + 1;
  }

  String getTypeDemande(String type) {
    switch (type) {
      case 'CONGE': return 'Congé';
      case 'ABSENCE': return 'Absence';
      case 'AUTORISATION_SORTIE': return 'Autorisation de sortie';
      default: return type;
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}

class GestionDemandeScreen extends StatelessWidget {
  GestionDemandeScreen({super.key});
  final GestionDemandeController controller = Get.put(GestionDemandeController());

 @override
Widget build(BuildContext context) {
  return Obx(() {
    final authProvider = Get.find<AuthProvider>();
    if (authProvider.typeResponsable.value != 'RH') {
      return RhLayout(
        title: 'Accès refusé',
        child: Center(
          child: Text(
            'Vous n\'avez pas les autorisations nécessaires',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      );
    }

    return RhLayout(
      title: 'Gestion des demandes',
      child: _buildContent(),
    );
  });
}

  Widget _buildContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (controller.demandes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 50, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Aucune demande en attente',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      
      return RefreshIndicator(
        onRefresh: controller.loadDemandes,
        child: ListView.builder(
          padding: EdgeInsets.only(top: 8, bottom: 20),
          itemCount: controller.demandes.length,
          itemBuilder: (context, index) {
            return _buildDemandeItem(controller.demandes[index]);
          },
        ),
      );
    });
  }
  

  Widget _buildDemandeItem(Map<String, dynamic> demande) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(Get.context!).size.width - 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    controller.getTypeDemande(demande['type']),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${demande['employe']['utilisateur']['nom']} ${demande['employe']['utilisateur']['prenom']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${demande['dateDebut'].toString().substring(0, 10)}'
                    '${demande['dateFin'] != null ? ' - ${demande['dateFin'].toString().substring(0, 10)}' : ''}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (demande['raison'] != null) ...[
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demande['raison'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('Approuver'),
                  onPressed: () => controller.approveDemande(
                    demande['id'],
                    demande['type'],
                    demande['dateDebut'],
                    demande['dateFin'],
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFF8B0000),
                    side: BorderSide(color: Color(0xFF8B0000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('Rejeter', style: TextStyle(color: Colors.white)),
                  onPressed: () => controller.showRejectionDialog(
                    demande['id'],
                    demande['type'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}