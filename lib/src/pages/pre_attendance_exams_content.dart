import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/exam_search.dart';
import '../models/pre_attendance.dart';
import '../models/questionnaire.dart';
import '../models/terminal_visual_identity.dart';
import '../models/third_party_authorization.dart';
import '../services/terminal_api.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/questionnaire_dialog.dart';
import '../widgets/third_party_authorization_dialog.dart';

class PreAttendanceExamsContent extends StatefulWidget {
  const PreAttendanceExamsContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.guide,
    required this.examSearchFuture,
    required this.onBack,
    required this.onHome,
    this.authentication,
    this.clientCode,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final ClientAuthentication? authentication;
  final String? clientCode;
  final PreAttendanceGuide guide;
  final Future<List<ProcedureExamSearch>> examSearchFuture;
  final VoidCallback onBack;
  final VoidCallback onHome;

  @override
  State<PreAttendanceExamsContent> createState() =>
      _PreAttendanceExamsContentState();
}

class _PreAttendanceExamsContentState extends State<PreAttendanceExamsContent> {
  final List<_ExamSelection> _examSelections = [];
  List<ThirdPartyAuthorization> _thirdPartyAuthorizations = const [];
  List<QuestionnaireAnswer> _questionnaireAnswers = const [];
  List<ProcedureExamSearch> _latestExamResults = const [];
  bool _thirdPartyUnidentified = false;
  bool _isLoadingQuestionnaires = false;
  late Future<List<String>> _relationships;

  @override
  void initState() {
    super.initState();
    _relationships = fetchRelationships();
  }

