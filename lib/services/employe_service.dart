import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class EmployeService extends GetxController {
  final String baseUrl = 'http://localhost:3000/employes';
  final String baseUrlUtilisateur = 'http://localhost:3000/utilisateurs';

  var employees = <Employe>[].obs;
  var chefsEquipe = <Employe>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;


// في Employe_Service.dart
Future<int> getNombreAbsences(String employeId) async {
  try {
    isLoading(true);
    errorMessage('');
    
    final response = await http.get(
      Uri.parse('$baseUrl/$employeId/calculate-absences'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['nbAbsences'] ?? 0;
    } else {
      return 0;
    }
  } catch (e) {
    errorMessage('Erreur lors de la récupération des absences: $e');
    return 0;
  } finally {
    isLoading(false);
  }
}


  // في Employe_Service.dart
Future<Map<String, dynamic>> calculerEtMettreAJourAbsences(String employeId) async {
  try {
    isLoading(true);
    errorMessage('');
    
    final response = await http.get(
      Uri.parse('$baseUrl/$employeId/calculate-absences'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result;
    } else if (response.statusCode == 404) {
      throw Exception('Employé non trouvé');
    } else if (response.statusCode == 500) {
      throw Exception('Erreur serveur lors du calcul des absences');
    } else {
      throw Exception('Erreur inattendue: ${response.statusCode}');
    }
  } catch (e) {
    errorMessage('Erreur lors du calcul des absences: $e');
    rethrow;
  } finally {
    isLoading(false);
  }
}

  // Récupérer la liste des employés avec leurs responsables
  Future<void> fetchEmployees() async {
    try {
      isLoading(true);
      errorMessage('');
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        employees.assignAll(data.map((item) => Employe.fromJson(item)).toList());
      } else {
        throw Exception('Échec de récupération des employés');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Récupérer la liste des chefs d'équipe
  Future<void> fetchChefsEquipe() async {
    try {
      isLoading(true);
      errorMessage('');
      final response = await http.get(
        Uri.parse('$baseUrlUtilisateur/chefs-equipe'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        chefsEquipe.assignAll(data.map((e) => Employe.fromChefJson(e)).toList());
      } else {
        throw Exception(
            'Failed to load chefs d\'équipe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Assigner un responsable à un employé
  Future<void> assignerResponsable(String employeId, String? chefId) async {
    try {
      isLoading(true);
      errorMessage('');
      
      if (employeId.isEmpty) {
        throw Exception('ID employé manquant');
      }

      final response = await http.patch(
        Uri.parse('$baseUrlUtilisateur/$employeId/assigner-responsable'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'responsableId': chefId}),
      );

      if (response.statusCode == 200) {
        // Rafraîchir la liste des employés après modification
        await fetchEmployees();
      } else if (response.statusCode == 404) {
        throw Exception('Employé ou responsable non trouvé');
      } else {
        throw Exception(
            'Échec de l\'assignation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Supprimer un employé
  Future<void> deleteEmployee(String id) async {
    try {
      isLoading(true);
      errorMessage('');
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Retirer l'employé de la liste observable
        employees.removeWhere((employe) => employe.id == id);
      } else if (response.statusCode == 404) {
        throw Exception('Employé non trouvé');
      } else if (response.statusCode == 500) {
        throw Exception('Erreur interne du serveur');
      } else {
        throw Exception('Échec de la suppression de l\'employé: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Mettre à jour un employé
  Future<void> updateEmployee(String id, Map<String, dynamic> updateData) async {
    try {
      isLoading(true);
      errorMessage('');
      
      if (updateData['dateDeNaissance'] != null && updateData['dateDeNaissance'] is DateTime) {
        updateData['dateDeNaissance'] = updateData['dateDeNaissance'].toIso8601String();
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        // Rafraîchir la liste des employés après modification
        await fetchEmployees();
      } else if (response.statusCode == 404) {
        throw Exception('Employé non trouvé');
      } else if (response.statusCode == 400) {
        throw Exception('Données invalides: ${response.body}');
      } else {
        throw Exception('Échec de la mise à jour: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
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
  final int heuresSupp; // Ajoutez ce champ
  final int heuresTravail; // Ajoutez ce champ
  final int soldeConges; // Ajoutez ce champ
  final int nbAbsences; // Ajoutez ce champ
  final Responsable? responsable;

  Employe({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.matricule,
    required this.datedenaissance,
    required this.heuresSupp,
    required this.heuresTravail,
    required this.soldeConges,
    required this.nbAbsences,
    this.responsable,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      id: json['id'] ?? json['_id'] ?? '',
      nom: json['utilisateur']['nom'] ?? '',
      prenom: json['utilisateur']['prenom'] ?? '',
      email: json['utilisateur']['email'] ?? '',
      matricule: json['utilisateur']['matricule'] ?? '',
      datedenaissance: json['utilisateur']['datedenaissance']?.toString() ?? '',
      heuresSupp: json['heuresSupp'] ?? 0,
      heuresTravail: json['heuresTravail'] ?? 0,
      soldeConges: json['soldeConges'] ?? 0,
      nbAbsences: json['nbAbsences'] ?? 0,
      responsable: json['responsable'] != null
          ? Responsable.fromJson(json['responsable'])
          : null,
    );
  }

  factory Employe.fromChefJson(Map<String, dynamic> json) {
    return Employe(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      matricule: json['matricule'] ?? '',
      datedenaissance: json['datedenaissance']?.toString() ?? '',
       heuresSupp: 0,
      heuresTravail: 0,
      soldeConges: 0,
      nbAbsences: 0,
      responsable: null,
    );
  }
}

class Responsable {
  final String id;
  final String nom;
  final String prenom;

  Responsable({
    required this.id,
    required this.nom,
    required this.prenom,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['utilisateur']['nom'] ?? 'Inconnu',
      prenom: json['utilisateur']['prenom'] ?? 'Inconnu',
    );
  }
}