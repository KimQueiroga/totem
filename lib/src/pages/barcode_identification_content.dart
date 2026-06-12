import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/numeric_touch_keyboard.dart';

class BarcodeIdentificationContent extends StatefulWidget {
  const BarcodeIdentificationContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.onHome,
    required this.onBack,
    required this.onSubmit,
    this.isSubmitting = false,
    this.message,
    this.isSuccess,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final ValueChanged<BarcodeIdentificationData> onSubmit;
  final bool isSubmitting;
  final String? message;
  final bool? isSuccess;

  @override
  State<BarcodeIdentificationContent> createState() =>
      _BarcodeIdentificationContentState();
}

class _BarcodeIdentificationContentState
    extends State<BarcodeIdentificationContent> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  bool _isKeyboardVisible = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSubmit(
      BarcodeIdentificationData(
        barcode: _digitsOnly(_barcodeController.text),
      ),
    );
  }

  void _appendDigit(String digit) {
    final digits = _digitsOnly(_barcodeController.text);

    if (digits.length >= 14) {
      return;
    }

    _setControllerText('$digits$digit');
  }

  void _backspace() {
    final digits = _digitsOnly(_barcodeController.text);

    if (digits.isEmpty) {
      return;
    }

    _setControllerText(digits.substring(0, digits.length - 1));
  }

  void _setControllerText(String text) {
    _barcodeController.value = TextEditingValue(
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
                  'Leitura por codigo de barras',
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
                      bottom: _isKeyboardVisible && !useSideKeyboard ? 300 : 96,
                    ),
                    child: Align(
                      alignment: useSideKeyboard && _isKeyboardVisible
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (widget.message != null) ...[
                                _BarcodeMessageBanner(
                                  message: widget.message!,
                                  color: primaryColor,
                                  isSuccess: widget.isSuccess == true,
                                ),
                                const SizedBox(height: 20),
                              ],
                              TextFormField(
                                key: const ValueKey(
                                  'barcode-identification-code',
                                ),
                                controller: _barcodeController,
                                showCursor: true,
                                autofocus: true,
                                onTap: () {
                                  setState(() {
                                    _isKeyboardVisible = true;
                                  });
                                },
                                decoration: _inputDecoration(primaryColor),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(14),
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) {
                                  final digits = _digitsOnly(value ?? '');

                                  if (digits.length != 14) {
                                    return 'Informe os 14 digitos da etiqueta.';
                                  }

                                  if (!digits.startsWith('01') ||
                                      !digits.endsWith('00')) {
                                    return 'Etiqueta invalida para impressao de resultado.';
                                  }

                                  return null;
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

  InputDecoration _inputDecoration(Color primaryColor) {
    return InputDecoration(
      labelText: 'Codigo de barras',
      helperText: _isKeyboardVisible ? 'Digite usando o teclado na tela.' : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: _isKeyboardVisible ? primaryColor : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildKeyboard(Color buttonColor, bool useSideKeyboard) {
    final keyboard = NumericTouchKeyboard(
      color: buttonColor,
      activeFieldLabel: 'Codigo de barras',
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
              : const Icon(Icons.print_outlined),
          onPressed: _submit,
          label: Text(widget.isSubmitting ? 'Imprimindo...' : 'Imprimir'),
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

class _BarcodeMessageBanner extends StatelessWidget {
  const _BarcodeMessageBanner({
    required this.message,
    required this.color,
    required this.isSuccess,
  });

  final String message;
  final Color color;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final bannerColor = isSuccess ? Colors.green.shade700 : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.10),
        border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: bannerColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: bannerColor,
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

class BarcodeIdentificationData {
  const BarcodeIdentificationData({required this.barcode});

  final String barcode;
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
