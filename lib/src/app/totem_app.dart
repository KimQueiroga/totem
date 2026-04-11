import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../services/terminal_api.dart';
import '../utils/terminal_name.dart';
import '../widgets/inactivity_timeout.dart';

class TotemApp extends StatefulWidget {
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
  State<TotemApp> createState() => _TotemAppState();
}

class _TotemAppState extends State<TotemApp> {
  static const inactivityTimeout = Duration(seconds: 60);

  int _resetCount = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _handleInactivityTimeout() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    setState(() {
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final terminalName = extractTerminalName(widget.initialUri ?? Uri.base);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Totem Autoatendimento',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return InactivityTimeout(
          timeout: inactivityTimeout,
          onTimeout: _handleInactivityTimeout,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A71)),
        useMaterial3: true,
      ),
      home: HomePage(
        terminalName: terminalName,
        resetCount: _resetCount,
        loadVisualIdentity:
            widget.loadVisualIdentity ?? fetchTerminalVisualIdentity,
        loadTerminalContext: widget.loadTerminalContext ?? fetchTerminalContext,
      ),
    );
  }
}
