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
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<ClientCodeIdentificationData> onSubmit;

  @override
  State<ClientCodeIdentificationContent> createState() =>
      _ClientCodeIdentificationContentState();
}

class _ClientCodeIdentificationContentState
    extends State<ClientCodeIdentificationContent> {
  final _formKey = GlobalKey<FormState>();
  final _clientCodeController = TextEditingController();
  bool _isKeyboardVisible = false;

  @override
  void dispose() {
    _clientCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSubmit(
      ClientCodeIdentificationData(
        clientCode: _digitsOnly(_clientCodeController.text),
      ),
    );
  }

  void _appendDigit(String digit) {
    final digits = _digitsOnly(_clientCodeController.text);

    if (digits.length >= 12) {
      return;
    }

    _setControllerText('$digits$digit');
  }

  void _backspace() {
    final digits = _digitsOnly(_clientCodeController.text);

    if (digits.isEmpty) {
      return;
    }

    _setControllerText(digits.substring(0, digits.length - 1));
  }

  void _setControllerText(String text) {
    _clientCodeController.value = TextEditingValue(
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
                const SizedBox(height: 42),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: _isKeyboardVisible && !useSideKeyboard ? 300 : 96,
                    ),
                    child: Align(
                      alignment: useSideKeyboard && _isKeyboardVisible
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            key: const ValueKey(
                              'client-code-identification-code',
                            ),
                            controller: _clientCodeController,
                            showCursor: true,
                            onTap: () {
                              setState(() {
                                _isKeyboardVisible = true;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Codigo cliente',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isKeyboardVisible
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
      activeFieldLabel: 'Codigo cliente',
      nextLabel: 'Concluir',
      layout: TouchKeyboardLayout.numeric,
      borderRadius: useSideKeyboard
          ? BorderRadius.circular(8)
          : const BorderRadius.vertical(top: Radius.circular(8)),
      onDigit: _appendDigit,
      onBackspace: _backspace,
      onClear: () => _setControllerText(''),
      onNext: () {
        setState(() {
          _isKeyboardVisible = false;
        });
      },
      onClose: () {
        setState(() {
          _isKeyboardVisible = false;
        });
      },
    );

    if (!useSideKeyboard) {
      return Center(child: keyboard);
    }

    return SizedBox(width: 360, child: keyboard);
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

class ClientCodeIdentificationData {
  const ClientCodeIdentificationData({required this.clientCode});

  final String clientCode;
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
