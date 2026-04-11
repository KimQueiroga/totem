import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';

class CpfIdentificationContent extends StatefulWidget {
  const CpfIdentificationContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.onHome,
    required this.onBack,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<CpfIdentificationData> onSubmit;
  final VoidCallback onForgotPassword;

  @override
  State<CpfIdentificationContent> createState() =>
      _CpfIdentificationContentState();
}

class _CpfIdentificationContentState extends State<CpfIdentificationContent> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _cpfController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSubmit(
      CpfIdentificationData(
        cpf: _digitsOnly(_cpfController.text),
        birthDate: _birthDateController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoBytes = widget.identity.logoBytes;
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = widget.identity.buttonColor ?? primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowTopBar(
          logoBytes: logoBytes,
          primaryColor: primaryColor,
          title: widget.flowTitle,
          onBack: widget.onBack,
          onHome: widget.onHome,
        ),
        const SizedBox(height: 36),
        Text(
          'Identificacao com CPF',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: widget.identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cpfController,
                    decoration: const InputDecoration(labelText: 'CPF'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      _CpfInputFormatter(),
                    ],
                    validator: (value) {
                      return _digitsOnly(value ?? '').length == 11
                          ? null
                          : 'Informe um CPF valido.';
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'DD/MM/AAAA',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      _DateInputFormatter(),
                    ],
                    validator: (value) {
                      return _digitsOnly(value ?? '').length == 8
                          ? null
                          : 'Informe a data de nascimento.';
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    validator: (value) {
                      return (value ?? '').trim().isEmpty
                          ? 'Informe a senha.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: widget.onForgotPassword,
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                    child: const Text('Esqueci minha senha'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 96),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackButtons = constraints.maxWidth < 640;
            final cancelButton = OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: widget.onBack,
              child: const Text('Cancelar'),
            );
            final submitButton = FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _submit,
              child: const Text('Entrar'),
            );

            if (stackButtons) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 64, child: submitButton),
                  const SizedBox(height: 16),
                  SizedBox(height: 64, child: cancelButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: SizedBox(height: 64, child: cancelButton)),
                const SizedBox(width: 48),
                Expanded(child: SizedBox(height: 64, child: submitButton)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CpfIdentificationData {
  const CpfIdentificationData({
    required this.cpf,
    required this.birthDate,
    required this.password,
  });

  final String cpf;
  final String birthDate;
  final String password;
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _format(newValue, _formatCpf);
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _format(newValue, _formatDate);
  }
}

TextEditingValue _format(
  TextEditingValue value,
  String Function(String digits) formatter,
) {
  final text = formatter(_digitsOnly(value.text));

  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

String _formatCpf(String digits) {
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index == 3 || index == 6) {
      buffer.write('.');
    } else if (index == 9) {
      buffer.write('-');
    }

    buffer.write(digits[index]);
  }

  return buffer.toString();
}

String _formatDate(String digits) {
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index == 2 || index == 4) {
      buffer.write('/');
    }

    buffer.write(digits[index]);
  }

  return buffer.toString();
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
