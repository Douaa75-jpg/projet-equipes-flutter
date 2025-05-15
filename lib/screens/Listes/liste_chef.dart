import 'package:flutter/material.dart';
import 'package:gestion_equipe_flutter/services/RH_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:gestion_equipe_flutter/screens/layoutt/rh_layout.dart';
import 'package:gestion_equipe_flutter/services/notification_service.dart';

class ListeChefScreen extends StatefulWidget {
  final NotificationService notificationService;
  
  const ListeChefScreen({
    super.key,
    required this.notificationService,
  });

  @override
  State<ListeChefScreen> createState() => _ListeChefScreenState();
}

class _ListeChefScreenState extends State<ListeChefScreen> {
  final RhService _rhService = RhService();
  List<Responsable> _responsables = [];
  List<Responsable> _filteredResponsables = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchResponsables();
  }

  Future<void> _fetchResponsables() async {
    try {
      final responsables = await _rhService.getResponsables();
      setState(() {
        _responsables = responsables;
        _filteredResponsables = responsables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors du chargement des responsables: $e')),
      );
    }
  }

  void _filterResponsables(String query) {
    setState(() {
      _searchQuery = query;
      _filteredResponsables = _responsables.where((responsable) {
        final nom = responsable.nom.toLowerCase();
        final prenom = responsable.prenom.toLowerCase();
        final email = responsable.email.toLowerCase();
        final matricule = responsable.matricule?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return nom.contains(searchLower) ||
            prenom.contains(searchLower) ||
            email.contains(searchLower) ||
            matricule.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _exportTeamPdf(Responsable responsable) async {
    final pdf = pw.Document();
    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    final employees = await _rhService.getEmployees();
    final teamEmployees =
        employees.where((e) => e.responsable?.id == responsable.id).toList();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(logo, width: 100, height: 100),
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Équipe de ${responsable.prenom} ${responsable.nom}',
                  style: pw.TextStyle(
                    color: PdfColors.red800,
                    fontSize: 24,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red200, width: 1),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                padding: pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Chef d\'équipe',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${responsable.prenom} ${responsable.nom}'),
                    pw.Text('Email: ${responsable.email}'),
                    pw.Text('Matricule: ${responsable.matricule ?? 'N/A'}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Membres de l\'équipe (${teamEmployees.length})',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Nom', 'Prénom', 'Email'],
                data: teamEmployees
                    .map((e) => [e.nom, e.prenom, e.email])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.red700,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logo, width: 100, height: 100),
              pw.Header(level: 0, text: 'Liste des Chefs d\'Équipe'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: [
                  ['Nom', 'Prénom', 'Email', 'Matricule', 'Date de naissance'],
                  ..._filteredResponsables.map((r) => [
                        r.nom,
                        r.prenom,
                        r.email,
                        r.matricule ?? 'N/A',
                        r.datedenaissance != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(r.datedenaissance!))
                            : 'N/A'
                      ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  void _showAddResponsableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un Responsable'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'Nom')),
              TextField(decoration: InputDecoration(labelText: 'Prénom')),
              TextField(decoration: InputDecoration(labelText: 'Email')),
              TextField(decoration: InputDecoration(labelText: 'Matricule')),
              TextField(
                  decoration: InputDecoration(labelText: 'Date de naissance')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Responsable ajouté avec succès')),
              );
              _fetchResponsables();
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Responsable responsable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Employés sous ${responsable.prenom} ${responsable.nom}'),
        content: FutureBuilder<List<Employe>>(
          future: _rhService.getEmployees(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }
            final employees = snapshot.data ?? [];
            final filteredEmployees = employees
                .where((e) => e.responsable?.id == responsable.id)
                .toList();

            if (filteredEmployees.isEmpty) {
              return Text('Aucun employé sous ce responsable');
            }

            return SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Prénom')),
                  DataColumn(label: Text('Email')),
                ],
                rows: filteredEmployees.map((emp) {
                  return DataRow(cells: [
                    DataCell(Text(emp.nom)),
                    DataCell(Text(emp.prenom)),
                    DataCell(Text(emp.email)),
                  ]);
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => _exportTeamPdf(responsable),
            child: Text('Exporter en PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RhLayout(
      title: 'Liste des Chefs d\'Équipe',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher un chef d\'équipe',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _filterResponsables('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterResponsables,
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: _exportToPdf,
                  tooltip: 'Exporter en PDF',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _showAddResponsableDialog,
                  child: Icon(Icons.add),
                  tooltip: 'Ajouter Responsable',
                  mini: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredResponsables.isEmpty
                    ? Center(
                        child: Text(_searchQuery.isEmpty
                            ? 'Aucun chef d\'équipe disponible'
                            : 'Aucun résultat trouvé'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Prénom')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Matricule')),
                            DataColumn(label: Text('Date de naissance')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredResponsables.map((responsable) {
                            return DataRow(cells: [
                              DataCell(Text(responsable.nom)),
                              DataCell(Text(responsable.prenom)),
                              DataCell(Text(responsable.email)),
                              DataCell(Text(responsable.matricule ?? 'N/A')),
                              DataCell(Text(responsable.datedenaissance != null
                                  ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.parse(
                                          responsable.datedenaissance!))
                                  : 'N/A')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.group),
                                    onPressed: () => _showEmployeeDetails(
                                        context, responsable),
                                    tooltip: 'Voir les employés',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.picture_as_pdf,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _exportTeamPdf(responsable),
                                    tooltip: 'Exporter l\'équipe en PDF',
                                  ),
                                  IconButton(
                                    icon:
                                        Icon(Icons.search, color: Colors.blue),
                                    onPressed: () => _showDetails(responsable),
                                    tooltip: 'Détails',
                                  ),
                                  IconButton(
                                    icon:
                                        Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () =>
                                        _editResponsable(responsable),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        _deleteResponsable(responsable),
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetails(Responsable responsable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du chef d\'équipe'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom: ${responsable.nom}'),
              Text('Prénom: ${responsable.prenom}'),
              Text('Email: ${responsable.email}'),
              Text('Matricule: ${responsable.matricule ?? 'N/A'}'),
              Text(
                  'Date de naissance: ${responsable.datedenaissance != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(responsable.datedenaissance!)) : 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _editResponsable(Responsable responsable) async {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: responsable.nom);
    final prenomController = TextEditingController(text: responsable.prenom);
    final emailController = TextEditingController(text: responsable.email);
    final matriculeController =
        TextEditingController(text: responsable.matricule ?? '');
    final dateNaissanceController = TextEditingController(
        text: responsable.datedenaissance != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(responsable.datedenaissance!)) : '');
    String? selectedType = responsable.typeResponsable;

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier Responsable'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom*'),
                  controller: nomController,
                  validator: (value) =>
                      value!.isEmpty ? 'Ce champ est obligatoire' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Prénom*'),
                  controller: prenomController,
                  validator: (value) =>
                      value!.isEmpty ? 'Ce champ est obligatoire' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email*'),
                  controller: emailController,
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Email invalide'
                      : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Matricule'),
                  controller: matriculeController,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date de naissance (AAAA-MM-JJ)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: dateNaissanceController,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      dateNaissanceController.text =
                          DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(
                      value: 'CHEF_EQUIPE',
                      child: Text('Chef d\'équipe'),
                    ),
                    DropdownMenuItem(
                      value: 'CHEF_DEPARTEMENT',
                      child: Text('Chef de département'),
                    ),
                  ],
                  onChanged: (value) => selectedType = value,
                  decoration:
                      InputDecoration(labelText: 'Type de responsable*'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification en cours...')),
      );

      try {
        final updatedData = {
          "nom": nomController.text,
          "prenom": prenomController.text,
          "email": emailController.text,
          "matricule": matriculeController.text.isEmpty
              ? null
              : matriculeController.text,
          "datedenaissance": dateNaissanceController.text.isEmpty
              ? null
              : dateNaissanceController.text,
          "typeResponsable": selectedType,
        };

        await _rhService.updateResponsable(responsable.id, updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Responsable modifié avec succès')),
        );
        _fetchResponsables();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification: $e')),
        );
      }
    }
  }

  void _deleteResponsable(Responsable responsable) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Êtes-vous sûr de vouloir supprimer ${responsable.prenom} ${responsable.nom}?'),
            SizedBox(height: 10),
            FutureBuilder<List<Employe>>(
              future: _rhService.getEmployees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox();
                }
                if (snapshot.hasError) {
                  return Text('Erreur lors de la vérification des employés',
                      style: TextStyle(color: Colors.red));
                }

                final employees = snapshot.data ?? [];
                final teamEmployees = employees
                    .where((e) => e.responsable?.id == responsable.id)
                    .toList();

                if (teamEmployees.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Attention: Ce responsable a ${teamEmployees.length} employé(s) sous sa supervision!',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression en cours...')),
      );

      try {
        await _rhService.deleteResponsable(responsable.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Responsable supprimé avec succès')),
        );
        _fetchResponsables();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }
}