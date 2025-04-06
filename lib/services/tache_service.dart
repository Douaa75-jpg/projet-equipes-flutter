import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/tache_model.dart';

class TacheService {
  final String baseUrl = "http://localhost:3000/taches";  // Remplacez par l'URL de votre API

  // Récupérer les tâches d'un employé spécifique
  Future<List<Tache>> getTachesForEmploye(String employeId) async {
    final response = await http.get(Uri.parse('$baseUrl/$employeId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Tache.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des tâches de l\'employé');
    }
  }

  // Créer une nouvelle tâche
  Future<void> createTache(String titre, String description, String dateLimite, String employeId) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'titre': titre,
        'description': description,
        'dateLimite': dateLimite,
        'employeId': employeId,  // Passer l'employeId
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de la création de la tâche');
    }
  }

  // Mettre à jour une tâche
  Future<void> updateTache(String id, String titre, String description, String dateLimite ,{required String statut, // ✅ Nouveau paramètre requis
}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'titre': titre,
        'description': description,
        'dateLimite': dateLimite,
        'statut': statut,
      }),
    );

      if (response.statusCode == 200) {
    // Si la mise à jour est réussie, rien à faire
    return;
  } else {
    // Gestion améliorée des erreurs : récupérer le message d'erreur du serveur
    final errorResponse = json.decode(response.body);
    throw Exception('Erreur lors de la mise à jour de la tâche: ${errorResponse['message'] ?? 'Détails non disponibles'}');
  }
}

  // Supprimer une tâche
  Future<void> deleteTache(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de la tâche');
    }
  }

  // جلب المهام بتاع اليوم
  Future<List<Tache>> getTachesToday() async {
  final response = await http.get(Uri.parse('$baseUrl/today')); // URL هذا يعتمد على الـ API
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Tache.fromJson(e)).toList();
  } else {
    throw Exception('حدث خطأ في جلب المهام بتاع اليوم');
  }
}

}
