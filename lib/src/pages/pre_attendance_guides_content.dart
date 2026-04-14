import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/pre_attendance.dart';
import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';

class PreAttendanceGuidesContent extends StatelessWidget {
  const PreAttendanceGuidesContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.authentication,
    required this.preAttendance,
    required this.onBack,
    required this.onHome,
    required this.onCancel,
    required this.onNext,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final ClientAuthentication authentication;
  final PreAttendanceQuery preAttendance;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onCancel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;
    final guides = preAttendance.guides;

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
                logoBytes: identity.logoBytes,
                primaryColor: primaryColor,
                title: flowTitle,
                onBack: onBack,
                onHome: onHome,
              ),
              const SizedBox(height: 12),
              _PatientSummary(
                authentication: authentication,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 14),
              Text(
                'Guias pre atendimento',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: identity.patientNameColor ?? primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: guides.isEmpty
                    ? _EmptyGuidesMessage(primaryColor: primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 720) {
                            return _GuideList(
                              guides: guides,
                              primaryColor: primaryColor,
                            );
                          }

                          return _GuideTable(
                            guides: guides,
                            primaryColor: primaryColor,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),
              _ActionButtons(
                primaryColor: primaryColor,
                buttonColor: buttonColor,
                onCancel: onCancel,
                onNext: guides.isEmpty ? null : onNext,
              ),
            ],
          ),
        );
      },
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
    required this.primaryColor,
  });

  final ClientAuthentication authentication;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final user = authentication.user;

    return Align(
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine(
              label: 'Paciente',
              value: user.displayName,
              primaryColor: primaryColor,
            ),
            _SummaryLine(
              label: 'Codigo do cliente',
              value: user.clientId ?? '-',
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

class _GuideTable extends StatelessWidget {
  const _GuideTable({required this.guides, required this.primaryColor});

  final List<PreAttendanceGuide> guides;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.maxWidth > 760
            ? constraints.maxWidth
            : 760.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableMinWidth),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    primaryColor.withValues(alpha: 0.08),
                  ),
                  columns: const [
                    DataColumn(label: Text('Guia')),
                    DataColumn(label: Text('Autorizacao')),
                    DataColumn(label: Text('Medico solicitante')),
                    DataColumn(label: Text('Detalhes')),
                  ],
                  rows: [
                    for (final guide in guides)
                      DataRow(
                        cells: [
                          DataCell(
                            _TableText(
                              _displayValue(guide.operatorGuideNumber),
                            ),
                          ),
                          DataCell(
                            _TableText(
                              _displayValue(guide.authorizationPassword),
                            ),
                          ),
                          DataCell(
                            _TableText(_displayValue(guide.requesterName)),
                          ),
                          DataCell(
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  _showGuideDetails(context, guide),
                              child: const Text('Ver detalhes'),
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
      },
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.guides, required this.primaryColor});

  final List<PreAttendanceGuide> guides;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final guide = guides[index];

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideValue(label: 'Guia', value: guide.operatorGuideNumber),
                _GuideValue(
                  label: 'Autorizacao',
                  value: guide.authorizationPassword,
                ),
                _GuideValue(
                  label: 'Medico solicitante',
                  value: guide.requesterName,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showGuideDetails(context, guide),
                  child: const Text('Ver detalhes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuideValue extends StatelessWidget {
  const _GuideValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: _displayValue(value)),
          ],
        ),
      ),
    );
  }
}

class _EmptyGuidesMessage extends StatelessWidget {
  const _EmptyGuidesMessage({required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhuma guia de pre atendimento encontrada.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.primaryColor,
    required this.buttonColor,
    required this.onCancel,
    required this.onNext,
  });

  final Color primaryColor;
  final Color buttonColor;
  final VoidCallback onCancel;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 640;
        final cancelButton = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onCancel,
          child: const Text('Cancelar'),
        );
        final nextButton = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onNext,
          child: const Text('Avancar'),
        );

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 56, child: nextButton),
              const SizedBox(height: 16),
              SizedBox(height: 56, child: cancelButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: SizedBox(height: 56, child: cancelButton)),
            const SizedBox(width: 48),
            Expanded(child: SizedBox(height: 56, child: nextButton)),
          ],
        );
      },
    );
  }
}

void _showGuideDetails(BuildContext context, PreAttendanceGuide guide) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Detalhes da guia'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GuideValue(label: 'Guia', value: guide.operatorGuideNumber),
                _GuideValue(
                  label: 'Pre atendimento',
                  value: guide.preAttendanceNumber,
                ),
                _GuideValue(
                  label: 'Autorizacao',
                  value: guide.authorizationPassword,
                ),
                _GuideValue(
                  label: 'Medico solicitante',
                  value: guide.requesterName,
                ),
                const SizedBox(height: 12),
                Text(
                  'Exames',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (guide.exams.isEmpty)
                  const Text('Nenhum exame informado.')
                else
                  for (final exam in guide.exams)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_displayValue(exam.description)} - ${_displayValue(exam.materialDescription)}',
                      ),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

String _displayValue(String value) {
  return value.trim().isEmpty ? '-' : value.trim();
}
