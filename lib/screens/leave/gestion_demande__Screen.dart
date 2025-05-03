import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/demande_service.dart';
import '../../AuthProvider.dart';
import '../layoutt/rh_layout.dart';

class GestionDemandeScreen extends StatefulWidget {
  @override
  _GestionDemandeScreenState createState() => _GestionDemandeScreenState();
}

class _GestionDemandeScreenState extends State<GestionDemandeScreen> {
  final DemandeService _demandeService = DemandeService();
  List<dynamic> _demandes = [];
  bool _isLoading = true;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    try {
      final demandes = await _demandeService.getAllDemandes();
      setState(() {
        _demandes = demandes.where((d) => d['statut'] == 'EN_ATTENTE').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectionDialog(String demandeId, String type) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Raison du rejet',
            style: TextStyle(color: Color(0xFF8B0000)),
          ),
          content: TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Entrez la raison du rejet',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler', style: TextStyle(color: Colors.grey[700])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 244, 229, 229),
              ),
              onPressed: () async {
                if (_reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez entrer une raison'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                await _rejectDemande(demandeId, _reasonController.text, type);
                _reasonController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveDemande(String demandeId, String type, String dateDebut, String? dateFin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (type == 'CONGE') {
        final days = _calculateLeaveDays(dateDebut, dateFin);
        await _demandeService.approveDemande(
          demandeId, 
          authProvider.userId!,
          days: days,
        );
      } else {
        await _demandeService.approveDemande(
          demandeId, 
          authProvider.userId!,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande approuvée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDemandes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectDemande(String demandeId, String raison, String type) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await _demandeService.rejectDemande(
        demandeId, 
        authProvider.userId!,
        raison: raison,
        type: type,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande rejetée avec succès'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      _loadDemandes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _calculateLeaveDays(String dateDebut, String? dateFin) {
    final start = DateTime.parse(dateDebut);
    final end = dateFin != null ? DateTime.parse(dateFin) : start;
    return end.difference(start).inDays + 1;
  }

  String _getTypeDemande(String type) {
    switch (type) {
      case 'CONGE': return 'Congé';
      case 'ABSENCE': return 'Absence';
      case 'AUTORISATION_SORTIE': return 'Autorisation de sortie';
      default: return type;
    }
  }

  Widget _buildDemandeItem(Map<String, dynamic> demande) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTypeDemande(demande['type']),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                Text(
                  '${demande['employe']['utilisateur']['nom']} ${demande['employe']['utilisateur']['prenom']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${demande['dateDebut'].toString().substring(0, 10)}'
                  '${demande['dateFin'] != null ? ' - ${demande['dateFin'].toString().substring(0, 10)}' : ''}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (demande['raison'] != null) ...[
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demande['raison'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('Approuver'),
                  onPressed: () => _approveDemande(
                    demande['id'],
                    demande['type'],
                    demande['dateDebut'],
                    demande['dateFin'],
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFF8B0000),
                    side: BorderSide(color: Color(0xFF8B0000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Rejeter', style: TextStyle(color: Colors.white),),
                  onPressed: () => _showRejectionDialog(
                    demande['id'],
                    demande['type'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.typeResponsable != 'RH') {
      return RhLayout(
        title: 'Accès refusé',
        child: Center(
          child: Text(
            'Vous n\'avez pas les autorisations nécessaires',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      );
    }

    return RhLayout(
      title: 'Gestion des demandes',
      child: RefreshIndicator(
        onRefresh: _loadDemandes,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _demandes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 50, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Aucune demande en attente',
                          style: TextStyle(
                            fontSize: 16, 
                            color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: _demandes.length,
                    itemBuilder: (context, index) {
                      return _buildDemandeItem(_demandes[index]);
                    },
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}