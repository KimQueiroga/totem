import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/numeric_touch_keyboard.dart';

class ClientConfirmationContent extends StatefulWidget {
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
  final ValueChanged<ClientProfileUpdate> onConfirm;

  @override
  State<ClientConfirmationContent> createState() =>
      _ClientConfirmationContentState();
}

class _ClientConfirmationContentState extends State<ClientConfirmationContent> {
  final _emailController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _homePhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  _EditableConfirmationField? _activeField;
  bool _isKeyboardVisible = false;
  bool _isUpperCase = false;

  @override
  void initState() {
    super.initState();
    _loadUser(widget.authentication.user);
  }

  @override
  void didUpdateWidget(covariant ClientConfirmationContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.authentication != widget.authentication) {
      _loadUser(widget.authentication.user);
      _closeKeyboard();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mobilePhoneController.dispose();
    _homePhoneController.dispose();
    _motherNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _loadUser(ClientUser user) {
    _emailController.text = user.email?.trim() ?? '';
    _mobilePhoneController.text = user.mobilePhoneNumber?.trim() ?? '';
    _homePhoneController.text = user.homePhoneNumber?.trim() ?? '';
    _motherNameController.text = user.motherName?.trim() ?? '';
    _addressController.text = user.streetAndComplement?.trim() ?? '';
    _cityController.text = user.cityAndState.trim();
  }

  void _setActiveField(_EditableConfirmationField field) {
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
    final activeField = _activeField;

    if (activeField == null) {
      _closeKeyboard();
      return;
    }

    final currentIndex = _editableFields.indexOf(activeField);
    final nextIndex = currentIndex + 1;

    if (nextIndex >= _editableFields.length) {
      _closeKeyboard();
      return;
    }

    _setActiveField(_editableFields[nextIndex]);
  }

  void _appendValue(String value) {
    final activeField = _activeField;

    if (activeField == null) {
      return;
    }

    if (activeField.layout == TouchKeyboardLayout.numeric &&
        !RegExp(r'^\d$').hasMatch(value)) {
      return;
    }

    final controller = activeField.controller(this);

    if (controller.text.length >= activeField.maxLength) {
      return;
    }

    _setControllerText(controller, '${controller.text}$value');
  }

  void _backspace() {
    final activeField = _activeField;

    if (activeField == null) {
      return;
    }

    final controller = activeField.controller(this);
    final value = controller.text;

    if (value.isEmpty) {
      return;
    }

    _setControllerText(controller, value.substring(0, value.length - 1));
  }

  void _clearActiveField() {
    final activeField = _activeField;

    if (activeField == null) {
      return;
    }

    _setControllerText(activeField.controller(this), '');
  }

  void _toggleLetterCase() {
    setState(() {
      _isUpperCase = !_isUpperCase;
    });
  }

  void _setControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _confirm() {
    widget.onConfirm(
      ClientProfileUpdate(
        authentication: widget.authentication,
        email: _emailController.text,
        mobilePhoneNumber: _mobilePhoneController.text,
        homePhoneNumber: _homePhoneController.text,
        motherName: _motherNameController.text,
        streetAndComplement: _addressController.text,
        cityAndState: _cityController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = widget.identity.buttonColor ?? primaryColor;
    final patientNameColor = widget.identity.patientNameColor ?? primaryColor;
    final user = widget.authentication.user;
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
                  logoBytes: widget.identity.logoBytes,
                  primaryColor: primaryColor,
                  title: widget.flowTitle,
                  onBack: widget.onBack,
                  onHome: widget.onHome,
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirme seus dados',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: patientNameColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confira os dados abaixo antes de continuar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fields = _buildFields(user, primaryColor);
                      final useTwoColumns =
                          !_isKeyboardVisible && constraints.maxWidth >= 720;

                      return SingleChildScrollView(
                        child: Align(
                          alignment: useSideKeyboard && _isKeyboardVisible
                              ? Alignment.centerLeft
                              : Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: useTwoColumns
                                  ? 900
                                  : useSideKeyboard && _isKeyboardVisible
                                  ? 400
                                  : 520,
                            ),
                            child: useTwoColumns
                                ? _TwoColumnFields(fields: fields)
                                : Column(children: fields),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!_isKeyboardVisible) ...[
                  const SizedBox(height: 20),
                  _buildActionButtons(primaryColor, buttonColor),
                ],
              ],
            ),
          ),
          if (_isKeyboardVisible)
            Positioned(
              left: useSideKeyboard ? null : 0,
              right: 0,
              top: useSideKeyboard ? 148 : null,
              bottom: useSideKeyboard ? null : 0,
              child: _buildKeyboard(buttonColor, useSideKeyboard),
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

    return height < 620 ? 620 : height;
  }

  bool _useSideKeyboard(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  Widget _buildKeyboard(Color buttonColor, bool useSideKeyboard) {
    final activeField = _activeField;

    if (activeField == null) {
      return const SizedBox.shrink();
    }

    final keyboard = NumericTouchKeyboard(
      color: buttonColor,
      activeFieldLabel: activeField.label,
      nextLabel: activeField == _editableFields.last ? 'Concluir' : 'Proximo',
      layout: activeField.layout,
      isUpperCase: _isUpperCase,
      includeSpace: activeField.includeSpace,
      onToggleLetterCase: _toggleLetterCase,
      borderRadius: useSideKeyboard
          ? BorderRadius.circular(8)
          : const BorderRadius.vertical(top: Radius.circular(8)),
      onDigit: _appendValue,
      onBackspace: _backspace,
      onClear: _clearActiveField,
      onNext: _goToNextField,
      onClose: _closeKeyboard,
    );

    if (!useSideKeyboard) {
      return Center(child: keyboard);
    }

    final width = activeField.layout == TouchKeyboardLayout.alphanumeric
        ? 560.0
        : 360.0;

    return SizedBox(width: width, child: keyboard);
  }

  List<Widget> _buildFields(ClientUser user, Color primaryColor) {
    return [
      _ReadOnlyConfirmationField(
        label: 'Nome',
        value: user.displayName,
        primaryColor: primaryColor,
      ),
      _ReadOnlyConfirmationField(
        label: 'CPF',
        value: _maskedCpf(user.cpf),
        primaryColor: primaryColor,
      ),
      _ReadOnlyConfirmationField(
        label: 'Data de nascimento',
        value: _formatDate(user.birthDate),
        primaryColor: primaryColor,
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.email.label,
        controller: _emailController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.email &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.email),
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.mobilePhone.label,
        controller: _mobilePhoneController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.mobilePhone &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.mobilePhone),
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.homePhone.label,
        controller: _homePhoneController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.homePhone &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.homePhone),
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.motherName.label,
        controller: _motherNameController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.motherName &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.motherName),
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.address.label,
        controller: _addressController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.address &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.address),
      ),
      _EditableConfirmationTextField(
        label: _EditableConfirmationField.city.label,
        controller: _cityController,
        primaryColor: primaryColor,
        isActive:
            _activeField == _EditableConfirmationField.city &&
            _isKeyboardVisible,
        onTap: () => _setActiveField(_EditableConfirmationField.city),
      ),
    ];
  }

  Widget _buildActionButtons(Color primaryColor, Color buttonColor) {
    return LayoutBuilder(
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
          onPressed: widget.onReject,
          child: const Text('Nao'),
        );
        final confirmButton = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _confirm,
          child: const Text('Sim'),
        );

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 56, child: confirmButton),
              const SizedBox(height: 16),
              SizedBox(height: 56, child: rejectButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: SizedBox(height: 56, child: rejectButton)),
            const SizedBox(width: 48),
            Expanded(child: SizedBox(height: 56, child: confirmButton)),
          ],
        );
      },
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var index = 0; index < fields.length; index += 2) {
      final rightIndex = index + 1;

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fields[index]),
            const SizedBox(width: 24),
            Expanded(
              child: rightIndex < fields.length
                  ? fields[rightIndex]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

class _ReadOnlyConfirmationField extends StatelessWidget {
  const _ReadOnlyConfirmationField({
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  final String label;
  final String? value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationFieldShell(
      child: TextFormField(
        readOnly: true,
        canRequestFocus: false,
        initialValue: _displayValue(value),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: Icon(Icons.lock_outline, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _EditableConfirmationTextField extends StatelessWidget {
  const _EditableConfirmationTextField({
    required this.label,
    required this.controller,
    required this.primaryColor,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final Color primaryColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationFieldShell(
      child: TextFormField(
        controller: controller,
        readOnly: true,
        showCursor: true,
        canRequestFocus: false,
        onTap: onTap,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: Icon(
            Icons.keyboard_alt_outlined,
            color: isActive ? primaryColor : Colors.grey,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isActive ? primaryColor : Colors.grey,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ConfirmationFieldShell extends StatelessWidget {
  const _ConfirmationFieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  }
}

const _editableFields = [
  _EditableConfirmationField.email,
  _EditableConfirmationField.mobilePhone,
  _EditableConfirmationField.homePhone,
  _EditableConfirmationField.motherName,
  _EditableConfirmationField.address,
  _EditableConfirmationField.city,
];

enum _EditableConfirmationField {
  email,
  mobilePhone,
  homePhone,
  motherName,
  address,
  city,
}

extension on _EditableConfirmationField {
  String get label {
    return switch (this) {
      _EditableConfirmationField.email => 'E-mail',
      _EditableConfirmationField.mobilePhone => 'Celular',
      _EditableConfirmationField.homePhone => 'Telefone',
      _EditableConfirmationField.motherName => 'Nome da mae',
      _EditableConfirmationField.address => 'Endereco',
      _EditableConfirmationField.city => 'Cidade/UF',
    };
  }

  TouchKeyboardLayout get layout {
    return switch (this) {
      _EditableConfirmationField.mobilePhone ||
      _EditableConfirmationField.homePhone => TouchKeyboardLayout.numeric,
      _ => TouchKeyboardLayout.alphanumeric,
    };
  }

  bool get includeSpace {
    return switch (this) {
      _EditableConfirmationField.motherName ||
      _EditableConfirmationField.address ||
      _EditableConfirmationField.city => true,
      _ => false,
    };
  }

  int get maxLength {
    return switch (this) {
      _EditableConfirmationField.mobilePhone ||
      _EditableConfirmationField.homePhone => 14,
      _EditableConfirmationField.email => 80,
      _ => 120,
    };
  }

  TextEditingController controller(_ClientConfirmationContentState state) {
    return switch (this) {
      _EditableConfirmationField.email => state._emailController,
      _EditableConfirmationField.mobilePhone => state._mobilePhoneController,
      _EditableConfirmationField.homePhone => state._homePhoneController,
      _EditableConfirmationField.motherName => state._motherNameController,
      _EditableConfirmationField.address => state._addressController,
      _EditableConfirmationField.city => state._cityController,
    };
  }
}

String _displayValue(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '-';
  }

  return value.trim();
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
