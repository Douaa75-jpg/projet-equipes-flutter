import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/chef_equipe_service.dart';
import '../screens/layoutt/chef_layout.dart';

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

      final employeInfo =
          await _chefEquipeService.getEmployeInfo(widget.employeId);

      if (employeInfo != null) {
        setState(() {
          _nom = employeInfo['nom'] ?? '';
          _prenom = employeInfo['prenom'] ?? '';
          _email = employeInfo['email'] ?? '';
          _matricule = employeInfo['matricule'] ?? '';
          _dateNaissance = employeInfo['datedenaissance'] != null
              ? DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(employeInfo['datedenaissance']))
              : '';
        });
      }

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
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
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
                if (_selectedDateRange != null)
                  pw.Row(
                    children: [
                      pw.Text('Période: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - '
                          '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Text('Historique des Pointages',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                _pointages.isEmpty
                    ? pw.Text('Aucun pointage trouvé')
                    : pw.Table.fromTextArray(
                        context: context,
                        border: pw.TableBorder.all(),
                        headerStyle:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.grey300),
                        headers: ['Date', 'Type', 'Heure', 'Statut'],
                        data: _pointages.map((pointage) => [
                              DateFormat('dd/MM/yyyy').format(DateTime.parse(
                                  pointage['date'] ?? DateTime.now().toString())),
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
    return ChefLayout(
      title: 'Historique de Pointage',
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
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
                  color: const Color(0xFF8B0000),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPointageHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF8B0000)),
                onPressed: _generateAndExportPDF,
                tooltip: 'Exporter en PDF',
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Color(0xFF8B0000)),
                onPressed: () => _selectDateRange(context),
                tooltip: 'Choisir une période',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF8B0000)),
                onPressed: _loadPointageHistory,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                                color: const Color(0xFF8B0000),
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
                                  color: const Color(0xFF8B0000),
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
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Période: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                          style: TextStyle(
                            color: const Color(0xFF8B0000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        'Historique des Pointages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B0000),
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
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DataTable(
                                    columnSpacing: 24,
                                    horizontalMargin: 16,
                                    headingRowColor:
                                        MaterialStateProperty.resolveWith<Color>(
                                      (states) => Colors.blue.shade50,
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: Container(
                                          width: constraints.maxWidth * 0.25,
                                          child: Center(
                                            child: Text(
                                              'Date',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF8B0000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: constraints.maxWidth * 0.25,
                                          child: Center(
                                            child: Text(
                                              'Type',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF8B0000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: constraints.maxWidth * 0.25,
                                          child: Center(
                                            child: Text(
                                              'Heure',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF8B0000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: constraints.maxWidth * 0.25,
                                          child: Center(
                                            child: Text(
                                              'Statut',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF8B0000),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: _pointages.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final pointage = entry.value;
                                      final isAbsent =
                                          (pointage['statut'] ?? 'Présent') == 'Absent';
                                      
                                      return DataRow(
                                        color: MaterialStateProperty.resolveWith<Color>(
                                          (states) => index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                                        ),
                                        cells: [
                                          DataCell(
                                            Center(
                                              child: Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                  DateTime.parse(pointage['date'] ?? DateTime.now().toString())),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(
                                                pointage['typeLibelle'] ?? pointage['type'] ?? '',
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(pointage['heure'] ?? ''),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Container(
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
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
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