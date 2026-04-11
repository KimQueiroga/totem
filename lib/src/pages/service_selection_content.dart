import 'dart:typed_data';

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

  static const double _serviceGap = 16;
  static const double _twoColumnBreakpoint = 680;

  @override
  Widget build(BuildContext context) {
    final logoBytes = identity.logoBytes;
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;
    final services = terminalContext.services;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns =
            constraints.maxWidth >= _twoColumnBreakpoint && services.length > 1;
        final serviceWidth = useTwoColumns
            ? (constraints.maxWidth - _serviceGap) / 2
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 12),
            _ServiceHeader(
              terminalName: terminalName,
              identity: identity,
              primaryColor: primaryColor,
              logoBytes: logoBytes,
              useHorizontalLayout: constraints.maxWidth >= 640,
            ),
            const SizedBox(height: 36),
            if (services.isEmpty)
              Text(
                'Nenhum servico disponivel para este terminal.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              Wrap(
                spacing: _serviceGap,
                runSpacing: _serviceGap,
                children: services
                    .map(
                      (service) => SizedBox(
                        width: serviceWidth,
                        height: 88,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _selectService(
                            context,
                            service,
                            primaryColor,
                            buttonColor,
                          ),
                          child: Text(
                            service.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        );
      },
    );
  }

  void _selectService(
    BuildContext context,
    TerminalService service,
    Color primaryColor,
    Color buttonColor,
  ) {
    final termsOfUse = service.termsOfUse.trim();

    if (termsOfUse.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(
              'Termos de uso',
              style: TextStyle(
                color: identity.patientNameColor ?? primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(child: Text(termsOfUse)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: buttonColor),
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

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.terminalName,
    required this.identity,
    required this.primaryColor,
    required this.logoBytes,
    required this.useHorizontalLayout,
  });

  final String terminalName;
  final TerminalVisualIdentity identity;
  final Color primaryColor;
  final Uint8List? logoBytes;
  final bool useHorizontalLayout;

  @override
  Widget build(BuildContext context) {
    final logo = _TerminalLogo(
      logoBytes: logoBytes,
      primaryColor: primaryColor,
    );
    final title = Column(
      crossAxisAlignment: useHorizontalLayout
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'Selecione o servico',
          textAlign: useHorizontalLayout ? TextAlign.left : TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          identity.alias.isEmpty ? terminalName : identity.alias,
          textAlign: useHorizontalLayout ? TextAlign.left : TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );

    if (!useHorizontalLayout) {
      return Column(children: [logo, const SizedBox(height: 28), title]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logo,
        const SizedBox(width: 32),
        Expanded(child: title),
      ],
    );
  }
}

class _TerminalLogo extends StatelessWidget {
  const _TerminalLogo({required this.logoBytes, required this.primaryColor});

  final Uint8List? logoBytes;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final bytes = logoBytes;

    if (bytes == null) {
      return Icon(Icons.local_hospital_outlined, size: 80, color: primaryColor);
    }

    return Image.memory(
      bytes,
      height: 96,
      width: 180,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.local_hospital_outlined,
          size: 80,
          color: primaryColor,
        );
      },
    );
  }
}
