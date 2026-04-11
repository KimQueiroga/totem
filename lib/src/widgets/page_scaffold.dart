import 'package:flutter/material.dart';

import '../models/terminal_visual_identity.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.child, this.identity});

  final Widget child;
  final TerminalVisualIdentity? identity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          identity?.primaryColor?.withValues(alpha: 0.08) ??
          const Color(0xFFF4F8F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
