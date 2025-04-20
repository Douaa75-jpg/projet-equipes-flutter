import 'package:http/http.dart' as http;
import 'dart:convert';

class PointageService {
  final String baseUrl = 'http://localhost:3000/pointages'; // Mets l'URL de ton backend

  Future<Map<String, dynamic>> getPointage(String employeId, String date) async {
    final response = await http.get(Uri.parse('$baseUrl/$employeId?date=$date'));
    print('Réponse API getPointage : ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération du pointage');
    }
  }

  Future<void> enregistrerPointage(Map<String, dynamic> data) async {
  print('Données envoyées pour le pointage : $data');  // Log pour débogage
  final response = await http.post(
    Uri.parse(baseUrl),
    headers: {"Content-Type": "application/json"},
    body: json.encode(data),
  );
  print('Réponse API enregistrerPointage : ${response.body}');
  if (response.statusCode != 201) {
    throw Exception('Échec de l’enregistrement du pointage');
  }
}

 // Enregistrer l'heure de départ
  Future<void> enregistrerHeureDepart(String employeId, String date, String heureDepart) async {
    if (employeId.isEmpty || date.isEmpty || heureDepart.isEmpty) {
      throw Exception('Les paramètres employeId, date et heureDepart sont nécessaires.');
    }
    print('Données envoyées pour l\'heure de départ : { employeId: $employeId, date: $date , heureDepart: $heureDepart}');

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/depart/$employeId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "date": date, // Date du pointage
          "heureDepart": heureDepart, // Heure de départ
        }),
      );

      print('Réponse API enregistrerHeureDepart (${response.statusCode}): ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Échec de l’enregistrement de l\'heure de départ (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de l\'heure de départ: $e');
    }
  }
  Future<Map<String, dynamic>> calculerHeuresTravail(String employeId, String dateDebut, String dateFin) async {
    final response = await http.get(Uri.parse('$baseUrl/calcul-heures?employeId=$employeId&dateDebut=$dateDebut&dateFin=$dateFin'));
    print('Réponse API calculerHeuresTravail : ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du calcul des heures de travail');
    }
  }
  Future<List<dynamic>> getHistorique(String employeId) async {
  final response = await http.get(Uri.parse('$baseUrl/historique/$employeId'));
  print('Réponse API getHistorique : ${response.body}');

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Échec du chargement de l'historique");
  }
}

//nombre d'absence 
Future<int> getNombreAbsences(String employeId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/absences/$employeId'));

    if (response.statusCode == 200) {
      final dynamic absencesData = json.decode(response.body);
      
      // Cas 1: La réponse est directement un nombre (int)
      if (absencesData is int) {
        return absencesData;
      }
      
      // Cas 2: La réponse est un Map avec une propriété 'absences'
      if (absencesData is Map && absencesData.containsKey('absences')) {
        return absencesData['absences'] as int? ?? 0;
      }
      
      // Cas 3: La réponse est une liste (compter les éléments)
      if (absencesData is List) {
        return absencesData.length;
      }
      
      // Si le format n'est pas reconnu
      return 0;
    } else {
      // Pour les autres codes statut, retourner 0 avec un log
      print('Statut HTTP ${response.statusCode} - ${response.body}');
      return 0;
    }
  } catch (e) {
    // Gestion des erreurs de réseau/parsing
    print('Erreur dans getNombreAbsences: $e');
    return 0;
  }
}

//getNombreEmployesPresentAujourdhu
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
    return 0; // نرجع 0 في حالة الخطأ
  }
}

// Récupérer le nombre d'absents aujourd'hui
Future<int> getNombreEmployesAbsentAujourdhui() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/absences/aujourdhui'),
    );
    
    print('Réponse API getNombreEmployesAbsentAujourdhui: ${response.body}');
    
     if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Extrait la valeur numérique du champ 'absences'
      return data['absences'] as int;
    } else {
      throw Exception('Erreur lors de la récupération des absences: ${response.statusCode}');
    }
  } catch (e) {
    print('Erreur dans getNombreEmployesAbsentAujourdhui: $e');
    return 0; // Valeur par défaut en cas d'erreur
  }
}
}
