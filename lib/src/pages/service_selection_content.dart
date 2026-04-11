import 'package:flutter/material.dart';

import '../models/terminal_context.dart';
import '../models/terminal_visual_identity.dart';

class ServiceSelectionContent extends StatelessWidget {
  const ServiceSelectionContent({
    super.key,
    required this.terminalName,
    required this.identity,
    required this.terminalContext,
    required this.onBack,
  });

  final String terminalName;
  final TerminalVisualIdentity identity;
  final TerminalContext terminalContext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final logoBytes = identity.logoBytes;
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;
    final services = terminalContext.services;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
        ),
        if (logoBytes != null)
          Image.memory(
            logoBytes,
            height: 88,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.local_hospital_outlined,
                size: 72,
                color: primaryColor,
              );
            },
          )
        else
          Icon(Icons.local_hospital_outlined, size: 72, color: primaryColor),
        const SizedBox(height: 28),
        Text(
          'Selecione o servico',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          identity.alias.isEmpty ? terminalName : identity.alias,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 32),
        if (services.isEmpty)
          Text(
            'Nenhum servico disponivel para este terminal.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          )
        else
          ...services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _selectService(context, service),
                  child: Text(
                    service.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _selectService(BuildContext context, TerminalService service) {
    final termsOfUse = service.termsOfUse.trim();

    if (termsOfUse.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Termos de uso'),
            content: SingleChildScrollView(child: Text(termsOfUse)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSelectedService(context, service);
                },
                child: const Text('Aceitar'),
              ),
            ],
          );
        },
      );

      return;
    }

    _showSelectedService(context, service);
  }

  void _showSelectedService(BuildContext context, TerminalService service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servico selecionado: ${service.displayName}')),
    );
  }
}
