class ExamQuestionnaireCheck {
  const ExamQuestionnaireCheck({required this.examHasQuestionnaire});

  factory ExamQuestionnaireCheck.fromJson(Map<String, dynamic> json) {
    return ExamQuestionnaireCheck(
      examHasQuestionnaire:
          json['examHasQuestionnaire'] == true ||
          json['examHasQuestionnaire']?.toString().toLowerCase() == 'true',
    );
  }

  final bool examHasQuestionnaire;
}

class ExamQuestionnaire {
  const ExamQuestionnaire({
    required this.id,
    required this.code,
    required this.description,
    required this.questions,
  });

  factory ExamQuestionnaire.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];

    return ExamQuestionnaire(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      questions: questions is List
          ? questions
                .whereType<Map<String, dynamic>>()
                .map(QuestionnaireQuestion.fromJson)
                .toList()
          : const [],
    );
  }

  final String id;
  final String code;
  final String description;
  final List<QuestionnaireQuestion> questions;
}

class QuestionnaireQuestion {
  const QuestionnaireQuestion({
    required this.id,
    required this.questionnaireCode,
    required this.description,
    required this.format,
    required this.template,
    required this.responseTypeCode,
    required this.answerType,
    required this.mandatory,
    required this.inviolable,
    required this.violableWithTerm,
    required this.allowConsolidation,
    required this.responses,
  });

  factory QuestionnaireQuestion.fromJson(Map<String, dynamic> json) {
    return QuestionnaireQuestion(
      id: json['id']?.toString() ?? '',
      questionnaireCode: json['questionnaireCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      template: json['template']?.toString() ?? '',
      responseTypeCode: _extractResponseTypeCode(json),
      answerType: json['answerType']?.toString() ?? '',
      mandatory: _boolValue(json['mandatory']),
      inviolable: _boolValue(json['inviolable']),
      violableWithTerm: _boolValue(json['violableWithTerm']),
      allowConsolidation: _boolValue(json['allowConsolidation']),
      responses: _extractResponses(json['responses']),
    );
  }

  final String id;
  final String questionnaireCode;
  final String description;
  final String format;
  final String template;
  final String responseTypeCode;
  final String answerType;
  final bool mandatory;
  final bool inviolable;
  final bool violableWithTerm;
  final bool allowConsolidation;
  final List<QuestionnaireResponse> responses;

  String get stableKey => '$questionnaireCode|$id|$description';

  List<QuestionnaireResponse> get answerOptions {
    if (responses.isNotEmpty) {
      return responses;
    }

    final optionsByType = _optionsForResponseType(responseTypeCode);

    if (optionsByType.isNotEmpty) {
      return optionsByType;
    }

    final normalizedType = answerType.toUpperCase();
    if (normalizedType.contains('SIM') && normalizedType.contains('NAO')) {
      return const [
        QuestionnaireResponse(type: 'S', description: 'Sim'),
        QuestionnaireResponse(type: 'N', description: 'Nao'),
      ];
    }

    if (normalizedType.contains('/')) {
      return normalizedType
          .split('/')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .map((item) => QuestionnaireResponse(type: item, description: item))
          .toList();
    }

    return const [];
  }

  QuestionnaireInputKind get inputKind {
    if (answerOptions.isNotEmpty) {
      return QuestionnaireInputKind.options;
    }

    final normalizedTypeCode = responseTypeCode.toUpperCase();
    final normalizedFormat = format.toUpperCase();
    final normalizedAnswerType = answerType.toUpperCase();

    if (normalizedTypeCode == 'TP05' || normalizedFormat.contains('DDMM')) {
      return QuestionnaireInputKind.date;
    }

    if (normalizedTypeCode == 'TP06' || normalizedFormat.contains('HH')) {
      return QuestionnaireInputKind.time;
    }

    if (const {'TP04', 'TP07', 'TP08', 'TP09'}.contains(normalizedTypeCode) ||
        normalizedAnswerType.contains('NUMERICO') ||
        normalizedFormat.contains('CARACTERES')) {
      return QuestionnaireInputKind.numeric;
    }

    return QuestionnaireInputKind.text;
  }
}

enum QuestionnaireInputKind { options, text, numeric, date, time }

class QuestionnaireResponse {
  const QuestionnaireResponse({
    required this.type,
    required this.description,
  });

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';

