import 'package:flutter/material.dart';

class NumericTouchKeyboard extends StatelessWidget {
  const NumericTouchKeyboard({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onNext,
    required this.onClose,
    required this.color,
    required this.activeFieldLabel,
    this.nextLabel = 'Proximo',
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(8)),
    this.layout = TouchKeyboardLayout.numeric,
    this.isUpperCase = false,
    this.onToggleLetterCase,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final Color color;
  final String activeFieldLabel;
  final String nextLabel;
  final BorderRadiusGeometry borderRadius;
  final TouchKeyboardLayout layout;
  final bool isUpperCase;
  final VoidCallback? onToggleLetterCase;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 18,
      color: Colors.white,
      borderRadius: borderRadius,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Digitando: $activeFieldLabel',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('numeric-touch-key-next'),
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        nextLabel == 'Concluir'
                            ? Icons.check
                            : Icons.arrow_forward,
                      ),
                      label: Text(nextLabel),
                    ),
                    IconButton(
                      key: const ValueKey('numeric-touch-key-close'),
                      tooltip: 'Fechar teclado',
                      onPressed: onClose,
                      icon: Icon(Icons.keyboard_hide_outlined, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final row in _rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (final digit in row) ...[
                          Expanded(
                            child: _KeyboardButton(
                              key: ValueKey('numeric-touch-key-$digit'),
                              label: digit,
                              color: color,
                              onPressed: () => onDigit(digit),
                            ),
                          ),
                          if (digit != row.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(child: _firstActionButton),
                    const SizedBox(width: 8),
                    Expanded(child: _secondActionButton),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KeyboardButton(
                        key: const ValueKey('numeric-touch-key-backspace'),
                        icon: Icons.backspace_outlined,
                        color: color,
                        isSecondary: true,
                        onPressed: onBackspace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<List<String>> get _rows {
    return switch (layout) {
      TouchKeyboardLayout.numeric => const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
      ],
      TouchKeyboardLayout.alphanumeric => [
        '1234567890'.split(''),
        _letters('qwertyuiop'),
        _letters('asdfghjkl'),
        _letters('zxcvbnm'),
        const ['@', '#', '*', '?', '!', '-', '_', '.', '+'],
      ],
    };
  }

  Widget get _firstActionButton {
    if (layout == TouchKeyboardLayout.alphanumeric) {
      return _KeyboardButton(
        key: const ValueKey('numeric-touch-key-case'),
        label: isUpperCase ? 'abc' : 'ABC',
        color: color,
        isSecondary: true,
        onPressed: onToggleLetterCase ?? () {},
      );
    }

    return _KeyboardButton(
      key: const ValueKey('numeric-touch-key-clear'),
      label: 'Limpar',
      color: color,
      isSecondary: true,
      onPressed: onClear,
    );
  }

  Widget get _secondActionButton {
    if (layout == TouchKeyboardLayout.alphanumeric) {
      return _KeyboardButton(
        key: const ValueKey('numeric-touch-key-clear'),
        label: 'Limpar',
        color: color,
        isSecondary: true,
        onPressed: onClear,
      );
    }

    return _KeyboardButton(
      key: const ValueKey('numeric-touch-key-0'),
      label: '0',
      color: color,
      onPressed: () => onDigit('0'),
    );
  }

  List<String> _letters(String row) {
    final values = row.split('');

    return isUpperCase
        ? values.map((value) => value.toUpperCase()).toList()
        : values;
  }
}

enum TouchKeyboardLayout { numeric, alphanumeric }

class _KeyboardButton extends StatelessWidget {
  const _KeyboardButton({
    super.key,
    required this.color,
    required this.onPressed,
    this.label,
    this.icon,
    this.isSecondary = false,
  });

  final String? label;
  final IconData? icon;
  final bool isSecondary;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSecondary ? color : Colors.white;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : color,
          foregroundColor: foregroundColor,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: icon == null
            ? Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                  fontSize: label!.length > 1 ? 18 : 22,
                ),
              )
            : Icon(icon, color: foregroundColor),
      ),
    );
  }
}
