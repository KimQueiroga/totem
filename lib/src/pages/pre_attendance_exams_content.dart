import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/exam_search.dart';
import '../models/pre_attendance.dart';
import '../models/terminal_visual_identity.dart';
import '../widgets/flow_top_bar.dart';

class PreAttendanceExamsContent extends StatelessWidget {
  const PreAttendanceExamsContent({
    super.key,
    required this.identity,
    required this.flowTitle,
    required this.authentication,
    required this.guide,
    required this.examSearchFuture,
    required this.onBack,
    required this.onHome,
  });

  final TerminalVisualIdentity identity;
  final String flowTitle;
  final ClientAuthentication authentication;
  final PreAttendanceGuide guide;
  final Future<List<ProcedureExamSearch>> examSearchFuture;
  final VoidCallback onBack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;

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
                'Exames autorizados',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: identity.patientNameColor ?? primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Guia ${guide.operatorGuideNumber} · Pre atendimento ${guide.preAttendanceNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<ProcedureExamSearch>>(
                  future: examSearchFuture,
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
                      primaryColor: primaryColor,
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onBack,
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(height: 12),
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

class _ExamResultTable extends StatelessWidget {
  const _ExamResultTable({required this.results, required this.primaryColor});

  final List<ProcedureExamSearch> results;
  final Color primaryColor;

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
            DataColumn(label: Text('Procedimento')),
            DataColumn(label: Text('Exame')),
            DataColumn(label: Text('Conservante')),
            DataColumn(label: Text('Descricao')),
            DataColumn(label: Text('Condicao amostra')),
            DataColumn(label: Text('Status')),
          ],
          rows: results.map((item) {
            final exam = item.firstResult;
            final status = item.error != null
                ? 'Erro'
                : exam != null
                ? 'Encontrado'
                : 'Nao encontrado';
            final condition = item.error != null
                ? item.error!
                : exam?.sampleConditionIsRequired == true
                ? 'Sim'
                : 'Nao';

            return DataRow(
              cells: [
                DataCell(Text(item.keyword)),
                DataCell(
                  Text(
                    exam?.mnemonic.isNotEmpty == true
                        ? exam!.mnemonic
                        : exam?.id ?? '-',
                  ),
                ),
                DataCell(Text(exam?.materialDescription ?? '-')),
                DataCell(Text(exam?.description ?? '-')),
                DataCell(Text(condition)),
                DataCell(Text(status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
