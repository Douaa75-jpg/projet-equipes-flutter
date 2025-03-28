import 'package:http/http.dart' as http;
import 'dart:convert';

class ResponsableService {
  final String apiUrl = "http://localhost:3000"; // Correction de l'URL

  Future<http.Response> createEmploye(
      String nom, String prenom, String email, String motDePasse) {
    return _postRequest('/employes', {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
    });
  }


  Future<http.Response> createResponsable(String nom, String prenom,
      String email, String motDePasse, String typeResponsable) {
    return _postRequest('/responsables', {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'typeResponsable': typeResponsable
    });
  }

  Future<http.Response> _postRequest(
      String endpoint, Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }
}
