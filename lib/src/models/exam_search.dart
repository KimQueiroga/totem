class ExamSearchResult {
  const ExamSearchResult({
    required this.id,
    required this.mnemonic,
    required this.description,
    required this.materialMnemonic,
    required this.materialDescription,
    required this.negotiatedCodes,
    required this.sampleConditionIsRequired,
    required this.sampleDescriptionIsRequired,
  });

  factory ExamSearchResult.fromJson(Map<String, dynamic> json) {
    final exam = _firstNestedMap(json, const ['exam', 'exame', 'procedure']);
    final material = _firstNestedMap(json, const ['material', 'sampleMaterial']);

    return ExamSearchResult(
      id: json['id']?.toString() ?? '',
      mnemonic: _extractFirstString([
        json,
        if (exam != null) exam,
      ], const [
        'mnemonic',
        'mnemonico',
        'mnemonicCode',
        'mnemonic_code',
        'sigla',
        'siglaExame',
        'mnemonicoExame',
      ]),
      description:
          json['description']?.toString() ??
          json['descricao']?.toString() ??
          exam?['description']?.toString() ??
          exam?['descricao']?.toString() ??
          '',
      materialMnemonic: material is Map<String, dynamic>
          ? _extractFirstString([material], const [
              'mnemonic',
              'mnemonico',
              'mnemonicCode',
              'mnemonic_code',
              'sigla',
              'code',
              'codigo',
              'codigoMaterial',
            ])
          : _extractFirstString([json], const [
              'materialMnemonic',
              'mnemonicoMaterial',
              'codigoMaterial',
              'materialCode',
            ]),
      materialDescription: material is Map<String, dynamic>
          ? material['description']?.toString() ??
                material['descricao']?.toString() ??
                ''
          : json['materialDescription']?.toString() ??
                json['descricaoMaterial']?.toString() ??
                '',
      negotiatedCodes: json['negotiatedCode'] is List
          ? List<String>.from(
              (json['negotiatedCode'] as List).map(
                (item) => item?.toString() ?? '',
              ),
            )
          : const [],
      sampleConditionIsRequired: json['sampleConditionIsRequired'] == true,
      sampleDescriptionIsRequired: json['sampleDescriptionIsRequired'] == true,
    );
  }

  final String id;
  final String mnemonic;
  final String description;
  final String materialMnemonic;
  final String materialDescription;
  final List<String> negotiatedCodes;
  final bool sampleConditionIsRequired;
  final bool sampleDescriptionIsRequired;
}

class ProcedureExamSearch {
  const ProcedureExamSearch({
    required this.keyword,
    required this.results,
    this.fallbackExamMnemonic = '',
    this.fallbackDescription = '',
    this.fallbackMaterialCode = '',
    this.fallbackMaterialDescription = '',
    this.fallbackSampleCondition = '',
    this.error,
  });

  final String keyword;
  final List<ExamSearchResult> results;
  final String fallbackExamMnemonic;
  final String fallbackDescription;
  final String fallbackMaterialCode;
  final String fallbackMaterialDescription;
  final String fallbackSampleCondition;
  final String? error;

  bool get hasResults => results.isNotEmpty;
  ExamSearchResult? get firstResult =>
      results.isNotEmpty ? results.first : null;
}

Map<String, dynamic>? _firstNestedMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];

    if (value is Map<String, dynamic>) {
      return value;
    }
  }

  return null;
}

String _extractFirstString(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    for (final key in keys) {
      final value = source[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is num) {
        return value.toString();
      }
    }
  }

  return '';
}
