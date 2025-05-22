import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChefEquipeService {
  final String _baseUrl = 'http://localhost:3000/pointages';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
 
//pour recuperer l'historique de pointage de chaque employe
   Future<Map<String, dynamic>> getHistoriqueEquipe(
    String chefId, {
    String? dateDebut,
    String? dateFin,
    int? page,
    int? limit,
    String? type,
    String? employeId,
  }) async {
    final url = Uri.parse('$_baseUrl/historique-equipe/$chefId')
        .replace(queryParameters: {
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (type != null) 'type': type,
      if (employeId != null) 'employeId': employeId,
    });

    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique: ${response.statusCode}');
    }
  }


  // Dans ChefEquipeService.dart
Future<void> updateEmployee(String employeId, Map<String, dynamic> updateData) async {
  try {
    final response = await http.put(  // Changé de patch à put
      Uri.parse('http://localhost:3000/utilisateurs/$employeId'),
      headers: await _getHeaders(),  // Utilise les headers avec auth
      body: json.encode(updateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la mise à jour: $e');
  }
}

Future<Map<String, dynamic>> getEmployeInfo(String employeId) async {
  try {
    if (employeId.isEmpty) {
      throw Exception('ID employé vide');
    }

    final url = Uri.parse('$_baseUrl/employe-info/$employeId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Employé non trouvé (ID: $employeId)');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la récupération des infos employé: $e');
  }
}

//pour recuperer la liste d'employe sous responsable avec son solde et nbr d'absence 
 Future<List<dynamic>> getHeuresEquipe(String chefId) async {
  try {
    final url = Uri.parse('$_baseUrl/heures-equipe/$chefId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Assure que nous retournons toujours une List même si un seul élément
      return data is List ? data : [data];
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la récupération des heures de l\'équipe: $e');
  }
}


//pour recuperer les nombre d'employe sous ce responsable 
Future<int> getNombreEmployesSousResponsable(String chefId) async {
  try {
    final url = Uri.parse('$_baseUrl/$chefId/nombre-employes');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['nombreEmployes'] as int;
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur lors du comptage des employés: $e');
  }
}


//pour recuperer les nombre des employe present ce jour
Future<Map<String, dynamic>> getPresencesSousChefAujourdhui(String chefId) async {
  try {
    final url = Uri.parse('$_baseUrl/presences-sous-chef/$chefId/stats-jour');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la récupération des présences: $e');
  }
}
}