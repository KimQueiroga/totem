import 'package:flutter/material.dart';

class TerminalNotFoundContent extends StatelessWidget {
  const TerminalNotFoundContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 88,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 32),
        Text(
          'Terminal nao informado',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Acesse usando /terminal=nome-do-terminal.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
