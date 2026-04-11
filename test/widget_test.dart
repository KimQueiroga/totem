import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:totem/totem.dart';

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

  testWidgets('loads services after starting attendance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        loadTerminalContext: (_) async => const TerminalContext(
          company: '1',
          store: '1',
          printer: 'AIMT0001',
          location: '1',
          services: [
            TerminalService(
              id: '3',
              name: 'PRE_ATENDIMENTO',
              hostName: 'ihpmgaimtotem1',
              termsOfUse: '',
            ),
            TerminalService(
              id: '4',
              name: 'RESULTADO',
              hostName: 'ihpmgaimtotem1',
              termsOfUse: '',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar atendimento'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione o servico'), findsOneWidget);
    expect(find.text('Pre Atendimento'), findsOneWidget);
    expect(find.text('Resultado'), findsOneWidget);

    final firstPosition = tester.getTopLeft(find.text('Pre Atendimento'));
    final secondPosition = tester.getTopLeft(find.text('Resultado'));

    expect(firstPosition.dy, closeTo(secondPosition.dy, 1));
    expect(secondPosition.dx, greaterThan(firstPosition.dx));
  });

  testWidgets('renders message when terminal is not in url', (tester) async {
    await tester.pumpWidget(
      TotemApp(initialUri: Uri.parse('http://127.0.0.1:8080/')),
    );

    expect(find.text('Terminal nao informado'), findsOneWidget);
  });
}
