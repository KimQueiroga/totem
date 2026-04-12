import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/terminal_context.dart';
import '../models/terminal_visual_identity.dart';
import '../services/terminal_api.dart';
import '../widgets/loading_content.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/terminal_error_content.dart';
import '../widgets/terminal_not_found_content.dart';
import 'cpf_identification_content.dart';
import 'client_confirmation_content.dart';
import 'identification_options_content.dart';
import 'service_selection_content.dart';
import 'terminal_home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.terminalName,
    required this.resetCount,
    required this.loadVisualIdentity,
    required this.loadTerminalContext,
    required this.authenticateClient,
    required this.updateClient,
  });

  final String? terminalName;
  final int resetCount;
  final VisualIdentityLoader loadVisualIdentity;
  final TerminalContextLoader loadTerminalContext;
  final ClientAuthenticator authenticateClient;
  final ClientUpdater updateClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<TerminalVisualIdentity>? _visualIdentity;
  Future<TerminalContext>? _terminalContext;
  Future<ClientAuthentication>? _clientAuthentication;
  TerminalService? _selectedService;
  IdentificationOption? _selectedIdentificationOption;

  @override
  void initState() {
    super.initState();

    final terminalName = widget.terminalName;
    if (terminalName != null) {
      _visualIdentity = widget.loadVisualIdentity(terminalName);
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resetCount != widget.resetCount) {
      _backToHome();
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
      _clientAuthentication = null;
      _selectedService = null;
      _selectedIdentificationOption = null;
    });
  }

  void _backToServices() {
    setState(() {
      _selectedService = null;
      _clientAuthentication = null;
      _selectedIdentificationOption = null;
    });
  }

  void _backToIdentificationOptions() {
    setState(() {
      _selectedIdentificationOption = null;
      _clientAuthentication = null;
    });
  }

  void _backToCpfIdentification() {
    setState(() {
      _clientAuthentication = null;
    });
  }

  void _handleServiceSelected(TerminalService service) {
    if (service.isPreAttendance) {
      setState(() {
        _selectedService = service;
      });

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servico selecionado: ${service.displayName}')),
    );
  }

  void _handleIdentificationOptionSelected(IdentificationOption option) {
    if (option == IdentificationOption.cpf) {
      setState(() {
        _selectedIdentificationOption = option;
      });

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Identificacao selecionada: ${option.label}')),
    );
  }

  void _handleCpfIdentificationSubmit(CpfIdentificationData data) {
    setState(() {
      _clientAuthentication = widget.authenticateClient(
        ClientCredentials(
          cpf: data.cpf,
          password: data.password,
          birthDate: data.birthDate,
        ),
      );
    });
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperacao de senha ainda nao disponivel'),
      ),
    );
  }

  Future<void> _handleClientConfirmation(
    ClientProfileUpdate profileUpdate,
  ) async {
    if (!profileUpdate.hasChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados confirmados.')));
      return;
    }

    try {
      await widget.updateClient(profileUpdate);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar dados: $error')),
      );
    }
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

              final selectedService = _selectedService;
              if (selectedService != null && selectedService.isPreAttendance) {
                if (_selectedIdentificationOption == IdentificationOption.cpf) {
                  final clientAuthentication = _clientAuthentication;

                  if (clientAuthentication != null) {
                    return FutureBuilder<ClientAuthentication>(
                      future: clientAuthentication,
                      builder: (context, clientSnapshot) {
                        if (clientSnapshot.connectionState !=
                            ConnectionState.done) {
                          return PageScaffold(
                            identity: identity,
                            child: const LoadingContent(
                              message: 'Validando dados do cliente...',
                            ),
                          );
                        }

                        if (clientSnapshot.hasError ||
                            !clientSnapshot.hasData) {
                          return PageScaffold(
                            alignment: Alignment.topCenter,
                            identity: identity,
                            maxWidth: 980,
                            child: TerminalErrorContent(
                              terminalName: terminalName,
                              error: clientSnapshot.error,
                            ),
                          );
                        }

                        return PageScaffold(
                          alignment: Alignment.topCenter,
                          identity: identity,
                          maxWidth: 980,
                          child: ClientConfirmationContent(
                            identity: identity,
                            flowTitle: 'Checkin Pre Atendimento',
                            authentication: clientSnapshot.data!,
                            onBack: _backToCpfIdentification,
                            onHome: _backToHome,
                            onReject: _backToCpfIdentification,
                            onConfirm: _handleClientConfirmation,
                          ),
                        );
                      },
                    );
                  }

                  return PageScaffold(
                    alignment: Alignment.topCenter,
                    identity: identity,
                    maxWidth: 980,
                    child: CpfIdentificationContent(
                      identity: identity,
                      flowTitle: 'Checkin Pre Atendimento',
                      onHome: _backToHome,
                      onBack: _backToIdentificationOptions,
                      onSubmit: _handleCpfIdentificationSubmit,
                      onForgotPassword: _handleForgotPassword,
                    ),
                  );
                }

                return PageScaffold(
                  alignment: Alignment.topCenter,
                  identity: identity,
                  maxWidth: 980,
                  child: IdentificationOptionsContent(
                    identity: identity,
                    flowTitle: 'Checkin Pre Atendimento',
                    question: 'Como voce quer acessar?',
                    onHome: _backToHome,
                    onBack: _backToServices,
                    onOptionSelected: _handleIdentificationOptionSelected,
                  ),
                );
              }

              return PageScaffold(
                alignment: Alignment.topCenter,
                identity: identity,
                maxWidth: 980,
                child: ServiceSelectionContent(
                  terminalName: terminalName,
                  identity: identity,
                  terminalContext: contextSnapshot.data!,
                  onBack: _backToHome,
                  onServiceSelected: _handleServiceSelected,
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
