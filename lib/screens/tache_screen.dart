import 'package:flutter/material.dart';
import '../services/tache_service.dart';
import '../screens/tache_model.dart';
import 'package:intl/intl.dart';

class TacheScreen extends StatefulWidget {
  final String employeId;

  TacheScreen({required this.employeId});

  @override
  _TacheScreenState createState() => _TacheScreenState();
}

class _TacheScreenState extends State<TacheScreen> {
  List<Tache> taches = [];
  bool isLoading = true;

  

  // Déclaration des contrôleurs
  TextEditingController _titreController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _dateLimiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTaches();
  }


  // Fonction pour récupérer les tâches de l'employé
  Future<void> _fetchTaches() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Appel au service pour récupérer les tâches de l'employé
      taches = await TacheService().getTachesForEmploye(widget.employeId);
    } catch (e) {
      // Affichage d'un message d'erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la récupération des tâches'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

   // Fonction pour formater la date
  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date); // Convertir la chaîne en DateTime
      return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate); // Formater la date
    } catch (e) {
      return date; // Retourner la date telle quelle en cas d'erreur
    }
  }

  // Fonction pour ajouter une nouvelle tâche
Future<void> _addTache() async {
  // فتح نافذة إدخال البيانات
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Ajouter une nouvelle tâche"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titreController,
              decoration: InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            GestureDetector(
              onTap: () async {
                // Sélection de la date
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (selectedDate != null) {
                  // Sélection de l'heure
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                  );

                  if (selectedTime != null) {
                    // Combiner la date et l'heure
                    DateTime combinedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Formater la date et l'heure pour l'affichage
                    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);

                    // Mettre la date formatée dans le contrôleur de texte
                    _dateLimiteController.text = formattedDate;
                  }
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateLimiteController,
                  decoration: InputDecoration(labelText: "Date Limite"),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String formattedDate = formatDate(_dateLimiteController.text);
              
              try {
                // Tentative d'ajout de la tâche
                await TacheService().createTache(
                  _titreController.text,
                  _descriptionController.text,
                  formattedDate,     // La date formatée en 'yyyy-MM-dd HH:mm'
                  widget.employeId, // استخدام employeId الذي تم تمريره في البداية
                );
                Navigator.pop(context); // إغلاق النافذة المنبثقة
                _fetchTaches(); // إعادة تحميل قائمة المهام

                // Affichage d'un SnackBar pour informer que la tâche a été ajoutée
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nouvelle tâche ajoutée'),
                    backgroundColor: Colors.green, // Couleur verte pour succès
                  ),
                );
              } catch (e) {
                // Affichage d'un message d'erreur si une exception est levée
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de l\'ajout de la tâche: $e'),
                    backgroundColor: Colors.red, // Couleur rouge pour erreur
                  ),
                );
              }
            },
            child: Text("Ajouter"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق النافذة بدون إضافة المهمة
            },
            child: Text("Annuler"),
          ),
        ],
      );
    },
  );
}

   // Fonction pour supprimer une tâche
  Future<void> _deleteTache(String tacheId) async {
    try {
      await TacheService().deleteTache(tacheId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Tâche supprimée avec succès'),
        backgroundColor: Colors.green,
      ));
      _fetchTaches(); // Recharger les tâches après suppression
    } catch (e) {
      // Gestion des erreurs lors de la suppression
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la suppression de la tâche'),
        backgroundColor: Colors.red,
      ));
    }
  }

 // Fonction pour mettre à jour une tâche
 Future<void> _updateTache(Tache tache) async {
  // Ouvrir une boîte de dialogue pour entrer les nouvelles données
  showDialog(
    context: context,
    builder: (context) {
      _titreController.text = tache.titre; // Remplir le champ titre
      _descriptionController.text = tache.description; // Remplir le champ description
      _dateLimiteController.text = tache.dateLimite; // Remplir le champ dateLimite
      String? _selectedStatut = tache.statut;

      return AlertDialog(
        title: Text("Mettre à jour la tâche"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titreController,
              decoration: InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            DropdownButtonFormField<String>(
          value: _selectedStatut,
          items: ['A_FAIRE', 'EN_COURS', 'TERMINEE']
              .map((statut) => DropdownMenuItem(
                    value: statut,
                    child: Text(statut),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatut = value;
              });
            }
          },
          decoration: InputDecoration(labelText: "Statut"),
        ),
            GestureDetector(
              onTap: () async {
                // Sélection de la date
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (selectedDate != null) {
                  // Sélection de l'heure
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                  );

                  if (selectedTime != null) {
                    // Combiner la date et l'heure
                    DateTime combinedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Formater la date et l'heure pour l'affichage
                    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);

                    // Mettre la date formatée dans le contrôleur de texte
                    _dateLimiteController.text = formattedDate;
                  }
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateLimiteController,
                  decoration: InputDecoration(labelText: "Date Limite"),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Validation de la date et formatage
              String formattedDate = formatDate(_dateLimiteController.text);

              // Validation si la date est correcte
              if (formattedDate == null || formattedDate.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Date invalide.'),
                  backgroundColor: Colors.red,
                ));
                return;
              }

              // Appeler le service pour mettre à jour la tâche
              try {
                await TacheService().updateTache(
                  tache.id, // L'ID de la tâche à modifier
                  _titreController.text,
                  _descriptionController.text,
                  formattedDate, // Nouvelle date limite formatée
                  statut: _selectedStatut ?? 'A_FAIRE',
                );
                Navigator.pop(context); // Fermer la boîte de dialogue
                _fetchTaches(); // Recharger la liste des tâches

                // Affichage d'un message de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tâche mise à jour avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Affichage d'une erreur en cas de problème
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la mise à jour de la tâche: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("Mettre à jour"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer sans modifier
            },
            child: Text("Annuler"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mes Tâches du Jour"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addTache,
          ),
        ],
      ),
     body: isLoading
    ? Center(
        child: CircularProgressIndicator(), // Affichage de la barre de chargement
      )
    : ListView.builder(
        itemCount: taches.length, // Nombre de tâches à afficher
        itemBuilder: (context, index) {
          final tache = taches[index];
          return Card(
             elevation: 5, 
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
                    title: Text(
                      tache.titre,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tache.description),
                  SizedBox(height: 4),
                  Text(
                    "Statut : ${tache.statut}",
                    style: TextStyle(
                      color: _getStatusColor(tache.statut),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Date limite : ${formatDate(tache.dateLimite)}",
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteTache(tache.id),
              ),
              onTap: () => _updateTache(tache),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'A_FAIRE':
        return Colors.orange;
      case 'EN_COURS':
        return Colors.blue;
      case 'TERMINEE':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}