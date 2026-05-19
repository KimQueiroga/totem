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
    final material = json['material'];

    return ExamSearchResult(
      id: json['id']?.toString() ?? '',
      mnemonic: json['mnemonic']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      materialMnemonic: material is Map<String, dynamic>
          ? material['mnemonic']?.toString() ?? ''
          : '',
      materialDescription: material is Map<String, dynamic>
          ? material['description']?.toString() ?? ''
          : '',
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
    this.error,
  });

  final String keyword;
  final List<ExamSearchResult> results;
  final String? error;

  bool get hasResults => results.isNotEmpty;
  ExamSearchResult? get firstResult =>
      results.isNotEmpty ? results.first : null;
}
