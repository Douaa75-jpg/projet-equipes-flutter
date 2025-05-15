import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tache_service.dart';
import '../screens/tache_model.dart';
import '../services/notification_service.dart';
import 'layoutt/employee_layout.dart';

class TacheScreen extends StatefulWidget {
  final String employeId;

  const TacheScreen({Key? key, required this.employeId}) : super(key: key);

  @override
  _TacheScreenState createState() => _TacheScreenState();
}

class _TacheScreenState extends State<TacheScreen> {
  List<Tache> taches = [];
  bool isLoading = true;
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateLimiteController = TextEditingController();
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _fetchTaches();
    _initializeNotifications();
  }

  void _initializeNotifications() {
   
  }

  Future<void> _fetchTaches() async {
    setState(() => isLoading = true);
    try {
      taches = await TacheService().getTachesForEmploye(widget.employeId);
    } catch (e) {
      _showSnackBar('Erreur lors de la récupération des tâches', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  Future<void> _addTache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter une nouvelle tâche"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                    );
                    if (selectedTime != null) {
                      final combinedDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      _dateLimiteController.text = 
                          DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
                    }
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateLimiteController,
                    decoration: const InputDecoration(
                      labelText: "Date Limite",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () async {
              try {
                await TacheService().createTache(
                  _titreController.text,
                  _descriptionController.text,
                  formatDate(_dateLimiteController.text),
                  widget.employeId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _fetchTaches();
                  _showSnackBar('Nouvelle tâche ajoutée', Colors.green);
                  _clearControllers();
                }
              } catch (e) {
                _showSnackBar('Erreur: $e', Colors.red);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTache(String tacheId) async {
    try {
      await TacheService().deleteTache(tacheId);
      _fetchTaches();
      _showSnackBar('Tâche supprimée avec succès', Colors.green);
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression', Colors.red);
    }
  }

  Future<void> _updateTache(Tache tache) async {
    _titreController.text = tache.titre;
    _descriptionController.text = tache.description;
    _dateLimiteController.text = tache.dateLimite;
    String? _selectedStatut = tache.statut;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mettre à jour la tâche"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatut,
                items: ['A_FAIRE', 'EN_COURS', 'TERMINEE']
                    .map((statut) => DropdownMenuItem(
                          value: statut,
                          child: Text(statut),
                        ))
                    .toList(),
                onChanged: (value) => _selectedStatut = value,
                decoration: const InputDecoration(
                  labelText: "Statut",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                    );
                    if (selectedTime != null) {
                      final combinedDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      _dateLimiteController.text = 
                          DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
                    }
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateLimiteController,
                    decoration: const InputDecoration(
                      labelText: "Date Limite",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () async {
              try {
                await TacheService().updateTache(
                  tache.id,
                  _titreController.text,
                  _descriptionController.text,
                  formatDate(_dateLimiteController.text),
                  statut: _selectedStatut ?? 'A_FAIRE',
                );
                if (mounted) {
                  Navigator.pop(context);
                  _fetchTaches();
                  _showSnackBar('Tâche mise à jour', Colors.green);
                  _clearControllers();
                }
              } catch (e) {
                _showSnackBar('Erreur: $e', Colors.red);
              }
            },
            child: const Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _titreController.clear();
    _descriptionController.clear();
    _dateLimiteController.clear();
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      title: 'Mes Tâches',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une tâche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _addTache,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : taches.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune tâche trouvée',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: taches.length,
                        itemBuilder: (context, index) {
                          final tache = taches[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tache.titre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Chip(
                                        backgroundColor:
                                            _getStatusColor(tache.statut)
                                                .withOpacity(0.2),
                                        label: Text(
                                          tache.statut,
                                          style: TextStyle(
                                            color: _getStatusColor(tache.statut),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(tache.description),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Date limite: ${formatDate(tache.dateLimite)}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _updateTache(tache),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteTache(tache.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dateLimiteController.dispose();
    super.dispose();
  }
}