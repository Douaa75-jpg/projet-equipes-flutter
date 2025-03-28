import 'package:http/http.dart' as http;
import 'dart:convert';

class PointageService {
  final String baseUrl = 'http://localhost:3000/pointages'; // Mets l'URL de ton backend

  Future<Map<String, dynamic>> getPointage(String employeId, String date) async {
    final response = await http.get(Uri.parse('$baseUrl/$employeId?date=$date'));
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
  if (response.statusCode != 201) {
    throw Exception('Échec de l’enregistrement du pointage');
  }
}


  Future<Map<String, dynamic>> calculerHeuresTravail(String employeId, String dateDebut, String dateFin) async {
    final response = await http.get(Uri.parse('$baseUrl/calcul-heures?employeId=$employeId&dateDebut=$dateDebut&dateFin=$dateFin'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du calcul des heures de travail');
    }
  }
  Future<List<dynamic>> getHistorique(String employeId) async {
  final response = await http.get(Uri.parse('$baseUrl/historique/$employeId'));

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
