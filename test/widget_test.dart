import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_equipe_flutter/main.dart';
import 'package:gestion_equipe_flutter/screens/auth/login_screen.dart'; // Assurez-vous d'importer l'écran approprié

void main() {
  testWidgets('Affichage de la page d\'accueil', (WidgetTester tester) async {
    // Crée une instance de MyApp avec un écran de connexion comme route initiale
    await tester.pumpWidget(MyApp());

    // Vérifier si le texte de bienvenue est présent
    expect(find.text('Bienvenue !'), findsOneWidget);  // Remplace cela par du texte que tu attends sur l'écran
    expect(find.text('1'), findsNothing);

    // Si tu as un bouton à tester, tu peux simuler un tap sur l'icône
    await tester.tap(find.byIcon(Icons.add));  // Vérifie que tu as un bouton avec cet icône
    await tester.pump();

    // Vérifie si l'incrémentation a bien eu lieu
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
