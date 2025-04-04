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
