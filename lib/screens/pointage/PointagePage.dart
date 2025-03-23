import 'package:flutter/material.dart';

class PointagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pointage'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Action de pointage (à compléter)
          },
          child: Text('Pointer maintenant'),
        ),
      ),
    );
  }
}
