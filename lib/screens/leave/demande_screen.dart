import 'package:flutter/material.dart';
import 'package:gestion_equipe_flutter/services/demande_service.dart';

class DemandeScreen extends StatefulWidget {
  final String employeId;

  DemandeScreen({required this.employeId});

  @override
  _DemandeScreenState createState() => _DemandeScreenState();
}

class _DemandeScreenState extends State<DemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _typeDemande;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _raison;

  final demandeService = DemandeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Faire une Demande"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _typeDemande,
                onChanged: (String? newValue) {
                  setState(() {
                    _typeDemande = newValue;
                  });
                },
                items: [
                  DropdownMenuItem(value: 'congé', child: Text('Congé')),
                  DropdownMenuItem(value: 'absence', child: Text('Absence')),
                  DropdownMenuItem(value: 'autorisation_sortie', child: Text('Autorisation de sortie')),
                ],
                decoration: InputDecoration(labelText: "Type de Demande"),
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un type de demande';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Raison"),
                onChanged: (value) {
                  setState(() {
                    _raison = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez fournir une raison';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Date de début"),
                onTap: () async {
                  DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (date != null) {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (time != null) {
                      setState(() {
                        _dateDebut = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
                readOnly: true,
                controller: TextEditingController(
                    text: _dateDebut != null ? _dateDebut!.toLocal().toString().split(' ')[0] : ''),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Date de fin (facultative)"),
                onTap: () async {
                  DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (date != null) {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (time != null) {
                      setState(() {
                        _dateFin = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
                readOnly: true,
                controller: TextEditingController(
                    text: _dateFin != null ? _dateFin!.toLocal().toString().split(' ')[0] : ''),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final demande = {
                      'employeId': widget.employeId,
                      'type': _typeDemande?.toLowerCase(),
                      'dateDebut': _dateDebut?.toIso8601String(),
                      'dateFin': _dateFin?.toIso8601String(),
                      'raison': _raison,
                    };
                    final success = await demandeService.createDemande(demande);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Demande soumise avec succès')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de l\'envoi de la demande')),
                      );
                    }
                  }
                },
                child: Text('Soumettre'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
