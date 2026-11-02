import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecolens/screens/sos/sos_screen.dart';

void main() {
  testWidgets('SOS apresenta contatos de emergência sem ligar sozinho',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SosScreen()),
    );

    expect(find.text('SOS ambiental'), findsOneWidget);
    expect(find.text('SAMU · 192'), findsOneWidget);
    expect(find.text('Corpo de Bombeiros · 193'), findsOneWidget);
    expect(find.textContaining('Priorize sua segurança'), findsOneWidget);

    // Sem tocar em um botão, o teste não aciona aplicativos externos.
    expect(find.byIcon(Icons.phone_outlined), findsWidgets);
  });
}
