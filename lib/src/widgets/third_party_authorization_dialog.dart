import 'package:flutter/material.dart';

import '../models/third_party_authorization.dart';
import 'numeric_touch_keyboard.dart';

class ThirdPartyAuthorizationResult {
  const ThirdPartyAuthorizationResult({
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

class ThirdPartyAuthorizationDialog extends StatefulWidget {
  const ThirdPartyAuthorizationDialog({
    super.key,
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
  State<ThirdPartyAuthorizationDialog> createState() =>
      _ThirdPartyAuthorizationDialogState();
}

class _ThirdPartyAuthorizationDialogState
    extends State<ThirdPartyAuthorizationDialog> {
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
    final keyboardOpen = _activeKeyboardField != null;

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
              if (!keyboardOpen)
                Text(
                  'Para liberar a entrega de resultados para terceiros e necessario o preenchimento das informacoes abaixo. Caso nao tenha as informacoes, selecione terceiro nao identificado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  'Digite usando o teclado na tela ou o teclado fisico.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
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
                          if (!keyboardOpen ||
                              _activeKeyboardField ==
                                  _ThirdPartyKeyboardField.name)
                            SizedBox(
                              width: keyboardOpen ? 520 : 330,
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
                          if (!keyboardOpen)
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
                          if (!keyboardOpen)
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
                          if (!keyboardOpen ||
                              _activeKeyboardField ==
                                  _ThirdPartyKeyboardField.document)
                            SizedBox(
                              width: keyboardOpen ? 280 : 190,
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
                          if (!keyboardOpen)
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
                          if (!keyboardOpen)
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
                      if (snapshot.hasError && !keyboardOpen)
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
              if (keyboardOpen) ...[
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
                      compact: true,
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
              if (!keyboardOpen) ...[
                const SizedBox(height: 18),
                _ThirdPartyTable(
                  authorizations: _authorizations,
                  onRemove: (index) {
                    setState(() => _authorizations.removeAt(index));
                  },
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
      ThirdPartyAuthorizationResult(
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
