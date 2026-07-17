import 'package:flutter/material.dart';

import '../models/questionnaire.dart';
import 'numeric_touch_keyboard.dart';

class QuestionnaireDialog extends StatefulWidget {
  const QuestionnaireDialog({
    super.key,
    required this.primaryColor,
    required this.questionnaireSets,
    required this.initialAnswers,
  });

  final Color primaryColor;
  final List<ExamQuestionnaireSet> questionnaireSets;
  final List<QuestionnaireAnswer> initialAnswers;

  @override
  State<QuestionnaireDialog> createState() => _QuestionnaireDialogState();
}

class _QuestionnaireStep {
  const _QuestionnaireStep({
    required this.set,
    required this.question,
  });

  final ExamQuestionnaireSet set;
  final QuestionnaireQuestion question;

  String get answerKey {
    return [
      set.examCode,
      set.material,
      question.questionnaireCode,
      question.id,
      question.description,
    ].join('|');
  }
}

class _QuestionnaireDialogState extends State<QuestionnaireDialog> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _answers = <String, String>{};
  late final List<_QuestionnaireStep> _steps;
  int _currentIndex = 0;
  bool _keyboardOpen = false;
  bool _isUpperCase = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _steps = [
      for (final set in widget.questionnaireSets)
        for (final question in set.questions)
          _QuestionnaireStep(set: set, question: question),
    ];

    for (final answer in widget.initialAnswers) {
      final key = [
        answer.examCode,
        answer.material,
        answer.questionnaireCode,
        answer.questionId,
        answer.question,
      ].join('|');
      _answers[key] = answer.answer;
    }

    if (_steps.isNotEmpty) {
      _syncTextController();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        title: const Text('Questionario'),
        content: const Text('Nenhuma pergunta encontrada para responder.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.primaryColor),
            onPressed: () =>
                Navigator.of(context).pop(const <QuestionnaireAnswer>[]),
            child: const Text('Continuar'),
          ),
        ],
      );
    }

    final step = _currentStep;
    final question = step.question;
    final options = question.answerOptions;
    final inputKind = question.inputKind;
    final selectedAnswer = _answers[step.answerKey] ?? '';
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _steps.length - 1;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      title: Text('Questionario - ${step.set.examLabel}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 560),
        child: SizedBox(
          width: 860,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Responda de acordo com as informacoes do paciente.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _steps.length,
                color: widget.primaryColor,
                backgroundColor: widget.primaryColor.withOpacity(0.12),
              ),
              const SizedBox(height: 10),
              Text(
                'Pergunta ${_currentIndex + 1} de ${_steps.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        question.description,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (question.mandatory)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Obrigatorio',
                            style: TextStyle(
                              color: widget.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (options.isNotEmpty)
                        _QuestionnaireOptions(
                          options: options,
                          selectedAnswer: selectedAnswer,
                          primaryColor: widget.primaryColor,
                          onSelected: (value) {
                            setState(() {
                              _answers[step.answerKey] = value;
                              _errorMessage = null;
                            });
                          },
                        )
                      else
                        TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: inputKind == QuestionnaireInputKind.text
                              ? 2
                              : 1,
                          keyboardType: _keyboardType(inputKind),
                          onTap: () => setState(() => _keyboardOpen = true),
                          onChanged: _handleTextChanged,
                          decoration: InputDecoration(
                            labelText: _inputLabel(question),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_keyboardOpen && options.isEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 560,
                    child: NumericTouchKeyboard(
                      color: widget.primaryColor,
                      activeFieldLabel: _inputLabel(question),
                      nextLabel: 'Concluir',
                      layout: _touchKeyboardLayout(inputKind),
                      includeSpace: inputKind == QuestionnaireInputKind.text,
                      isUpperCase: _isUpperCase,
                      compact: true,
                      borderRadius: BorderRadius.circular(8),
                      onToggleLetterCase: () {
                        setState(() => _isUpperCase = !_isUpperCase);
                      },
                      onDigit: _appendKeyboardValue,
                      onBackspace: _backspaceKeyboardValue,
                      onClear: _clearKeyboardField,
                      onNext: _closeKeyboard,
                      onClose: _closeKeyboard,
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.primaryColor,
            side: BorderSide(color: widget.primaryColor),
          ),
          onPressed: isFirst ? null : _previous,
          child: const Text('Voltar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.primaryColor),
          onPressed: isLast ? _finish : _next,
          child: Text(isLast ? 'Salvar respostas' : 'Proxima'),
        ),
      ],
    );
  }

  _QuestionnaireStep get _currentStep => _steps[_currentIndex];

  void _previous() {
    if (_currentIndex == 0) {
      return;
    }

    setState(() {
      _currentIndex--;
      _keyboardOpen = false;
      _errorMessage = null;
      _syncTextController();
    });
  }

  void _next() {
    if (!_validateCurrentAnswer()) {
      return;
    }

    setState(() {
      _currentIndex++;
      _keyboardOpen = false;
      _errorMessage = null;
      _syncTextController();
    });
  }

  void _finish() {
    if (!_validateCurrentAnswer()) {
      return;
    }

    Navigator.of(context).pop(_buildAnswers());
  }

  bool _validateCurrentAnswer() {
    final step = _currentStep;
    final answer = (_answers[step.answerKey] ?? '').trim();

    if (step.question.mandatory && answer.isEmpty) {
      setState(() {
        _errorMessage = 'Responda esta pergunta para continuar.';
      });
      return false;
    }

    return true;
  }

  List<QuestionnaireAnswer> _buildAnswers() {
    return [
      for (final step in _steps)
        if ((_answers[step.answerKey] ?? '').trim().isNotEmpty)
          QuestionnaireAnswer(
            examCode: step.set.examCode,
            material: step.set.material,
            questionnaireCode: step.question.questionnaireCode,
            questionId: step.question.id,
            question: step.question.description,
            answer: _answers[step.answerKey]!.trim(),
          ),
    ];
  }

  void _syncTextController() {
    final value = _answers[_currentStep.answerKey] ?? '';
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _appendKeyboardValue(String value) {
    final inputKind = _currentStep.question.inputKind;
    final selection = _textController.selection;
    final text = _textController.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = _normalizeInput(
      text.replaceRange(start, end, value),
      inputKind,
    );
    final offset = start + value.length;

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: offset > newText.length ? newText.length : offset,
      ),
    );
    _answers[_currentStep.answerKey] = newText;
  }

  void _backspaceKeyboardValue() {
    final inputKind = _currentStep.question.inputKind;
    final selection = _textController.selection;
    final text = _textController.text;

    if (text.isEmpty) {
      return;
    }

    if (selection.start != selection.end &&
        selection.start >= 0 &&
        selection.end >= 0) {
      final newText = _normalizeInput(
        text.replaceRange(selection.start, selection.end, ''),
        inputKind,
      );
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start > newText.length
              ? newText.length
              : selection.start,
        ),
      );
      _answers[_currentStep.answerKey] = newText;
      return;
    }

    final offset = selection.start > 0 ? selection.start : text.length;

    if (offset <= 0) {
      return;
    }

    final newText = _normalizeInput(
      _removeLastInputValue(text, inputKind, offset),
      inputKind,
    );
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _answers[_currentStep.answerKey] = newText;
  }

  void _clearKeyboardField() {
    _textController.clear();
    _answers[_currentStep.answerKey] = '';
  }

  void _closeKeyboard() {
    setState(() => _keyboardOpen = false);
  }

  void _handleTextChanged(String value) {
    final inputKind = _currentStep.question.inputKind;
    final normalized = _normalizeInput(value, inputKind);

    if (normalized != value) {
      _textController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    _answers[_currentStep.answerKey] = normalized;
    _errorMessage = null;
  }

  TextInputType _keyboardType(QuestionnaireInputKind inputKind) {
    return switch (inputKind) {
      QuestionnaireInputKind.date => TextInputType.datetime,
      QuestionnaireInputKind.time => TextInputType.datetime,
      QuestionnaireInputKind.numeric => TextInputType.number,
      _ => TextInputType.text,
    };
  }

  TouchKeyboardLayout _touchKeyboardLayout(QuestionnaireInputKind inputKind) {
    return switch (inputKind) {
      QuestionnaireInputKind.text => TouchKeyboardLayout.alphanumeric,
      _ => TouchKeyboardLayout.numeric,
    };
  }

  String _inputLabel(QuestionnaireQuestion question) {
    return switch (question.inputKind) {
      QuestionnaireInputKind.date => 'Data',
      QuestionnaireInputKind.time => 'Hora',
      QuestionnaireInputKind.numeric => 'Numero',
      _ => 'Resposta',
    };
  }

  String _normalizeInput(String value, QuestionnaireInputKind inputKind) {
    return switch (inputKind) {
      QuestionnaireInputKind.date => _formatDateInput(value),
      QuestionnaireInputKind.time => _formatTimeInput(value),
      QuestionnaireInputKind.numeric => _numericCharacters(value),
      _ => value,
    };
  }

  String _removeLastInputValue(
    String value,
    QuestionnaireInputKind inputKind,
    int offset,
  ) {
    if (inputKind == QuestionnaireInputKind.date ||
        inputKind == QuestionnaireInputKind.time ||
        inputKind == QuestionnaireInputKind.numeric) {
      final digits = _digitsOnly(value);

      if (digits.isEmpty) {
        return '';
      }

      return digits.substring(0, digits.length - 1);
    }

    return value.replaceRange(offset - 1, offset, '');
  }
}

