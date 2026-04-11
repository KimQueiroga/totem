import 'package:flutter/material.dart';

import '../models/terminal_context.dart';
import '../models/terminal_visual_identity.dart';
import '../services/terminal_api.dart';
import '../widgets/loading_content.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/terminal_error_content.dart';
import '../widgets/terminal_not_found_content.dart';
import 'service_selection_content.dart';
import 'terminal_home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.terminalName,
    required this.loadVisualIdentity,
    required this.loadTerminalContext,
  });

  final String? terminalName;
  final VisualIdentityLoader loadVisualIdentity;
  final TerminalContextLoader loadTerminalContext;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<TerminalVisualIdentity>? _visualIdentity;
  Future<TerminalContext>? _terminalContext;

  @override
  void initState() {
    super.initState();

    final terminalName = widget.terminalName;
    if (terminalName != null) {
      _visualIdentity = widget.loadVisualIdentity(terminalName);
    }
  }

  void _startAttendance() {
    final terminalName = widget.terminalName;
    if (terminalName == null) {
      return;
    }

    setState(() {
      _terminalContext = widget.loadTerminalContext(terminalName);
    });
  }

  void _backToHome() {
    setState(() {
      _terminalContext = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final terminalName = widget.terminalName;

    if (terminalName == null) {
      return const PageScaffold(child: TerminalNotFoundContent());
    }

    return FutureBuilder<TerminalVisualIdentity>(
      future: _visualIdentity,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageScaffold(child: LoadingContent());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return PageScaffold(
            child: TerminalErrorContent(
              terminalName: terminalName,
              error: snapshot.error,
            ),
          );
        }

        final identity = snapshot.data!;
        final terminalContext = _terminalContext;

        if (terminalContext != null) {
          return FutureBuilder<TerminalContext>(
            future: terminalContext,
            builder: (context, contextSnapshot) {
              if (contextSnapshot.connectionState != ConnectionState.done) {
                return PageScaffold(
                  identity: identity,
                  child: const LoadingContent(
                    message: 'Carregando servicos disponiveis...',
                  ),
                );
              }

              if (contextSnapshot.hasError || !contextSnapshot.hasData) {
                return PageScaffold(
                  identity: identity,
                  child: TerminalErrorContent(
                    terminalName: terminalName,
                    error: contextSnapshot.error,
                  ),
                );
              }

              return PageScaffold(
                identity: identity,
                child: ServiceSelectionContent(
                  terminalName: terminalName,
                  identity: identity,
                  terminalContext: contextSnapshot.data!,
                  onBack: _backToHome,
                ),
              );
            },
          );
        }

        return PageScaffold(
          identity: identity,
          child: TerminalHomeContent(
            terminalName: terminalName,
            identity: identity,
            onStartAttendance: _startAttendance,
          ),
        );
      },
    );
  }
}
