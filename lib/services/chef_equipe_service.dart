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

  Future<Map<String, dynamic>> getHeuresEquipe(String chefId) async {
    final url = Uri.parse('$_baseUrl/heures-equipe/$chefId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec du chargement des heures d\'équipe: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getHeuresTravailTousLesEmployes(
    String chefId, {
    String? dateDebut,
    String? dateFin,
  }) async {
    final url = Uri.parse('$_baseUrl/heures-travail-equipe/$chefId')
        .replace(queryParameters: {
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
    });

    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec du chargement des heures de travail: ${response.statusCode}');
    }
  }

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

  Future<List<dynamic>> getEmployesList() async {
    final url = Uri.parse('$_baseUrl/employes');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec du chargement de la liste des employés: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getHeuresJournalieres(
      String employeId, String date) async {
    final url = Uri.parse('$_baseUrl/heures-journalieres/$employeId')
        .replace(queryParameters: {'date': date});

    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec du chargement des heures journalières: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getEmployeInfo(String employeId) async {
    final url = Uri.parse('$_baseUrl/employe-info/$employeId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Employé non trouvé');
    } else {
      throw Exception('Échec du chargement des informations de l\'employé: ${response.statusCode}');
    }
  }

  Future<int> getNombreEmployesSousResponsable(String chefId) async {
  final url = Uri.parse('$_baseUrl/$chefId/nombre-employes');
  final response = await http.get(url, headers: await _getHeaders());

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['nombreEmployes'] as int;
  } else {
    throw Exception('Échec du chargement du nombre d\'employés: ${response.statusCode}');
  }
}
}