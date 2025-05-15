import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DemandeService extends GetxService {
  final String baseUrl = 'http://localhost:3000';
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
        headers: await _getHeaders(),
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
        debugPrint('Erreur: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur réseau: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAllDemandes({int page = 1, int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demande?page=$page&limit=$limit'),
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

  Future<List<dynamic>> getEmployeeDemandes(String employeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/demande/$employeId/historique'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      return [];
    }
  }

  Future<int> getSoldeConges(String employeId) async {
    try {
      if (employeId.isEmpty) {
        debugPrint('EmployeId is empty in getSoldeConges');
        return 30;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/demande/$employeId/solde'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final solde = data['soldeConges'] ?? data['data']?['soldeConges'];
        return (solde is int ? solde : int.tryParse(solde.toString()) ?? 30);
      } else {
        debugPrint('Error getting solde conges: ${response.statusCode}');
        return 30;
      }
    } catch (e) {
      debugPrint('Exception in getSoldeConges: $e');
      return 30;
    }
  }

  Future<void> supprimerDemande(String demandeId, String userId) async {
    final url = Uri.parse('$baseUrl/demande/$demandeId');
    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
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
      debugPrint('Erreur lors de la suppression: $e');
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
          headers: await _getHeaders(),
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
          headers: await _getHeaders(),
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
    // Validate responsableId
    if (responsableId.isEmpty) {
      throw Exception('Responsable ID cannot be empty');
    }

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
    // Validate responsableId
    if (responsableId.isEmpty) {
      throw Exception('Responsable ID cannot be empty');
    }

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

  Future<List<Map<String, dynamic>>> getJoursFeries(int year) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/jours-feries?year=$year'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load holidays');
  } catch (e) {
    debugPrint('Error getting holidays: $e');
    return [];
  }
}
}