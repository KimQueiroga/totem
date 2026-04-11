import 'package:flutter/material.dart';

class NumericTouchKeyboard extends StatelessWidget {
  const NumericTouchKeyboard({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.color,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                    if (digit != row.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _KeyboardButton(
                  key: const ValueKey('numeric-touch-key-clear'),
                  label: 'Limpar',
                  color: color,
                  isSecondary: true,
                  onPressed: onClear,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KeyboardButton(
                  key: const ValueKey('numeric-touch-key-0'),
                  label: '0',
                  color: color,
                  onPressed: () => onDigit('0'),
                ),
              ),
              const SizedBox(width: 12),
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
    );
  }
}

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
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : color,
          foregroundColor: foregroundColor,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: icon == null
            ? Text(
                label!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Icon(icon, color: foregroundColor),
      ),
    );
  }
}
