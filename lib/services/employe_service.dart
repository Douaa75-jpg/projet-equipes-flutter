import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeService {
  final String baseUrl = 'http://localhost:3000/employes';

  // Récupérer la liste des employés avec leurs responsables
  Future<List<Employe>> getEmployees() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Employe.fromJson(item)).toList();
    } else {
      throw Exception('Échec de récupération des employés');
    }
  }

   // ✅ supprimer employe
  Future<bool> deleteEmployee(String id) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/$id'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    return true;
  } else if (response.statusCode == 404) {
    throw Exception('Employé non trouvé');
  } else if (response.statusCode == 500) {
    throw Exception('Erreur interne du serveur');
  } else {
    throw Exception('Échec de la suppression de l\'employé: ${response.statusCode}');
  }
}
 // ✅ Mettre à jour un employé
  Future<Employe> updateEmployee(String id, Map<String, dynamic> updateData) async {
     if (updateData['dateDeNaissance'] != null && updateData['dateDeNaissance'] is DateTime) {
    updateData['dateDeNaissance'] = updateData['dateDeNaissance'].toIso8601String();
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return Employe.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Employé non trouvé');
    } else if (response.statusCode == 400) {
      throw Exception('Données invalides: ${response.body}');
    } else {
      throw Exception('Échec de la mise à jour: ${response.statusCode}');
    }
  }
}


// Définition de la classe Employe
class Employe {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String matricule;
  final String datedenaissance;
  final Responsable responsable;

  Employe({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.matricule,
    required this.datedenaissance,
    required this.responsable,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
       id: json['id'] ?? json['_id'] ?? '',
      nom: json['utilisateur']['nom'] ?? '',
      prenom: json['utilisateur']['prenom'] ?? '',
      email: json['utilisateur']['email'] ?? '',
      matricule: json['utilisateur']['matricule'] ?? '',
      datedenaissance: json['utilisateur']['datedenaissance'] ?? '',
      responsable: json['responsable'] != null
          ? Responsable.fromJson(json['responsable'])
          : Responsable(nom: 'Inconnu', prenom: 'Inconnu'),
    );
  }
}

// Définition de la classe Responsable
class Responsable {
  final String nom;
  final String prenom;

  Responsable({
    required this.nom,
    required this.prenom,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      nom: json['utilisateur']['nom'] ?? 'Inconnu',
      prenom: json['utilisateur']['prenom'] ?? 'Inconnu',
    );
  }
}
