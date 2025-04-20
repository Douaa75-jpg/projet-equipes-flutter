import 'package:http/http.dart' as http;
import 'dart:convert';

class DemandeService {
  final String baseUrl = 'http://localhost:3000';  // Remplacez par l'URL de votre API

  Future<bool> createDemande(Map<String, dynamic> demandeData) async {
    final url = Uri.parse('$baseUrl/demande');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(demandeData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // Log de l'erreur pour obtenir plus de détails
        print('Erreur lors de l\'envoi de la demande: ${response.statusCode}');
        print('Réponse du serveur: ${response.body}');
        return false;
      }
    } catch (e) {
      // Log des erreurs réseau
      print('Erreur lors de l\'envoi de la demande: $e');
      return false;
    }
  }

  //recuperer tout les demande 
 Future<List<dynamic>> getAllDemandes({int page = 1, int limit = 50}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/demande?page=$page&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Données reçues: ${data}');
      
      // Vérifiez si la réponse contient un tableau 'demandes'
      if (data is Map && data.containsKey('demandes')) {
        return data['demandes'];
      }
      // Ou si c'est directement un tableau
      else if (data is List) {
        return data;
      }
      return [];
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('Erreur getAllDemandes: $e');
    return [];
  }
}

  Future<void> supprimerDemande(String demandeId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/demande/$demandeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression de la demande');
    }
  }

  Future<bool> updateDemande(String demandeId, Map<String, dynamic> updatedData) async {
  final url = Uri.parse('$baseUrl/demande/$demandeId');
  try {
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Erreur lors de la mise à jour: ${response.statusCode}');
      print('Réponse du serveur: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Erreur réseau lors de la mise à jour: $e');
    return false;
  }
}

}
