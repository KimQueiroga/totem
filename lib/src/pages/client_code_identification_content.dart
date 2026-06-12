import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/numeric_touch_keyboard.dart';

class ClientCodeIdentificationContent extends StatefulWidget {
  const ClientCodeIdentificationContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.onHome,
    required this.onBack,
    required this.onSubmit,
    this.isSubmitting = false,
    this.errorMessage,
    this.failureCount = 0,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<ClientCodeIdentificationData> onSubmit;
  final bool isSubmitting;
  final String? errorMessage;
  final int failureCount;

  @override
  State<ClientCodeIdentificationContent> createState() =>
      _ClientCodeIdentificationContentState();
}

class _ClientCodeIdentificationContentState
    extends State<ClientCodeIdentificationContent> {
  final _formKey = GlobalKey<FormState>();
  final _clientCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  _ClientCodeIdentificationField _activeField =
      _ClientCodeIdentificationField.clientCode;
  bool _isKeyboardVisible = false;
  bool _isPasswordUpperCase = false;

  @override
  void dispose() {
    _clientCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientCodeIdentificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.failureCount != oldWidget.failureCount &&
        widget.errorMessage != null) {
      _setControllerText(_passwordController, '');
      _activeField = _ClientCodeIdentificationField.password;
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
      ClientCodeIdentificationData(
        clientCode: _digitsOnly(_clientCodeController.text),
        password: _passwordController.text,
      ),
    );
  }

  void _setActiveField(_ClientCodeIdentificationField field) {
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
      case _ClientCodeIdentificationField.clientCode:
        _setActiveField(_ClientCodeIdentificationField.password);
      case _ClientCodeIdentificationField.password:
        _closeKeyboard();
    }
  }

  void _appendDigit(String digit) {
    switch (_activeField) {
      case _ClientCodeIdentificationField.clientCode:
        final digits = _digitsOnly(_clientCodeController.text);

        if (digits.length >= 12) {
          return;
        }

        _setControllerText(_clientCodeController, '$digits$digit');
      case _ClientCodeIdentificationField.password:
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
    final value = _activeField == _ClientCodeIdentificationField.password
        ? controller.text
        : _digitsOnly(controller.text);

    if (value.isEmpty) {
      return;
    }

    _setControllerText(controller, value.substring(0, value.length - 1));
  }

  void _clearActiveField() {
    _setControllerText(_activeController, '');
  }

  TextEditingController get _activeController {
    return switch (_activeField) {
      _ClientCodeIdentificationField.clientCode => _clientCodeController,
      _ClientCodeIdentificationField.password => _passwordController,
    };
  }

  void _setControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = widget.identity.buttonColor ?? primaryColor;
    final useSideKeyboard = MediaQuery.sizeOf(context).width >= 900;

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
                  logoBytes: widget.identity.logoBytes,
                  primaryColor: primaryColor,
                  title: widget.flowTitle,
                  onBack: widget.onBack,
                  onHome: widget.onHome,
                ),
                const SizedBox(height: 24),
                Text(
                  'Identificacao com codigo cliente',
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
                                key: const ValueKey(
                                  'client-code-identification-code',
                                ),
                                controller: _clientCodeController,
                                showCursor: true,
                                onTap: () => _setActiveField(
                                  _ClientCodeIdentificationField.clientCode,
                                ),
                                decoration: _inputDecoration(
                                  label: 'Codigo cliente',
                                  field:
                                      _ClientCodeIdentificationField.clientCode,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  return _digitsOnly(value ?? '').isEmpty
                                      ? 'Informe o codigo do cliente.'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const ValueKey(
                                  'client-code-identification-password',
                                ),
                                controller: _passwordController,
                                showCursor: true,
                                onTap: () => _setActiveField(
                                  _ClientCodeIdentificationField.password,
                                ),
                                decoration: _inputDecoration(
                                  label: 'Senha',
                                  field:
                                      _ClientCodeIdentificationField.password,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  return (value ?? '').trim().isEmpty
                                      ? 'Informe a senha.'
                                      : null;
                                },
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

  Widget _buildKeyboard(Color buttonColor, bool useSideKeyboard) {
    final keyboard = NumericTouchKeyboard(
      color: buttonColor,
      activeFieldLabel: _activeField.label,
      nextLabel: _activeField == _ClientCodeIdentificationField.password
          ? 'Concluir'
          : 'Proximo',
      layout: _activeField == _ClientCodeIdentificationField.password
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

    final width = _activeField == _ClientCodeIdentificationField.password
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
    required _ClientCodeIdentificationField field,
  }) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final isActive = _isKeyboardVisible && field == _activeField;

    return InputDecoration(
      labelText: label,
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

  double _pageHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        64;

    return height < 520 ? 520 : height;
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

class ClientCodeIdentificationData {
  const ClientCodeIdentificationData({
    required this.clientCode,
    required this.password,
  });

  final String clientCode;
  final String password;
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

enum _ClientCodeIdentificationField { clientCode, password }

extension on _ClientCodeIdentificationField {
  String get label {
    return switch (this) {
      _ClientCodeIdentificationField.clientCode => 'Codigo cliente',
      _ClientCodeIdentificationField.password => 'Senha',
    };
  }
}
