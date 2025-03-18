import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeService {
  final String baseUrl = 'http://localhost:3000'; // Remplacez par votre URL API

  // Fonction pour récupérer les employés d'un responsable
  Future<List<dynamic>> getEmployesByResponsable(String responsableId) async {
    final url = Uri.parse('$baseUrl/employe/responsable/$responsableId/employes');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Si la requête réussie, parse la réponse JSON
        return json.decode(response.body);
      } else {
        throw Exception('Échec de la récupération des employés');
      }
    } catch (error) {
      rethrow;
    }
  }
}
