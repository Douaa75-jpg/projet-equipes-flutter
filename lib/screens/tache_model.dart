class Tache {
  final String id;
  final String titre;
  final String description;
  final String statut;
  final String dateLimite;

  Tache({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.dateLimite,
  });
  

  factory Tache.fromJson(Map<String, dynamic> json) {
    return Tache(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'],
      dateLimite: json['dateLimite'],
    );
  }

  
}
