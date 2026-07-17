import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/exam_search.dart';
import '../models/pre_attendance.dart';
import '../models/terminal_visual_identity.dart';
import '../models/third_party_authorization.dart';
import '../services/terminal_api.dart';
import '../widgets/flow_top_bar.dart';
import '../widgets/numeric_touch_keyboard.dart';

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
  bool _thirdPartyUnidentified = false;
  late Future<List<String>> _relationships;

  @override
  void initState() {
    super.initState();
    _relationships = fetchRelationships();
  }

  @override
  void didUpdateWidget(covariant PreAttendanceExamsContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.examSearchFuture != widget.examSearchFuture) {
      _examSelections.clear();
      _thirdPartyAuthorizations = const [];
      _thirdPartyUnidentified = false;
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
                        onPressed: _handleNext,
                        child: const Text('Avancar'),
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

    final result = await showDialog<_ThirdPartyAuthorizationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ThirdPartyAuthorizationDialog(
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

class _ExamSelection {
  _ExamSelection({required this.key});

  final String key;
  bool delivered = true;
  bool excluded = false;
}

class _ThirdPartyAuthorizationResult {
  const _ThirdPartyAuthorizationResult({
    required this.authorizations,
    required this.unidentified,
  });

  final List<ThirdPartyAuthorization> authorizations;
  final bool unidentified;
}

enum _ThirdPartyKeyboardField {
  name('Nome completo'),
  document('Documento');

  const _ThirdPartyKeyboardField(this.label);

  final String label;

  TextEditingController controller(
    _ThirdPartyAuthorizationDialogState state,
  ) {
    return switch (this) {
      _ThirdPartyKeyboardField.name => state._nameController,
      _ThirdPartyKeyboardField.document => state._documentNumberController,
    };
  }

  FocusNode focusNode(_ThirdPartyAuthorizationDialogState state) {
    return switch (this) {
      _ThirdPartyKeyboardField.name => state._nameFocusNode,
      _ThirdPartyKeyboardField.document => state._documentNumberFocusNode,
    };
  }
}

class _ThirdPartyAuthorizationDialog extends StatefulWidget {
  const _ThirdPartyAuthorizationDialog({
    required this.primaryColor,
    required this.relationshipsFuture,
    required this.initialAuthorizations,
    required this.initialUnidentified,
  });

  final Color primaryColor;
  final Future<List<String>> relationshipsFuture;
  final List<ThirdPartyAuthorization> initialAuthorizations;
  final bool initialUnidentified;

  @override
  State<_ThirdPartyAuthorizationDialog> createState() =>
      _ThirdPartyAuthorizationDialogState();
}

class _ThirdPartyAuthorizationDialogState
    extends State<_ThirdPartyAuthorizationDialog> {
  static const _documentTypes = [
    'CPF',
    'RG',
    'CNH',
    'Passaporte',
    'Carteira de Trabalho',
  ];
  static const _fallbackRelationships = [
    'Conjuge',
    'Pai/Mae',
    'Filho/Filha',
    'Irmao/Irma',
    'Tio/Tia',
    'Sobrinho/Sobrinha',
    'Avo/Avo',
    'Outros',
  ];

  final _nameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _documentNumberFocusNode = FocusNode();
  final _authorizations = <ThirdPartyAuthorization>[];
  _ThirdPartyKeyboardField? _activeKeyboardField;
  String? _relationship;
  String? _documentType;
  bool _unidentified = false;
  bool _isUpperCase = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authorizations.addAll(widget.initialAuthorizations);
    _unidentified = widget.initialUnidentified;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentNumberController.dispose();
    _nameFocusNode.dispose();
    _documentNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: const Text('Liberacao de Resultado para Terceiro'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Para liberar a entrega de resultados para terceiros e necessario o preenchimento das informacoes abaixo. Caso nao tenha as informacoes, selecione terceiro nao identificado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<String>>(
                future: widget.relationshipsFuture,
                builder: (context, snapshot) {
                  final relationships = _relationshipOptions(snapshot.data);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 330,
                            child: TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              onTap: () => _setActiveKeyboardField(
                                _ThirdPartyKeyboardField.name,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: relationships.contains(_relationship)
                                  ? _relationship
                                  : null,
                              items: relationships
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: 'Parentesco *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _relationship = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _documentType,
                              items: _documentTypes
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: 'Documento *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _documentType = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: TextField(
                              controller: _documentNumberController,
                              focusNode: _documentNumberFocusNode,
                              onTap: () => _setActiveKeyboardField(
                                _ThirdPartyKeyboardField.document,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'No do Documento *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.primaryColor,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: _addAuthorization,
                              child: const Text('Adicionar'),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _unidentified,
                                activeColor: widget.primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    _unidentified = value ?? false;
                                    _errorMessage = null;
                                  });
                                },
                              ),
                              const Text('Terceiro nao identificado'),
                            ],
                          ),
                        ],
                      ),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Nao foi possivel carregar parentescos da API. Usando lista padrao.',
                            style: TextStyle(color: widget.primaryColor),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_activeKeyboardField != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 560,
                    child: NumericTouchKeyboard(
                      color: widget.primaryColor,
                      activeFieldLabel: _activeKeyboardField!.label,
                      nextLabel:
                          _activeKeyboardField == _ThirdPartyKeyboardField.name
                          ? 'Proximo'
                          : 'Concluir',
                      layout: TouchKeyboardLayout.alphanumeric,
                      includeSpace: true,
                      isUpperCase: _isUpperCase,
                      borderRadius: BorderRadius.circular(8),
                      onToggleLetterCase: () {
                        setState(() => _isUpperCase = !_isUpperCase);
                      },
                      onDigit: _appendKeyboardValue,
                      onBackspace: _backspaceKeyboardValue,
                      onClear: _clearKeyboardField,
                      onNext: _goToNextKeyboardField,
                      onClose: _closeKeyboard,
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _ThirdPartyTable(
                authorizations: _authorizations,
                onRemove: (index) {
                  setState(() => _authorizations.removeAt(index));
                },
              ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.primaryColor),
          onPressed: _save,
          child: const Text('Salvar Informacoes'),
        ),
      ],
    );
  }

  List<String> _relationshipOptions(List<String>? apiItems) {
    final items = [
      if (apiItems != null)
        for (final item in apiItems)
          if (item.trim().isNotEmpty) item.trim(),
    ];

    return items.isEmpty ? _fallbackRelationships : items;
  }

  void _setActiveKeyboardField(_ThirdPartyKeyboardField field) {
    setState(() => _activeKeyboardField = field);

    field.focusNode(this).requestFocus();
  }

  void _appendKeyboardValue(String value) {
    final field = _activeKeyboardField;

    if (field == null) {
      return;
    }

    final controller = field.controller(this);
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, value);
    final offset = start + value.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  void _backspaceKeyboardValue() {
    final field = _activeKeyboardField;

    if (field == null) {
      return;
    }

    final controller = field.controller(this);
    final selection = controller.selection;
    final text = controller.text;

    if (text.isEmpty) {
      return;
    }

    if (selection.start != selection.end &&
        selection.start >= 0 &&
        selection.end >= 0) {
      controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, ''),
        selection: TextSelection.collapsed(offset: selection.start),
      );
      return;
    }

    final offset = selection.start > 0 ? selection.start : text.length;

    if (offset <= 0) {
      return;
    }

    controller.value = TextEditingValue(
      text: text.replaceRange(offset - 1, offset, ''),
      selection: TextSelection.collapsed(offset: offset - 1),
    );
  }

  void _clearKeyboardField() {
    final field = _activeKeyboardField;

    if (field == null) {
      return;
    }

    field.controller(this).clear();
  }

  void _goToNextKeyboardField() {
    if (_activeKeyboardField == _ThirdPartyKeyboardField.name) {
      _setActiveKeyboardField(_ThirdPartyKeyboardField.document);
      return;
    }

    _closeKeyboard();
  }

  void _closeKeyboard() {
    setState(() => _activeKeyboardField = null);
  }

  void _addAuthorization() {
    final name = _nameController.text.trim();
    final documentNumber = _documentNumberController.text.trim();
    final relationship = _relationship;
    final documentType = _documentType;

    if (name.isEmpty ||
        relationship == null ||
        documentType == null ||
        documentNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha todos os campos obrigatorios para adicionar.';
      });
      return;
    }

    setState(() {
      _authorizations.add(
        ThirdPartyAuthorization(
          name: name,
          relationship: relationship,
          documentType: documentType,
          documentNumber: documentNumber,
        ),
      );
      _nameController.clear();
      _documentNumberController.clear();
      _relationship = null;
      _documentType = null;
      _errorMessage = null;
    });
  }

  void _save() {
    if (_authorizations.isEmpty && !_unidentified) {
      setState(() {
        _errorMessage =
            'Adicione ao menos um terceiro ou marque terceiro nao identificado.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ThirdPartyAuthorizationResult(
        authorizations: List.unmodifiable(_authorizations),
        unidentified: _unidentified,
      ),
    );
  }
}

