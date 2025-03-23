import 'package:flutter/material.dart';

class DemandeCongePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Demande de congé")),
      body: Center(
        child: Column(
          children: [
            Text("Formulaire de demande de congé ici"),
            // هنا يمكنك إضافة محتويات النموذج (نموذج لطلب الإجازة)
          ],
        ),
      ),
    );
  }
}