String _formatDateInput(String value) {
  final digits = _digitsOnly(value);
  final limited = digits.length > 8 ? digits.substring(0, 8) : digits;

  if (limited.length <= 2) {
    return limited;
  }

  if (limited.length <= 4) {
    return '${limited.substring(0, 2)}/${limited.substring(2)}';
  }

  return '${limited.substring(0, 2)}/${limited.substring(2, 4)}/${limited.substring(4)}';
}

String _formatTimeInput(String value) {
  final digits = _digitsOnly(value);
  final limited = digits.length > 4 ? digits.substring(0, 4) : digits;

  if (limited.length <= 2) {
    return limited;
  }

  return '${limited.substring(0, 2)}:${limited.substring(2)}';
}

String _numericCharacters(String value) {
  return value
      .split('')
      .where((character) => RegExp(r'[\d,.]').hasMatch(character))
      .join();
}

String _digitsOnly(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

class _QuestionnaireOptions extends StatelessWidget {
  const _QuestionnaireOptions({
    required this.options,
    required this.selectedAnswer,
    required this.primaryColor,
    required this.onSelected,
  });

  final List<QuestionnaireResponse> options;
  final String selectedAnswer;
  final Color primaryColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          SizedBox(
            width: 190,
            height: 52,
            child: option.answerValue == selectedAnswer
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onSelected(option.answerValue),
                    child: Text(_optionLabel(option)),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onSelected(option.answerValue),
                    child: Text(_optionLabel(option)),
                  ),
          ),
      ],
    );
  }

  String _optionLabel(QuestionnaireResponse option) {
    final description = option.description.trim();

    return description.isEmpty ? option.type : description;
  }
}
