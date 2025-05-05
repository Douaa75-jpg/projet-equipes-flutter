import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DemandeService {
  final String baseUrl = 'http://localhost:3000';  // Remplacez par l'URL de votre API
   final FlutterSecureStorage _storage = const FlutterSecureStorage();

 Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> createDemande(Map<String, dynamic> demandeData) async {
    final url = Uri.parse('$baseUrl/demande');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employeId': demandeData['employeId'],
          'type': demandeData['type'],
          'dateDebut': demandeData['dateDebut'],
          'dateFin': demandeData['dateFin'],
          'raison': demandeData['raison']
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur réseau: $e');
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
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

   Future<List<dynamic>> getEmployeeDemandes(String employeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demande/$employeId/historique'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur: $e');
      return [];
    }
  }

 Future<int> getSoldeConges(String employeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demande/$employeId/solde'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data['soldeConges'] is int 
          ? data['soldeConges'] 
          : int.tryParse(data['soldeConges'].toString()) ?? 30;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<void> supprimerDemande(String demandeId, String userId) async {
  final url = Uri.parse('$baseUrl/demande/$demandeId');
  try {
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['message'] != null) {
        return;
      }
      throw Exception('Réponse inattendue du serveur');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Échec de la suppression de la demande');
    }
  } catch (e) {
    print('Erreur lors de la suppression: $e');
    throw Exception('Erreur réseau: $e');
  }
}

   Future<bool> updateDemande(String demandeId, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('$baseUrl/demande/$demandeId');
    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

Future<void> approveDemande(
    String demandeId, 
    String userId, {
    int? days,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/demande/$demandeId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          if (days != null) 'days': days,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec approbation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

Future<void> rejectDemande(
    String demandeId, 
    String userId, {
    required String raison,
    required String type,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/demande/$demandeId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'raison': raison,
          'type': type,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec rejet: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<List<dynamic>> getTeamLeaveRequests(String responsableId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/demande/equipe/en-conge/$responsableId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur réseau: $e');
  }
}

Future<List<dynamic>> getUpcomingTeamLeaveRequests(String responsableId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/demande/equipe/conges-a-venir/$responsableId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur réseau: $e');
  }
}


Future<List<dynamic>> getUpcomingLeaves() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/demande/conges/a-venir'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur réseau: $e');
  }
}
}
