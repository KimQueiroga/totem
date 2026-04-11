import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TerminalErrorContent extends StatelessWidget {
  const TerminalErrorContent({
    super.key,
    required this.terminalName,
    this.error,
  });

  final String terminalName;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 88,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 32),
        Text(
          'Nao foi possivel carregar este terminal.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          terminalName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (kDebugMode && error != null) ...[
          const SizedBox(height: 24),
          SelectableText(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
