import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/demande_service.dart';

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
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy – HH:mm').format(date);
  }

  void _modifierDemandeDialog(Map<String, dynamic> demande) {
    final TextEditingController raisonController =
        TextEditingController(text: demande['raison'] ?? '');
    DateTime dateDebut = DateTime.parse(demande['dateDebut']);
    DateTime? dateFin =
        demande['dateFin'] != null ? DateTime.parse(demande['dateFin']) : null;
        

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier la demande"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: raisonController,
                decoration: const InputDecoration(labelText: 'Raison'),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Date début"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateDebut,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dateDebut = picked);
                },
              ),
              ListTile(
              title: const Text("Date fin"),
              subtitle: Text(
                dateFin != null
                    ? DateFormat('dd/MM/yyyy').format(dateFin!)
                    : 'Non définie',
              ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateFin ?? dateDebut,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dateFin = picked);
                },
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
            onPressed: () async {
              await DemandeService().updateDemande(demande['id'], {
                'dateDebut': dateDebut.toIso8601String(),
                'dateFin': dateFin?.toIso8601String(),
                'raison': raisonController.text,
                'type': demande['type'],
                'userId': demande['employe']['id']
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Demande modifiée !")),
              );
              fetchDemandes();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des demandes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedStatut,
                    onChanged: (value) {
                      if (value != null) filterDemandes(value);
                    },
                    items: const [
                      DropdownMenuItem(value: 'TOUS', child: Text('Toutes les demandes')),
                      DropdownMenuItem(value: 'APPROUVEE', child: Text('Approuvées')),
                      DropdownMenuItem(value: 'REJETEE', child: Text('Rejetées')),
                      DropdownMenuItem(value: 'EN_ATTENTE', child: Text('En attente')),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredDemandes.isEmpty
                      ? const Center(child: Text('Aucune demande trouvée.'))
                      : ListView.builder(
                          itemCount: filteredDemandes.length,
                          itemBuilder: (context, index) {
                            final demande = filteredDemandes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_note, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            demande['type'].toString().toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text('Début : ${formatDate(demande['dateDebut'])}'),
                                    if (demande['dateFin'] != null)
                                      Text('Fin : ${formatDate(demande['dateFin'])}'),
                                    Text('Statut : ${demande['statut']}'),
                                    if (demande['raison'] != null &&
                                        demande['raison'].toString().isNotEmpty)
                                      Text(
                                        'Raison : ${demande['raison']}',
                                        style: const TextStyle(fontStyle: FontStyle.italic),
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
                                            icon: const Icon(Icons.edit, color: Colors.orange),
                                            label: const Text(
                                              'Modifier',
                                              style: TextStyle(color: Colors.orange),
                                            ),
                                          ),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirmer'),
                                                content: const Text(
                                                    'Voulez-vous vraiment supprimer cette demande ?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context, false),
                                                    child: const Text('Annuler'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context, true),
                                                    child: const Text('Supprimer'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                final service = DemandeService();
                                                await service.supprimerDemande(
                                                    demande['id'], widget.employeId);
                                                fetchDemandes();
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Erreur lors de la suppression : $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.delete, color: Colors.red),
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
              ],
            ),
    );
  }
}
