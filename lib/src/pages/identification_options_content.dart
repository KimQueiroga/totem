import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/terminal_visual_identity.dart';

enum IdentificationOption { barcode, cpf, clientCode }

extension IdentificationOptionLabel on IdentificationOption {
  String get label {
    return switch (this) {
      IdentificationOption.barcode => 'Codigo de barra',
      IdentificationOption.cpf => 'CPF',
      IdentificationOption.clientCode => 'Codigo cliente',
    };
  }
}

class IdentificationOptionsContent extends StatelessWidget {
  const IdentificationOptionsContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.question,
    required this.onHome,
    required this.onBack,
    required this.onOptionSelected,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final String question;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<IdentificationOption> onOptionSelected;

  static const double _optionGap = 24;
  static const double _threeColumnBreakpoint = 820;
  static const double _twoColumnBreakpoint = 560;

  @override
  Widget build(BuildContext context) {
    final logoBytes = identity.logoBytes;
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= _threeColumnBreakpoint
            ? 3
            : constraints.maxWidth >= _twoColumnBreakpoint
            ? 2
            : 1;
        final optionWidth =
            (constraints.maxWidth - (_optionGap * (columnCount - 1))) /
            columnCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdentificationTopBar(
              logoBytes: logoBytes,
              primaryColor: primaryColor,
              flowTitle: flowTitle,
              onBack: onBack,
              onHome: onHome,
            ),
            const SizedBox(height: 36),
            Text(
              question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: identity.patientNameColor ?? primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 64),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: _optionGap,
              runSpacing: _optionGap,
              children: [
                _IdentificationOptionButton(
                  width: optionWidth,
                  color: buttonColor,
                  icon: Icons.qr_code_scanner,
                  title: 'Ler codigo de barra',
                  onPressed: () =>
                      onOptionSelected(IdentificationOption.barcode),
                ),
                _IdentificationOptionButton(
                  width: optionWidth,
                  color: buttonColor,
                  icon: Icons.person_outline,
                  title: 'Usar CPF',
                  onPressed: () => onOptionSelected(IdentificationOption.cpf),
                ),
                _IdentificationOptionButton(
                  width: optionWidth,
                  color: buttonColor,
                  icon: Icons.badge_outlined,
                  title: 'Codigo cliente',
                  onPressed: () =>
                      onOptionSelected(IdentificationOption.clientCode),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IdentificationTopBar extends StatelessWidget {
  const _IdentificationTopBar({
    required this.logoBytes,
    required this.primaryColor,
    required this.flowTitle,
    required this.onBack,
    required this.onHome,
  });

  final Uint8List? logoBytes;
  final Color primaryColor;
  final String flowTitle;
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
                  _IdentificationLogo(
                    logoBytes: logoBytes,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    flowTitle,
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

class _IdentificationLogo extends StatelessWidget {
  const _IdentificationLogo({
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

class _IdentificationOptionButton extends StatelessWidget {
  const _IdentificationOptionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 128,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
