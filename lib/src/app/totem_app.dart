import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../services/terminal_api.dart';
import '../utils/terminal_name.dart';

class TotemApp extends StatelessWidget {
  const TotemApp({
    super.key,
    this.initialUri,
    this.loadVisualIdentity,
    this.loadTerminalContext,
  });

  final Uri? initialUri;
  final VisualIdentityLoader? loadVisualIdentity;
  final TerminalContextLoader? loadTerminalContext;

  @override
  Widget build(BuildContext context) {
    final terminalName = extractTerminalName(initialUri ?? Uri.base);

    return MaterialApp(
      title: 'Totem Autoatendimento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A71)),
        useMaterial3: true,
      ),
      home: HomePage(
        terminalName: terminalName,
        loadVisualIdentity: loadVisualIdentity ?? fetchTerminalVisualIdentity,
        loadTerminalContext: loadTerminalContext ?? fetchTerminalContext,
      ),
    );
  }
}
