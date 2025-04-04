import 'package:http/http.dart' as http;
import 'dart:convert';

class DemandeService {
  final String baseUrl = 'http://localhost:3000';  // Remplacez par l'URL de votre API

  Future<bool> createDemande(Map<String, dynamic> demandeData) async {
    final url = Uri.parse('$baseUrl/demande');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(demandeData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // Log de l'erreur pour obtenir plus de détails
        print('Erreur lors de l\'envoi de la demande: ${response.statusCode}');
        print('Réponse du serveur: ${response.body}');
        return false;
      }
    } catch (e) {
      // Log des erreurs réseau
      print('Erreur lors de l\'envoi de la demande: $e');
      return false;
    }
  }
}
