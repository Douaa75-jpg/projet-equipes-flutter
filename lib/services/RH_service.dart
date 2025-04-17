import 'dart:convert';
import 'package:http/http.dart' as http;

class RhService {
  final String baseUrl = 'http://localhost:3000/utilisateurs';
  final String baseUrlEmployes =
      'http://localhost:3000/employes'; // Cette ligne est correcte
  final String baseUrlResponsables = 'http://localhost:3000/responsables';

  // Fonction pour obtenir le nombre d'employés
  Future<int> getEmployesCount() async {
    final response = await http.get(Uri.parse('$baseUrl/count/employes'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['totalEmployes'];
    } else {
      throw Exception('Échec de récupération des employés');
    }
  }

  // Fonction pour obtenir le nombre de responsables (chefs d'équipe)
  Future<int> getResponsablesCount() async {
    final response = await http.get(Uri.parse('$baseUrl/count/responsables'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['totalResponsables'];
    } else {
      throw Exception('Échec de récupération des responsables');
    }
  }

  // Fonction pour obtenir la liste des responsables
  Future<List<Responsable>> getResponsables() async {
    final response = await http.get(Uri.parse('$baseUrlResponsables'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Responsable.fromJson(item)).toList();
    } else {
      throw Exception('Échec de récupération des responsables');
    }
  }

  // Fonction pour obtenir la liste des employés avec leurs responsables
  Future<List<Employe>> getEmployees() async {
    final response = await http.get(Uri.parse(
        baseUrlEmployes)); // Ici, la variable 'baseUrlEmployes' est utilisée correctement.

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Employe.fromJson(item)).toList();
    } else {
      throw Exception('Échec de récupération des employés');
    }
  }

   // Méthode pour mettre à jour un employé
  Future<Map<String, dynamic>> updateEmployee(String id, Map<String, dynamic> updateData) async {
    final url = Uri.parse('$baseUrlEmployes/$id');
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la mise à jour de l\'employé');
    }
  }

  // Méthode pour supprimer un employé
  Future<Map<String, dynamic>> deleteEmployee(String id) async {
    final url = Uri.parse('$baseUrlEmployes/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la suppression de l\'employé');
    }
  }

  // Méthode pour mettre à jour un responsable
  Future<Map<String, dynamic>> updateResponsable(String id, Map<String, dynamic> updateData) async {
    final url = Uri.parse('$baseUrlResponsables/$id');
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la mise à jour du responsable');
    }
  }

  // Méthode pour supprimer un responsable
  Future<Map<String, dynamic>> deleteResponsable(String id) async {
    final url = Uri.parse('$baseUrlResponsables/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la suppression du responsable');
    }
  }
}


// Définition de la classe Responsable
class Responsable {
  final String nom;
  final String prenom;
  final String email;

  Responsable({
    required this.nom,
    required this.prenom,
    required this.email,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      nom: json['utilisateur']['nom'] ?? 'Inconnu',
      prenom: json['utilisateur']['prenom'] ?? 'Inconnu',
      email: json['utilisateur']['email'] ?? 'Inconnu',
    );
  }
}

// Définition de la classe Employe
class Employe {
  final String nom;
  final String prenom;
  final String email;
  final Responsable responsable;

  Employe({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.responsable,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      nom: json['utilisateur']['nom'] ?? '',
      prenom: json['utilisateur']['prenom'] ?? '',
      email: json['utilisateur']['email'] ?? '',
      responsable: json['responsable'] != null
          ? Responsable.fromJson(json['responsable'])
          : Responsable(nom: 'Inconnu', prenom: 'Inconnu', email: 'Inconnu'),
    );
  }
}
