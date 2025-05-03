import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/demande_service.dart';
import '../layoutt/employee_layout.dart';
import '../../services/notification_service.dart';

class HistoriqueDemandesPage extends StatefulWidget {
  final String employeId;

  const HistoriqueDemandesPage({super.key, required this.employeId});

  @override
  State<HistoriqueDemandesPage> createState() => _HistoriqueDemandesPageState();
}

class _HistoriqueDemandesPageState extends State<HistoriqueDemandesPage> {
  List<dynamic> allDemandes = [];
  List<dynamic> filteredDemandes = [];
  bool isLoading = true;
  String selectedStatut = 'TOUS';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    fetchDemandes();
  }

  Future<void> fetchDemandes() async {
    try {
      final service = DemandeService();
      final demandes = await service.getAllDemandes();
      final employeDemandes =
          demandes.where((d) => d['employe']['id'] == widget.employeId).toList();
      setState(() {
        allDemandes = employeDemandes;
        filteredDemandes = employeDemandes;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des demandes: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des demandes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void filterDemandes(String statut) {
    setState(() {
      selectedStatut = statut;
      if (statut == 'TOUS') {
        filteredDemandes = allDemandes;
      } else {
        filteredDemandes = allDemandes.where((d) => d['statut'] == statut).toList();
      }
    });
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy – HH:mm').format(date);
    } catch (e) {
      return dateStr; // Retourne la chaîne originale en cas d'erreur de parsing
    }
  }

  Color getStatusColor(String statut) {
    switch (statut) {
      case 'APPROUVEE':
        return Colors.green;
      case 'REJETEE':
        return Colors.red;
      case 'EN_ATTENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _modifierDemandeDialog(Map<String, dynamic> demande) async {
  final TextEditingController raisonController =
      TextEditingController(text: demande['raison'] ?? '');
  DateTime dateDebut = DateTime.parse(demande['dateDebut']);
  DateTime? dateFin =
      demande['dateFin'] != null ? DateTime.parse(demande['dateFin']) : null;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text("Modifier la demande"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: raisonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text("Date début"),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateDebut,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != dateDebut) {
                      setState(() => dateDebut = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text("Date fin"),
                  subtitle: Text(
                    dateFin != null
                        ? DateFormat('dd/MM/yyyy').format(dateFin!)
                        : 'Non définie',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFin ?? dateDebut,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dateFin = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
              ),
              onPressed: () {
                if (dateFin != null && dateFin!.isBefore(dateDebut)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("La date de fin doit être après la date de début"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        );
      },
    ),
  );

   if (result == true) {
    try {
      final updatedData = {
        'dateDebut': dateDebut.toIso8601String(),
        'dateFin': dateFin?.toIso8601String(),
        'raison': raisonController.text,
        'type': demande['type'],
        'userId': widget.employeId, // Ajouter le userId ici
      };

      final service = DemandeService();
      final success = await service.updateDemande(demande['id'], updatedData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande modifiée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchDemandes();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Échec de la modification de la demande"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la modification: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

  Future<void> _supprimerDemande(String demandeId) async {
  try {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette demande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = DemandeService();
      await service.supprimerDemande(demandeId, widget.employeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande supprimée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchDemandes();
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      title: 'Historique des Demandes',
      notificationService: _notificationService,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButton<String>(
                        value: selectedStatut,
                        isExpanded: true,
                        underline: const SizedBox(),
                        onChanged: (value) {
                          if (value != null) filterDemandes(value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'TOUS',
                            child: Text('Toutes les demandes'),
                          ),
                          DropdownMenuItem(
                            value: 'APPROUVEE',
                            child: Text('Approuvées'),
                          ),
                          DropdownMenuItem(
                            value: 'REJETEE',
                            child: Text('Rejetées'),
                          ),
                          DropdownMenuItem(
                            value: 'EN_ATTENTE',
                            child: Text('En attente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredDemandes.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune demande trouvée.',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchDemandes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filteredDemandes.length,
                            itemBuilder: (context, index) {
                              final demande = filteredDemandes[index];
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
                                            demande['type']
                                                .toString()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          Chip(
                                            backgroundColor:
                                                getStatusColor(demande['statut'])
                                                    .withOpacity(0.2),
                                            label: Text(
                                              demande['statut'],
                                              style: TextStyle(
                                                color:
                                                    getStatusColor(demande['statut']),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Début: ${formatDate(demande['dateDebut'])}',
                                            style:
                                                const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      if (demande['dateFin'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Fin: ${formatDate(demande['dateFin'])}',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (demande['raison'] != null &&
                                          demande['raison'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: Text(
                                            'Raison: ${demande['raison']}',
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (demande['statut'] == 'EN_ATTENTE')
                                            TextButton.icon(
                                              onPressed: () {
                                                _modifierDemandeDialog(demande);
                                              },
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.orange),
                                              label: const Text(
                                                'Modifier',
                                                style:
                                                    TextStyle(color: Colors.orange),
                                              ),
                                            ),
                                          const SizedBox(width: 10),
                                          TextButton.icon(
                                            onPressed: () async {
                                              await _supprimerDemande(demande['id']);
                                            },
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            label: const Text(
                                              'Supprimer',
                                              style: TextStyle(color: Colors.red),
                                            ),
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
                ),
              ],
            ),
    );
  }
}