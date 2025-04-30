import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';


class PointageService {
  final String baseUrl = 'http://localhost:3000/pointages'; // URL de votre backend NestJS

  // Enregistrer un pointage (entrée/sortie automatique)
  Future<Map<String, dynamic>> enregistrerPointage(String employeId) async {
    print('Enregistrement pointage pour employé: $employeId');
    
    final response = await http.post(
      Uri.parse('$baseUrl/$employeId'),
      headers: {"Content-Type": "application/json"},
    );
    
    print('Réponse API enregistrerPointage : ${response.body}');
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de l\'enregistrement du pointage');
    }
  }

  // Calculer les heures travaillées
  Future<Map<String, dynamic>> calculerHeuresTravail(
    String employeId, 
    String dateDebut, 
    String dateFin
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/heures-travail/$employeId?dateDebut=$dateDebut&dateFin=$dateFin'),
    );
    
    print('Réponse API calculerHeuresTravail : ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du calcul des heures de travail');
    }
  }

  // Obtenir l'historique des pointages
 Future<List<dynamic>> getHistorique(String employeId, String date) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/historique/$employeId?date=$date'),
    );
    
    debugPrint('Réponse API getHistorique : ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      }
      throw Exception("Format de réponse inattendu");
    } else {
      throw Exception("Échec du chargement de l'historique: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Erreur dans getHistorique: $e');
    rethrow;
  }
}

  // Nombre d'absences (si l'endpoint existe dans votre backend)
  Future<int> getNombreAbsences(String employeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/absences/$employeId'));

      if (response.statusCode == 200) {
        final dynamic absencesData = json.decode(response.body);
        
        if (absencesData is int) return absencesData;
        if (absencesData is Map && absencesData.containsKey('absences')) {
          return absencesData['absences'] as int? ?? 0;
        }
        if (absencesData is List) return absencesData.length;
        
        return 0;
      } else {
        print('Statut HTTP ${response.statusCode} - ${response.body}');
        return 0;
      }
    } catch (e) {
      print('Erreur dans getNombreAbsences: $e');
      return 0;
    }
  }

  // Nombre d'employés présents aujourd'hui
  Future<int> getNombreEmployesPresentAujourdhui() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/presences-aujourdhui'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as int;
      } else {
        throw Exception('Erreur lors de la récupération des présences');
      }
    } catch (e) {
      print('Erreur: $e');
      return 0;
    }
  }

  // Nombre d'employés absents aujourd'hui
  Future<int> getNombreEmployesAbsentAujourdhui() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/absences/aujourdhui'),
      );
      
      print('Réponse API getNombreEmployesAbsentAujourdhui: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['absences'] as int;
      } else {
        throw Exception('Erreur lors de la récupération des absences: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getNombreEmployesAbsentAujourdhui: $e');
      return 0;
    }
  }
}