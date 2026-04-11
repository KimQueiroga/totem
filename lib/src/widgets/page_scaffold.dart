import 'package:flutter/material.dart';

import '../models/terminal_visual_identity.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.child,
    this.identity,
    this.alignment = Alignment.center,
    this.maxWidth = 720,
  });

  final Widget child;
  final TerminalVisualIdentity? identity;
  final Alignment alignment;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          identity?.primaryColor?.withValues(alpha: 0.08) ??
          const Color(0xFFF4F8F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight > 64
                ? constraints.maxHeight - 64
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Align(
                  alignment: alignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
