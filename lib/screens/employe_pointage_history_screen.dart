import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ajouté pour rootBundle
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/chef_equipe_service.dart';

class EmployePointageHistoryScreen extends StatefulWidget {
  final String employeId;
  final String chefId;

  const EmployePointageHistoryScreen({
    Key? key, 
    required this.employeId,
    required this.chefId,
  }) : super(key: key);

  @override
  _EmployePointageHistoryScreenState createState() =>
      _EmployePointageHistoryScreenState();
}

class _EmployePointageHistoryScreenState
    extends State<EmployePointageHistoryScreen> {
  final ChefEquipeService _chefEquipeService = ChefEquipeService();
  List<dynamic> _pointages = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTimeRange? _selectedDateRange;
  
  // Informations de l'employé
  String _nom = '';
  String _prenom = '';
  String _email = '';
  String _matricule = '';
  String _dateNaissance = '';

  @override
  void initState() {
    super.initState();
    _loadPointageHistory();
  }

  Future<void> _loadPointageHistory() async {
    try {
      setState(() => _isLoading = true);
      
      // Charger les informations de l'employé
      final employeInfo = await _chefEquipeService.getEmployeInfo(widget.employeId);
      
      if (employeInfo != null) {
        setState(() {
          _nom = employeInfo['nom'] ?? '';
          _prenom = employeInfo['prenom'] ?? '';
          _email = employeInfo['email'] ?? '';
          _matricule = employeInfo['matricule'] ?? '';
          _dateNaissance = employeInfo['datedenaissance'] != null 
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(employeInfo['datedenaissance']))
            : '';
        });
      }

      // Charger l'historique de pointage
      final history = await _chefEquipeService.getHistoriqueEquipe(
        widget.chefId,
        employeId: widget.employeId,
      );

      if (history != null && history['items'] != null) {
        setState(() {
          _pointages = List.from(history['items']);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Aucune donnée de pointage disponible';
          _isLoading = false;
          _pointages = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
        _pointages = [];
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      await _loadPointageHistoryWithDates();
    }
  }

  Future<void> _loadPointageHistoryWithDates() async {
    if (_selectedDateRange == null) return;

    try {
      setState(() => _isLoading = true);
      
      final history = await _chefEquipeService.getHistoriqueEquipe(
        widget.chefId,
        employeId: widget.employeId,
        dateDebut: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start),
        dateFin: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end),
      );

      if (history != null && history['items'] != null) {
        setState(() {
          _pointages = List.from(history['items']);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Aucune donnée pour cette période';
          _isLoading = false;
          _pointages = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
        _pointages = [];
      });
    }
  }

   Future<void> _generateAndExportPDF() async {
    try {
      final pdf = pw.Document();

      // En-tête du PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Historique de Pointage',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Informations employé
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  padding: pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Informations Employé',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildPdfInfoRow('Nom', _nom),
                      _buildPdfInfoRow('Prénom', _prenom),
                      _buildPdfInfoRow('Matricule', _matricule),
                      _buildPdfInfoRow('Email', _email),
                      _buildPdfInfoRow('Date Naissance', _dateNaissance),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Période sélectionnée
                if (_selectedDateRange != null)
                  pw.Row(
                    children: [
                      pw.Text('Période: ', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - '
                        '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                      ),
                    ],
                  ),
                
                pw.SizedBox(height: 20),
                
                // Tableau des pointages
                pw.Text('Historique des Pointages',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                _pointages.isEmpty
                  ? pw.Text('Aucun pointage trouvé')
                  : pw.Table.fromTextArray(
                      context: context,
                      border: pw.TableBorder.all(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                      headers: ['Date', 'Type', 'Heure', 'Statut'],
                      data: _pointages.map((pointage) => [
                        DateFormat('dd/MM/yyyy').format(
                          DateTime.parse(pointage['date'] ?? DateTime.now().toString())),
                        pointage['typeLibelle'] ?? pointage['type'] ?? '',
                        pointage['heure'] ?? '',
                        pointage['statut'] ?? 'Présent',
                      ]).toList(),
                    ),
              ],
            );
          },
        ),
      );

      // Impression/export
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            '$label :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(value.isNotEmpty ? value : 'Non renseigné'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de Pointage'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color.fromARGB(255, 157, 18, 18), Color.fromARGB(255, 204, 23, 23)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateAndExportPDF,
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Choisir une période',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPointageHistory,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Chargement en cours...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 50,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 157, 18, 18),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPointageHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 157, 18, 18), // Changé de primary à backgroundColor
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Carte d'information de l'employé
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informations du Employé',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 157, 18, 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${widget.employeId}',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 192, 21, 21),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nom', _nom),
                  _buildInfoRow('Prénom', _prenom),
                  _buildInfoRow('Matricule', _matricule),
                  _buildInfoRow('Email', _email),
                  _buildInfoRow('Date de naissance', _dateNaissance),
                ],
              ),
            ),
          ),
          
          // Période sélectionnée
          if (_selectedDateRange != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Période: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 192, 21, 21),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Titre de la section historique
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  'Historique des Pointages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 192, 21, 21),
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_pointages.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tableau des pointages
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _pointages.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun pointage trouvé',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        headingRowColor: MaterialStateProperty.resolveWith<Color>(
                          (states) => Colors.blue.shade50,
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 157, 18, 18),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Type',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 157, 18, 18),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Heure',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 157, 18, 18),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Statut',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 157, 18, 18),
                              ),
                            ),
                          ),
                        ],
                        rows: _pointages.map((pointage) {
                          final isAbsent = (pointage['statut'] ?? 'Présent') == 'Absent';
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(pointage['date'] ?? DateTime.now().toString())),
                              )),
                              DataCell(Text(pointage['typeLibelle'] ?? pointage['type'] ?? '')),
                              DataCell(Text(pointage['heure'] ?? '')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAbsent
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isAbsent
                                          ? Colors.red.shade200
                                          : Colors.green.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    pointage['statut'] ?? 'Présent',
                                    style: TextStyle(
                                      color: isAbsent ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}