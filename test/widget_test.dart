import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:totem/main.dart';

void main() {
  test('extracts terminal name from path format', () {
    final terminalName = extractTerminalName(
      Uri.parse('http://127.0.0.1:8080/terminal=ihpmgaimtotem1'),
    );

    expect(terminalName, 'ihpmgaimtotem1');
  });

  test('extracts terminal name from query string format', () {
    final terminalName = extractTerminalName(
      Uri.parse('http://127.0.0.1:8080/?terminal=ihpmgaimtotem1'),
    );

    expect(terminalName, 'ihpmgaimtotem1');
  });

  testWidgets('renders autoatendimento start screen from visual identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      TotemApp(
        initialUri: Uri.parse('http://127.0.0.1:8080/terminal=ihpmgaimtotem1'),
        loadVisualIdentity: (_) async => const TerminalVisualIdentity(
          alias: 'HERMES PARDINI (MG)',
          primaryColor: Color(0xFFCF043B),
          primaryHoverColor: Color(0xFF9D032D),
          buttonColor: Color(0xFFD31245),
          patientNameColor: Color(0xFFCF043B),
          logoBase64: '',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Autoatendimento'), findsOneWidget);
    expect(find.text('HERMES PARDINI (MG)'), findsOneWidget);
    expect(find.text('Iniciar atendimento'), findsOneWidget);
    expect(find.text('Consultar senha'), findsOneWidget);
  });

  testWidgets('renders message when terminal is not in url', (tester) async {
    await tester.pumpWidget(
      TotemApp(initialUri: Uri.parse('http://127.0.0.1:8080/')),
    );

    expect(find.text('Terminal nao informado'), findsOneWidget);
  });
}
