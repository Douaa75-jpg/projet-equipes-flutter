class Employe {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String matricule;
  final String datedenaissance;
  final Responsable? responsable;

  Employe({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.matricule,
    required this.datedenaissance,
    this.responsable,
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