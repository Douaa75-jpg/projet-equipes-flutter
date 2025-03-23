import 'package:flutter/material.dart';

class DemandeSortiePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Demande d'autorisation de sortie")),
      body: Center(
        child: Column(
          children: [
            Text("Formulaire de demande d'autorisation de sortie ici"),
            // هنا يمكنك إضافة محتويات النموذج (نموذج لطلب إذن الخروج)
          ],
        ),
      ),
    );
  }
}
