import 'package:flutter/material.dart';

class HistoriquePointagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des Pointages'),
      ),
      body: Center(
        child: Text('Aucun pointage disponible.'),
      ),
    );
  }
}
