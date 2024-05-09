import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importa el archivo main.dart donde se define MyApp
import 'package:ecg_3/main.dart'; 

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construye nuestra aplicación y activa un frame.
    await tester.pumpWidget(const MyApp());

    // Verifica que nuestro contador comience en 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Toca el icono '+' y activa un frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifica que nuestro contador ha incrementado.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
