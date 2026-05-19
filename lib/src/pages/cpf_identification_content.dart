import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.isSubmitting = false,
    this.errorMessage,
    this.failureCount = 0,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<CpfIdentificationData> onSubmit;
  final VoidCallback onForgotPassword;
  final bool isSubmitting;
  final String? errorMessage;
  final int failureCount;

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
  bool _isKeyboardVisible = false;
  bool _isPasswordUpperCase = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CpfIdentificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.failureCount != oldWidget.failureCount &&
        widget.errorMessage != null) {
      _setControllerText(_passwordController, '');
      _activeField = _CpfIdentificationField.password;
      _isKeyboardVisible = true;
    }
  }

  void _submit() {
    if (widget.isSubmitting) {
      return;
    }

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
      _isKeyboardVisible = true;
    });
  }

  void _closeKeyboard() {
    setState(() {
      _isKeyboardVisible = false;
    });
  }

  void _goToNextField() {
    switch (_activeField) {
      case _CpfIdentificationField.cpf:
        _setActiveField(_CpfIdentificationField.birthDate);
      case _CpfIdentificationField.birthDate:
        _setActiveField(_CpfIdentificationField.password);
      case _CpfIdentificationField.password:
        _closeKeyboard();
    }
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
        _appendPasswordCharacter(digit);
    }
  }

  void _appendPasswordCharacter(String value) {
    final text = _passwordController.text;

    if (text.length >= 20) {
      return;
    }

    _setControllerText(_passwordController, '$text$value');
  }

  void _togglePasswordCase() {
    setState(() {
      _isPasswordUpperCase = !_isPasswordUpperCase;
    });
  }

  void _backspace() {
    final controller = _activeController;
    final value = _activeField == _CpfIdentificationField.password
        ? controller.text
        : _digitsOnly(controller.text);

    if (value.isEmpty) {
      return;
    }

    final nextValue = value.substring(0, value.length - 1);
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
    final useSideKeyboard = _useSideKeyboard(context);

    return SizedBox(
      height: _pageHeight(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FlowTopBar(
                  logoBytes: logoBytes,
                  primaryColor: primaryColor,
                  title: widget.flowTitle,
                  onBack: widget.onBack,
                  onHome: widget.onHome,
                ),
                const SizedBox(height: 24),
                Text(
                  'Identificacao com CPF',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: widget.identity.patientNameColor ?? primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: _isKeyboardVisible && !useSideKeyboard ? 360 : 96,
                    ),
                    child: Align(
                      alignment: useSideKeyboard && _isKeyboardVisible
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (widget.errorMessage != null) ...[
                                _AuthenticationErrorBanner(
                                  message: widget.errorMessage!,
                                  color: primaryColor,
                                ),
                                const SizedBox(height: 20),
                              ],
                              TextFormField(
                                key: const ValueKey('cpf-identification-cpf'),
                                controller: _cpfController,
                                showCursor: true,
                                onTap: () => _setActiveField(
                                  _CpfIdentificationField.cpf,
                                ),
                                decoration: _inputDecoration(
                                  label: 'CPF',
                                  field: _CpfIdentificationField.cpf,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                      final digits = _digitsOnly(newValue.text);
                                      final formatted = _formatCpf(digits);
                                      return TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                validator: (value) {
                                  return _digitsOnly(value ?? '').length == 11
                                      ? null
                                      : 'Informe um CPF valido.';
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const ValueKey(
                                  'cpf-identification-birth-date',
                                ),
                                controller: _birthDateController,
                                showCursor: true,
                                onTap: () => _setActiveField(
                                  _CpfIdentificationField.birthDate,
                                ),
                                decoration: _inputDecoration(
                                  label: 'Data de nascimento',
                                  field: _CpfIdentificationField.birthDate,
                                  hint: 'DD/MM/AAAA',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                      final digits = _digitsOnly(newValue.text);
                                      final formatted = _formatDate(digits);
                                      return TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                validator: (value) {
                                  return _digitsOnly(value ?? '').length == 8
                                      ? null
                                      : 'Informe a data de nascimento.';
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const ValueKey(
                                  'cpf-identification-password',
                                ),
                                controller: _passwordController,
                                showCursor: true,
                                onTap: () => _setActiveField(
                                  _CpfIdentificationField.password,
                                ),
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
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                ),
                                child: const Text('Esqueci minha senha'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isKeyboardVisible)
            Positioned(
              left: useSideKeyboard ? null : 0,
              right: 0,
              top: useSideKeyboard ? 132 : null,
              bottom: useSideKeyboard ? null : 0,
              child: _buildKeyboard(buttonColor, useSideKeyboard),
            ),
          if (!_isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionButtons(primaryColor, buttonColor),
            ),
        ],
      ),
    );
  }

  double _pageHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        64;

    return height < 520 ? 520 : height;
  }

  bool _useSideKeyboard(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  Widget _buildKeyboard(Color buttonColor, bool useSideKeyboard) {
    final keyboard = NumericTouchKeyboard(
      color: buttonColor,
      activeFieldLabel: _activeField.label,
      nextLabel: _activeField == _CpfIdentificationField.password
          ? 'Concluir'
          : 'Proximo',
      layout: _activeField == _CpfIdentificationField.password
          ? TouchKeyboardLayout.alphanumeric
          : TouchKeyboardLayout.numeric,
      isUpperCase: _isPasswordUpperCase,
      onToggleLetterCase: _togglePasswordCase,
      borderRadius: useSideKeyboard
          ? BorderRadius.circular(8)
          : const BorderRadius.vertical(top: Radius.circular(8)),
      onDigit: _appendDigit,
      onBackspace: _backspace,
      onClear: _clearActiveField,
      onNext: _goToNextField,
      onClose: _closeKeyboard,
    );

    if (!useSideKeyboard) {
      return Center(child: keyboard);
    }

    final width = _activeField == _CpfIdentificationField.password
        ? 560.0
        : 360.0;

    return SizedBox(width: width, child: keyboard);
  }

  Widget _buildActionButtons(Color primaryColor, Color buttonColor) {
    return LayoutBuilder(
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
        final submitButton = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: widget.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
          onPressed: _submit,
          label: Text(widget.isSubmitting ? 'Validando...' : 'Entrar'),
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
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required _CpfIdentificationField field,
    String? hint,
  }) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final isActive = _isKeyboardVisible && field == _activeField;

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

class _AuthenticationErrorBanner extends StatelessWidget {
  const _AuthenticationErrorBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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

extension on _CpfIdentificationField {
  String get label {
    return switch (this) {
      _CpfIdentificationField.cpf => 'CPF',
      _CpfIdentificationField.birthDate => 'Data de nascimento',
      _CpfIdentificationField.password => 'Senha',
    };
  }
}
