import 'package:flutter/material.dart';
import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/numeric_touch_keyboard.dart';

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
  _CpfIdentificationField _activeField = _CpfIdentificationField.cpf;

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

  void _setActiveField(_CpfIdentificationField field) {
    setState(() {
      _activeField = field;
    });
  }

  void _appendDigit(String digit) {
    switch (_activeField) {
      case _CpfIdentificationField.cpf:
        _setFormattedDigits(
          controller: _cpfController,
          digit: digit,
          maxLength: 11,
          formatter: _formatCpf,
        );
      case _CpfIdentificationField.birthDate:
        _setFormattedDigits(
          controller: _birthDateController,
          digit: digit,
          maxLength: 8,
          formatter: _formatDate,
        );
      case _CpfIdentificationField.password:
        _setFormattedDigits(
          controller: _passwordController,
          digit: digit,
          maxLength: 20,
          formatter: (digits) => digits,
        );
    }
  }

  void _backspace() {
    final controller = _activeController;
    final digits = _digitsOnly(controller.text);

    if (digits.isEmpty) {
      return;
    }

    final nextValue = digits.substring(0, digits.length - 1);
    _setControllerText(controller, _formatActiveField(nextValue));
  }

  void _clearActiveField() {
    _setControllerText(_activeController, '');
  }

  TextEditingController get _activeController {
    return switch (_activeField) {
      _CpfIdentificationField.cpf => _cpfController,
      _CpfIdentificationField.birthDate => _birthDateController,
      _CpfIdentificationField.password => _passwordController,
    };
  }

  String _formatActiveField(String digits) {
    return switch (_activeField) {
      _CpfIdentificationField.cpf => _formatCpf(digits),
      _CpfIdentificationField.birthDate => _formatDate(digits),
      _CpfIdentificationField.password => digits,
    };
  }

  void _setFormattedDigits({
    required TextEditingController controller,
    required String digit,
    required int maxLength,
    required String Function(String digits) formatter,
  }) {
    final digits = _digitsOnly(controller.text);

    if (digits.length >= maxLength) {
      return;
    }

    _setControllerText(controller, formatter('$digits$digit'));
  }

  void _setControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
                    readOnly: true,
                    showCursor: true,
                    onTap: () => _setActiveField(_CpfIdentificationField.cpf),
                    decoration: _inputDecoration(
                      label: 'CPF',
                      field: _CpfIdentificationField.cpf,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      return _digitsOnly(value ?? '').length == 11
                          ? null
                          : 'Informe um CPF valido.';
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    showCursor: true,
                    onTap: () =>
                        _setActiveField(_CpfIdentificationField.birthDate),
                    decoration: _inputDecoration(
                      label: 'Data de nascimento',
                      field: _CpfIdentificationField.birthDate,
                      hint: 'DD/MM/AAAA',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      return _digitsOnly(value ?? '').length == 8
                          ? null
                          : 'Informe a data de nascimento.';
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    readOnly: true,
                    showCursor: true,
                    onTap: () =>
                        _setActiveField(_CpfIdentificationField.password),
                    decoration: _inputDecoration(
                      label: 'Senha',
                      field: _CpfIdentificationField.password,
                    ),
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
        const SizedBox(height: 32),
        Center(
          child: NumericTouchKeyboard(
            color: buttonColor,
            onDigit: _appendDigit,
            onBackspace: _backspace,
            onClear: _clearActiveField,
          ),
        ),
        const SizedBox(height: 48),
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

  InputDecoration _inputDecoration({
    required String label,
    required _CpfIdentificationField field,
    String? hint,
  }) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final isActive = field == _activeField;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: isActive ? 'Digite usando o teclado na tela.' : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isActive ? primaryColor : Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

enum _CpfIdentificationField { cpf, birthDate, password }
