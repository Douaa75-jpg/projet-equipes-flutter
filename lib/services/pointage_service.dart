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

Future<int> getNombreAbsences(String employeId) async {
  final response = await http.get(Uri.parse('$baseUrl/absences/$employeId'));

  if (response.statusCode == 200) {
    return json.decode(response.body)['nombreAbsences'];
  } else {
    throw Exception('Erreur lors de la récupération des absences');
  }
}


}
