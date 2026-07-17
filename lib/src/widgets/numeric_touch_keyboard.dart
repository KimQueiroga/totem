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
    this.includeSpace = false,
    this.onToggleLetterCase,
    this.compact = false,
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
  final bool includeSpace;
  final VoidCallback? onToggleLetterCase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actionButtons = _actionButtons;
    final buttonHeight = compact ? 40.0 : 52.0;
    final spacing = compact ? 5.0 : 8.0;
    final padding = compact
        ? const EdgeInsets.fromLTRB(12, 8, 12, 10)
        : const EdgeInsets.fromLTRB(20, 12, 20, 20);

    return Material(
      elevation: 18,
      color: Colors.white,
      borderRadius: borderRadius,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
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
                              fontSize: compact ? 16 : null,
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
                    padding: EdgeInsets.only(bottom: spacing),
                    child: Row(
                      children: [
                        for (final digit in row) ...[
                          Expanded(
                            child: _KeyboardButton(
                              key: ValueKey('numeric-touch-key-$digit'),
                              label: digit,
                              color: color,
                              height: buttonHeight,
                              onPressed: () => onDigit(digit),
                            ),
                          ),
                          if (digit != row.last) SizedBox(width: spacing),
                        ],
                      ],
                    ),
                  ),
                Row(
                  children: [
                    for (final button in actionButtons) ...[
                      Expanded(child: button),
                      if (button != actionButtons.last) SizedBox(width: spacing),
                    ],
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
        const ['@', '#', '*', '?', '!', '-', '_', '.', ',', '+'],
      ],
    };
  }

  List<Widget> get _actionButtons {
    final buttonHeight = compact ? 40.0 : 52.0;

    if (layout == TouchKeyboardLayout.alphanumeric) {
      return [
        _KeyboardButton(
          key: const ValueKey('numeric-touch-key-case'),
          label: isUpperCase ? 'abc' : 'ABC',
          color: color,
          height: buttonHeight,
          isSecondary: true,
          onPressed: onToggleLetterCase ?? () {},
        ),
        if (includeSpace)
          _KeyboardButton(
            key: const ValueKey('numeric-touch-key-space'),
            label: 'Espaco',
            color: color,
            height: buttonHeight,
            isSecondary: true,
            onPressed: () => onDigit(' '),
          ),
        _KeyboardButton(
          key: const ValueKey('numeric-touch-key-clear'),
          label: 'Limpar',
          color: color,
          height: buttonHeight,
          isSecondary: true,
          onPressed: onClear,
        ),
        _KeyboardButton(
          key: const ValueKey('numeric-touch-key-backspace'),
          icon: Icons.backspace_outlined,
          color: color,
          height: buttonHeight,
          isSecondary: true,
          onPressed: onBackspace,
        ),
      ];
    }

    return [
      _KeyboardButton(
        key: const ValueKey('numeric-touch-key-clear'),
        label: 'Limpar',
        color: color,
        height: buttonHeight,
        isSecondary: true,
        onPressed: onClear,
      ),
      _KeyboardButton(
        key: const ValueKey('numeric-touch-key-0'),
        label: '0',
        color: color,
        height: buttonHeight,
        onPressed: () => onDigit('0'),
      ),
      _KeyboardButton(
        key: const ValueKey('numeric-touch-key-backspace'),
        icon: Icons.backspace_outlined,
        color: color,
        height: buttonHeight,
        isSecondary: true,
        onPressed: onBackspace,
      ),
    ];
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
    this.height = 52,
  });

  final String? label;
  final IconData? icon;
  final bool isSecondary;
  final Color color;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSecondary ? color : Colors.white;

    return SizedBox(
      height: height,
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
                  fontSize: height < 52
                      ? (label!.length > 1 ? 15 : 19)
                      : (label!.length > 1 ? 18 : 22),
                ),
              )
            : Icon(icon, color: foregroundColor),
      ),
    );
  }
}