  @override
  void didUpdateWidget(covariant PreAttendanceExamsContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.examSearchFuture != widget.examSearchFuture ||
        _guideKey(oldWidget.guide) != _guideKey(widget.guide)) {
      _examSelections.clear();
      _thirdPartyAuthorizations = const [];
      _questionnaireAnswers = const [];
      _latestExamResults = const [];
      _thirdPartyUnidentified = false;
      _isLoadingQuestionnaires = false;
      _relationships = fetchRelationships();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : _pageHeight(context);

        return SizedBox(
          height: height,
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
              const SizedBox(height: 12),
              _PatientSummary(
                authentication: widget.authentication,
                clientCode: widget.clientCode,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 14),
              Text(
                'Exames autorizados',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: widget.identity.patientNameColor ?? primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Guia ${widget.guide.operatorGuideNumber} · Pre atendimento ${widget.guide.preAttendanceNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<ProcedureExamSearch>>(
                  future: widget.examSearchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return _ErrorMessage(
                        primaryColor: primaryColor,
                        message:
                            'Nao foi possivel buscar os exames autorizados.',
                        details: snapshot.error.toString(),
                      );
                    }

                    final results = snapshot.data ?? const [];
                    _syncExamSelections(results);

                    if (results.isEmpty) {
                      return _ErrorMessage(
                        primaryColor: primaryColor,
                        message: 'Nenhum exame autorizado encontrado.',
                        details:
                            'Verifique o pre atendimento ou tente novamente.',
                      );
                    }

                    return _ExamResultTable(
                      results: results,
                      selections: _examSelections,
                      primaryColor: primaryColor,
                      onSelectionChanged: () => setState(() {}),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: widget.onBack,
                        child: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: _isLoadingQuestionnaires ? null : _handleNext,
                        child: _isLoadingQuestionnaires
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Avancar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _syncExamSelections(List<ProcedureExamSearch> results) {
    _latestExamResults = List.unmodifiable(results);

    if (_examSelections.length == results.length) {
      return;
    }

    _examSelections
      ..clear()
      ..addAll(
        results.map(
          (item) => _ExamSelection(key: item.keyword),
        ),
      );
  }

  Future<void> _handleNext() async {
    if (_examSelections.isEmpty ||
        _examSelections.every((selection) => selection.excluded)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E preciso manter pelo menos um exame para avancar.'),
        ),
      );
      return;
    }

    final questionnaireSets = await _loadQuestionnaireSets();

    if (!mounted) {
      return;
    }

    if (questionnaireSets == null) {
      return;
    }

    if (questionnaireSets.isNotEmpty) {
      final answers = await showDialog<List<QuestionnaireAnswer>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => QuestionnaireDialog(
          primaryColor:
              widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary,
          questionnaireSets: questionnaireSets,
          initialAnswers: _questionnaireAnswers,
        ),
      );

      if (answers == null) {
        return;
      }

      setState(() {
        _questionnaireAnswers = answers;
      });
    } else {
      _questionnaireAnswers = const [];
    }

    final authorizeThirdParty = await showDialog<bool>(
      context: context,
      builder: (context) {
        final primaryColor =
            widget.identity.primaryColor ??
            Theme.of(context).colorScheme.primary;

        return AlertDialog(
          title: const Text('Autorizar terceiros'),
          content: const Text(
            'Deseja autorizar terceiros a obter o resultado deste pedido?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nao'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    if (authorizeThirdParty != true) {
      _showPendingFinalizationMessage();
      return;
    }

    final result = await showDialog<ThirdPartyAuthorizationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ThirdPartyAuthorizationDialog(
        primaryColor:
            widget.identity.primaryColor ?? Theme.of(context).colorScheme.primary,
        relationshipsFuture: _relationships,
        initialAuthorizations: _thirdPartyAuthorizations,
        initialUnidentified: _thirdPartyUnidentified,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _thirdPartyAuthorizations = result.authorizations;
      _thirdPartyUnidentified = result.unidentified;
    });

    _showPendingFinalizationMessage();
  }

  Future<List<ExamQuestionnaireSet>?> _loadQuestionnaireSets() async {
    final gender = _questionnaireGender();
    final birthDate = widget.authentication?.user.birthDate.trim() ?? '';

    if (gender.isEmpty || birthDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel consultar questionario sem genero e data de nascimento do cliente.',
          ),
        ),
      );
      return null;
    }

    final selectedExams = <_QuestionnaireExamCandidate>[];

    for (var index = 0; index < _latestExamResults.length; index++) {
      if (index >= _examSelections.length || _examSelections[index].excluded) {
        continue;
      }

      final item = _latestExamResults[index];
      final candidate = _QuestionnaireExamCandidate.fromSearch(item);

      if (candidate.examForCheck.isNotEmpty &&
          candidate.examForQuestionnaire.isNotEmpty &&
          candidate.material.isNotEmpty) {
        selectedExams.add(candidate);
      }
    }

    if (selectedExams.isEmpty) {
      return const [];
    }

    setState(() => _isLoadingQuestionnaires = true);

    try {
      final sets = <ExamQuestionnaireSet>[];

      for (final candidate in selectedExams) {
        final check = await fetchExamQuestionnaireCheck(
          candidate.examForCheck,
          widget.authentication?.token,
        );

        if (!check.examHasQuestionnaire) {
          continue;
        }

        final questionnaires = await fetchQuestionnaires(
          material: candidate.material,
          exam: candidate.examForQuestionnaire,
          gender: gender,
          birthDate: birthDate,
          clientToken: widget.authentication?.token,
        );
        final usefulQuestionnaires = questionnaires
            .where((questionnaire) => questionnaire.questions.isNotEmpty)
            .toList();

        if (usefulQuestionnaires.isEmpty) {
          continue;
        }

        sets.add(
          ExamQuestionnaireSet(
            examCode: candidate.examForQuestionnaire,
            examLabel: candidate.label,
            material: candidate.material,
            questionnaires: usefulQuestionnaires,
          ),
        );
      }

      return sets;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao consultar questionarios: $error')),
        );
      }

      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestionnaires = false);
      }
    }
  }

  String _questionnaireGender() {
    final rawGender = widget.authentication?.user.gender?.trim() ?? '';
    final normalized = rawGender.toUpperCase();

    if (normalized == 'M' || normalized.startsWith('MASC')) {
      return 'Masculino';
    }

    if (normalized == 'F' || normalized.startsWith('FEM')) {
      return 'Feminino';
    }

    if (normalized.startsWith('IND')) {
      return 'Indeterminado';
    }

    return rawGender;
  }

  void _showPendingFinalizationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Informacoes registradas no fluxo. Envio sera feito na finalizacao do pedido.',
        ),
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
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({
    required this.authentication,
    required this.clientCode,
    required this.primaryColor,
  });

  final ClientAuthentication? authentication;
  final String? clientCode;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final user = authentication?.user;

    return Align(
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine(
              label: 'Paciente',
              value: user?.displayName ?? '-',
              primaryColor: primaryColor,
            ),
            _SummaryLine(
              label: 'Codigo do cliente',
              value: user?.clientId ?? clientCode ?? '-',
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  final String label;
  final String value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({
    required this.primaryColor,
    required this.message,
    required this.details,
  });

  final Color primaryColor;
  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              details,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _guideKey(PreAttendanceGuide guide) {
  return [
    guide.preAttendanceNumber,
    guide.operatorGuideNumber,
    guide.authorizationPassword,
  ].join('|');
}

class _QuestionnaireExamCandidate {
  const _QuestionnaireExamCandidate({
    required this.examForCheck,
    required this.examForQuestionnaire,
    required this.material,
    required this.label,
  });

  factory _QuestionnaireExamCandidate.fromSearch(ProcedureExamSearch item) {
    final exam = item.firstResult;
    final examForCheck = _firstUseful([
      exam?.id,
      exam?.mnemonic,
      item.keyword,
    ]);
    final examForQuestionnaire = _firstUseful([
      exam?.mnemonic,
      item.keyword,
      exam?.id,
    ]);
    final material = _firstUseful([
      exam?.materialMnemonic,
      item.fallbackMaterialCode,
    ]);
    final description = _firstUseful([
      exam?.description,
      item.fallbackDescription,
    ]);
    final label = _buildExamLabel(
      examCode: examForQuestionnaire,
      description: description,
      materialCode: material,
      materialDescription: _firstUseful([
        item.fallbackMaterialDescription,
        exam?.materialDescription,
      ]),
    );

    return _QuestionnaireExamCandidate(
      examForCheck: examForCheck,
      examForQuestionnaire: examForQuestionnaire,
      material: material,
      label: label,
    );
  }

  final String examForCheck;
  final String examForQuestionnaire;
  final String material;
  final String label;
}

class _ExamSelection {
  _ExamSelection({required this.key});

  final String key;
  bool delivered = true;
  bool excluded = false;
}

class _ExamResultTable extends StatelessWidget {
  const _ExamResultTable({
    required this.results,
    required this.selections,
    required this.primaryColor,
    required this.onSelectionChanged,
  });

  final List<ProcedureExamSearch> results;
  final List<_ExamSelection> selections;
  final Color primaryColor;
  final VoidCallback onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStatePropertyAll(
            primaryColor.withOpacity(0.08),
          ),
          columns: const [
            DataColumn(label: Text('Entregue?')),
            DataColumn(label: Text('Excluir?')),
            DataColumn(label: Text('Exame')),
            DataColumn(label: Text('Conservante')),
            DataColumn(label: Text('Descricao')),
            DataColumn(label: Text('Condicao amostra')),
          ],
          rows: List.generate(results.length, (index) {
            final item = results[index];
            final selection = selections[index];
            final exam = item.firstResult;
            final description = _firstNotEmpty([
              exam?.description,
              item.fallbackDescription,
            ]);
            final examCode = _firstNotEmpty([
              exam?.mnemonic,
              exam?.id,
              item.keyword,
            ]);
            final materialCode = _firstNotEmpty([
              exam?.materialMnemonic,
              item.fallbackMaterialCode,
            ]);
            final materialDescription = _firstNotEmpty([
              item.fallbackMaterialDescription,
              exam?.materialDescription,
            ]);
            final condition = _firstNotEmpty([
              item.fallbackSampleCondition,
            ]);
            final examLabel = _buildExamLabel(
              examCode: examCode,
              description: description,
              materialCode: materialCode,
              materialDescription: materialDescription,
            );

            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: selection.delivered,
                    activeColor: primaryColor,
                    onChanged: selection.excluded
                        ? null
                        : (value) {
                            selection.delivered = value ?? false;
                            onSelectionChanged();
                          },
                  ),
                ),
                DataCell(
                  Checkbox(
                    value: selection.excluded,
                    activeColor: primaryColor,
                    onChanged: (value) {
                      selection.excluded = value ?? false;
                      if (selection.excluded) {
                        selection.delivered = false;
                      }
                      onSelectionChanged();
                    },
                  ),
                ),
                DataCell(Text(examLabel)),
                // TODO: preencher pela rota especifica de conservante quando o
                // contrato existir. basic/exams e uma consulta geral de exames.
                const DataCell(Text('-')),
                DataCell(Text(materialDescription)),
                DataCell(Text(condition)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

String _buildExamLabel({
  required String examCode,
  required String description,
  required String materialCode,
  required String materialDescription,
}) {
  final buffer = StringBuffer();

  if (materialCode != '-') {
    buffer.write('$materialCode || ');
  }

  buffer.write(examCode);

  if (description != '-') {
    buffer.write(' - $description');
  }

  if (materialDescription != '-') {
    buffer.write(' / $materialDescription');
  }

  return buffer.toString();
}

String _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();

    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '-';
}

String _firstUseful(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();

    if (trimmed != null && trimmed.isNotEmpty && trimmed != '-') {
      return trimmed;
    }
  }

  return '';
}
