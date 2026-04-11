import 'package:flutter/material.dart';

import '../models/terminal_visual_identity.dart';

class TerminalHomeContent extends StatelessWidget {
  const TerminalHomeContent({
    super.key,
    required this.terminalName,
    required this.identity,
    required this.onStartAttendance,
  });

  final String terminalName;
  final TerminalVisualIdentity identity;
  final VoidCallback onStartAttendance;

  @override
  Widget build(BuildContext context) {
    final logoBytes = identity.logoBytes;
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logoBytes != null)
          Image.memory(
            logoBytes,
            height: 112,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.local_hospital_outlined,
                size: 88,
                color: primaryColor,
              );
            },
          )
        else
          Icon(Icons.local_hospital_outlined, size: 88, color: primaryColor),
        const SizedBox(height: 32),
        Text(
          'Autoatendimento',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          identity.alias.isEmpty ? terminalName : identity.alias,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: buttonColor),
            onPressed: onStartAttendance,
            child: const Text('Iniciar atendimento'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
            onPressed: () {},
            child: const Text('Consultar senha'),
          ),
        ),
      ],
    );
  }
}
