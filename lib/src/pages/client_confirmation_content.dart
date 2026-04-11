import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';

class ClientConfirmationContent extends StatelessWidget {
  const ClientConfirmationContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.authentication,
    required this.onBack,
    required this.onHome,
    required this.onReject,
    required this.onConfirm,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final ClientAuthentication authentication;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onReject;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;
    final user = authentication.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowTopBar(
          logoBytes: identity.logoBytes,
          primaryColor: primaryColor,
          title: flowTitle,
          onBack: onBack,
          onHome: onHome,
        ),
        const SizedBox(height: 36),
        Text(
          'Confirme seus dados',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Os dados abaixo estao corretos?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 40),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _ConfirmationField(label: 'Nome', value: user.displayName),
                _ConfirmationField(label: 'CPF', value: _maskedCpf(user.cpf)),
                _ConfirmationField(
                  label: 'Data de nascimento',
                  value: _formatDate(user.birthDate),
                ),
                _ConfirmationField(label: 'E-mail', value: user.email),
                _ConfirmationField(
                  label: 'Celular',
                  value: user.mobilePhoneNumber,
                ),
                _ConfirmationField(
                  label: 'Telefone',
                  value: user.homePhoneNumber,
                ),
                _ConfirmationField(
                  label: 'Nome da mae',
                  value: user.motherName,
                ),
                _ConfirmationField(
                  label: 'Endereco',
                  value: user.streetAndComplement,
                ),
                _ConfirmationField(label: 'Cidade', value: user.cityAndState),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackButtons = constraints.maxWidth < 640;
            final rejectButton = OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onReject,
              child: const Text('Nao'),
            );
            final confirmButton = FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onConfirm,
              child: const Text('Sim'),
            );

            if (stackButtons) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 64, child: confirmButton),
                  const SizedBox(height: 16),
                  SizedBox(height: 64, child: rejectButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: SizedBox(height: 64, child: rejectButton)),
                const SizedBox(width: 48),
                Expanded(child: SizedBox(height: 64, child: confirmButton)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConfirmationField extends StatelessWidget {
  const _ConfirmationField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null || value!.trim().isEmpty
        ? '-'
        : value!.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        readOnly: true,
        initialValue: displayValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

String _maskedCpf(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');

  if (digits.length < 4) {
    return value;
  }

  final suffix = digits.substring(digits.length - 2);

  return '***.***.***-$suffix';
}

String _formatDate(String value) {
  final parts = value.split('-');

  if (parts.length != 3) {
    return value;
  }

  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
