import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class PointageService extends GetxService {
  final String baseUrl = 'http://localhost:3000/pointages';
  final String timezone = 'Africa/Tunis';

  // Headers communs
  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<Map<String, dynamic>> enregistrerPointage(String employeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$employeId'),
        headers: _headers,
      );

      debugPrint(
          'Pointage Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in enregistrerPointage: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calculerHeuresTravail(
      String employeId, String dateDebut, String dateFin) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/heures-travail/$employeId?dateDebut=$dateDebut&dateFin=$dateFin');

      final response = await http.get(uri, headers: _headers);

      debugPrint(
          'Heures Travail Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in calculerHeuresTravail: $e');
      return {
        'totalHeures': 0,
        'totalHeuresFormatted': '0h 0min',
        'heuresParJour': {}
      };
    }
  }

Future<List<dynamic>> getHistorique(String employeId, String date) async {
  try {
    final uri = date.isNotEmpty 
        ? Uri.parse('$baseUrl/historique/$employeId?date=$date')
        : Uri.parse('$baseUrl/historique/$employeId');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<dynamic>.from(data);
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw _handleError(response);
    }
  } catch (e) {
    debugPrint('Error in getHistorique: $e');
    return [];
  }
}

  Future<Map<String, dynamic>> getHeuresEquipe(String chefId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/heures-equipe/$chefId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getHeuresEquipe: $e');
      return {'equipe': []};
    }
  }

  Future<Map<String, dynamic>> getHeuresTravailTousLesEmployes(
    String chefId, {
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/heures-travail-equipe/$chefId');
      if (dateDebut != null && dateFin != null) {
        uri = Uri.parse(
            '$baseUrl/heures-travail-equipe/$chefId?dateDebut=$dateDebut&dateFin=$dateFin');
      }

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getHeuresTravailTousLesEmployes: $e');
      return {'employes': [], 'periode': {}};
    }
  }

  Future<Map<String, dynamic>> getWeeklyHoursChartData(
      String employeId, String dateDebut) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/weekly-hours-chart/$employeId?dateDebut=$dateDebut'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getWeeklyHoursChartData: $e');
      return {
        'labels': [],
        'datasets': [
          {'data': [], 'label': 'Heures travaillées'}
        ]
      };
    }
  }

  Future<Map<String, dynamic>> getAttendanceDistribution(
      String employeId, String dateDebut, String dateFin) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/attendance-distribution/$employeId?dateDebut=$dateDebut&dateFin=$dateFin'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier le message spécial
        if (data['message'] != null &&
            data['message'].contains("n'était pas encore en poste")) {
          return {
            'labels': ['Présent', 'Retard', 'Absent'],
            'datasets': [
              {
                'data': [0, 0, 0]
              }
            ],
            'rawData': {
              'present': 0,
              'retard': 0,
              'absent': 0,
              'joursOuvresTotal': 0,
              'message': data['message']
            },
            'periode': data['periode']
          };
        }

        return data;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      return {
        'labels': ['Présent', 'Retard', 'Absent'],
        'datasets': [
          {
            'data': [0, 0, 0]
          }
        ],
        'rawData': {
          'present': 0,
          'retard': 0,
          'absent': 0,
          'joursOuvresTotal': 0,
          'message': 'Erreur lors du chargement des données'
        }
      };
    }
  }

  Future<Map<String, dynamic>> getEmployeInfo(String employeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employe-info/$employeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getEmployeInfo: $e');
      return {};
    }
  }

  Future<int> getNombreEmployesSousResponsable(String chefId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$chefId/nombre-employes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['nombreEmployes'] as int;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getNombreEmployesSousResponsable: $e');
      return 0;
    }
  }

  // Helper pour la gestion des erreurs
  Exception _handleError(http.Response response) {
    debugPrint('API Error: ${response.statusCode} - ${response.body}');
    try {
      final error = json.decode(response.body);
      return Exception(error['message'] ?? 'Erreur inconnue');
    } catch (e) {
      return Exception('Erreur HTTP ${response.statusCode}');
    }
  }

  // Helper pour formater les dates selon le timezone
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date.toLocal());
  }

  // Méthodes mises à jour pour Flutter
  Future<int> getNombreEmployesPresentAujourdhui({String? employeId}) async {
    try {
      final endpoint = employeId != null
          ? '$baseUrl/presences-aujourdhui/$employeId'
          : '$baseUrl/presences-aujourdhui';

      final response = await http.get(Uri.parse(endpoint), headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body)['count'] as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error in getNombreEmployesPresentAujourdhui: $e');
      return 0;
    }
  }

//recuperer lles presence de la semaine
  Future<Map<String, dynamic>> getPresenceByWeekdayForAllEmployees(
      String dateDebut, String dateFin) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/presence-weekday/all?dateDebut=$dateDebut&dateFin=$dateFin'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getPresenceByWeekdayForAllEmployees: $e');
      return {
        'labels': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'],
        'datasets': []
      };
    }
  }

  Future<Map<String, dynamic>> getHistoriqueEquipe(
    String chefId, {
    String? dateDebut,
    String? dateFin,
    int page = 1,
    int limit = 10,
    String? type,
    String? employeId,
  }) async {
    try {
      var queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (dateDebut != null) 'dateDebut': dateDebut,
        if (dateFin != null) 'dateFin': dateFin,
        if (type != null) 'type': type,
        if (employeId != null) 'employeId': employeId,
      };

      final uri = Uri.parse('$baseUrl/historique-equipe/$chefId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('Error in getHistoriqueEquipe: $e');
      return {
        'items': [],
        'meta': {'total': 0, 'page': 1, 'limit': 10, 'totalPages': 0},
        'periode': {}
      };
    }
  }
}