class _ThirdPartyTable extends StatelessWidget {
  const _ThirdPartyTable({
    required this.authorizations,
    required this.onRemove,
  });

  final List<ThirdPartyAuthorization> authorizations;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: borderColor)),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TableText('Nome do Terceiro', true)),
                Expanded(child: _TableText('Parentesco', true)),
                Expanded(child: _TableText('Documento', true)),
                Expanded(child: _TableText('No do Documento', true)),
                SizedBox(width: 52),
              ],
            ),
          ),
          if (authorizations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                'Nao foi adicionado nenhum terceiro para entrega de resultados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            )
          else
            for (var index = 0; index < authorizations.length; index++)
              _ThirdPartyRow(
                authorization: authorizations[index],
                borderColor: borderColor,
                onRemove: () => onRemove(index),
              ),
        ],
      ),
    );
  }
}

class _ThirdPartyRow extends StatelessWidget {
  const _ThirdPartyRow({
    required this.authorization,
    required this.borderColor,
    required this.onRemove,
  });

  final ThirdPartyAuthorization authorization;
  final Color borderColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
      children: [
          Expanded(flex: 2, child: _TableText(authorization.name, false)),
          Expanded(child: _TableText(authorization.relationship, false)),
          Expanded(child: _TableText(authorization.documentType, false)),
          Expanded(child: _TableText(authorization.documentNumber, false)),
          SizedBox(
            width: 52,
            child: IconButton(
              tooltip: 'Remover',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.value, this.isHeader);

  final String value;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w700 : null,
        ),
      ),
    );
  }
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