    return QuestionnaireResponse(
      type: type,
      description:
          json['description']?.toString() ??
          json['descricao']?.toString() ??
          json['label']?.toString() ??
          json['value']?.toString() ??
          type,
    );
  }

  final String type;
  final String description;

  String get answerValue {
    final normalizedType = type.trim();

    return normalizedType.isEmpty ? description.trim() : normalizedType;
  }
}

class ExamQuestionnaireSet {
  const ExamQuestionnaireSet({
    required this.examCode,
    required this.examLabel,
    required this.material,
    required this.questionnaires,
  });

  final String examCode;
  final String examLabel;
  final String material;
  final List<ExamQuestionnaire> questionnaires;

  List<QuestionnaireQuestion> get questions {
    return [
      for (final questionnaire in questionnaires)
        for (final question in questionnaire.questions) question,
    ];
  }
}

class QuestionnaireAnswer {
  const QuestionnaireAnswer({
    required this.examCode,
    required this.material,
    required this.questionnaireCode,
    required this.questionId,
    required this.question,
    required this.answer,
  });

  final String examCode;
  final String material;
  final String questionnaireCode;
  final String questionId;
  final String question;
  final String answer;
}

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();

  return normalized == 'true' || normalized == 's' || normalized == '1';
}

List<QuestionnaireResponse> _extractResponses(Object? payload) {
  if (payload is List) {
    return payload
        .whereType<Map<String, dynamic>>()
        .map(QuestionnaireResponse.fromJson)
        .toList();
  }

  if (payload is Map<String, dynamic>) {
    for (final key in ['items', 'responses', 'options', 'values']) {
      final values = payload[key];
      if (values is List) {
        return values
            .whereType<Map<String, dynamic>>()
            .map(QuestionnaireResponse.fromJson)
            .toList();
      }
    }

    final hasDisplayValue =
        payload.containsKey('description') ||
        payload.containsKey('descricao') ||
        payload.containsKey('label') ||
        payload.containsKey('value');
    if (hasDisplayValue && payload['type'] != null) {
      return [QuestionnaireResponse.fromJson(payload)];
    }
  }

  return const [];
}

String _extractResponseTypeCode(Map<String, dynamic> json) {
  final payload = json['response'] ?? json['responses'];

  if (payload is Map<String, dynamic>) {
    final type = payload['type']?.toString().trim() ?? '';

    if (type.isNotEmpty) {
      return type;
    }
  }

  return json['responseTypeCode']?.toString().trim() ??
      json['responseType']?.toString().trim() ??
      '';
}

List<QuestionnaireResponse> _optionsForResponseType(String responseTypeCode) {
  return switch (responseTypeCode.trim().toUpperCase()) {
    'TP03' => const [
        QuestionnaireResponse(type: 'S', description: 'Sim'),
        QuestionnaireResponse(type: 'N', description: 'Nao'),
      ],
    'TP10' => _options(['Local', 'Oral']),
    'TP11' => _options(['Laboratorio', 'Casa', 'Outros']),
    'TP12' => _options(['Oral', 'Local', 'Ambos', 'NA']),
    'TP13' => _options(['Home office', 'Presencial']),
    'TP14' => _options([
        'Febre',
        'Tosse',
        'Falta de ar',
        'Coriza',
        'Dor de garganta',
        'Perda de olfato',
        'Nenhum',
      ]),
    'TP15' => _options(['24', '48', '72']),
    _ => const [],
  };
}

List<QuestionnaireResponse> _options(List<String> values) {
  return [
    for (final value in values)
      QuestionnaireResponse(type: value, description: value),
  ];
}
