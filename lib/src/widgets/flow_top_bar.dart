import 'dart:typed_data';

import 'package:flutter/material.dart';

class FlowTopBar extends StatelessWidget {
  const FlowTopBar({
    super.key,
    required this.logoBytes,
    required this.primaryColor,
    required this.title,
    required this.onBack,
    required this.onHome,
  });

  final Uint8List? logoBytes;
  final Color primaryColor;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final sideWidth = compact ? 56.0 : 160.0;

        return Row(
          children: [
            SizedBox(
              width: sideWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: compact
                    ? IconButton(
                        onPressed: onBack,
                        color: primaryColor,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Voltar',
                      )
                    : TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  FlowLogo(logoBytes: logoBytes, primaryColor: primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: sideWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton.outlined(
                  onPressed: onHome,
                  color: primaryColor,
                  icon: const Icon(Icons.home_rounded),
                  tooltip: 'Inicio',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FlowLogo extends StatelessWidget {
  const FlowLogo({
    super.key,
    required this.logoBytes,
    required this.primaryColor,
  });

  final Uint8List? logoBytes;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final bytes = logoBytes;

    if (bytes == null) {
      return Icon(Icons.local_hospital_outlined, size: 48, color: primaryColor);
    }

    return Image.memory(
      bytes,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.local_hospital_outlined,
          size: 48,
          color: primaryColor,
        );
      },
    );
  }
}
