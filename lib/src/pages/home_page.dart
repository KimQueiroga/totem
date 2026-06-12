import 'package:flutter/material.dart';

import '../models/client_authentication.dart';
import '../models/exam_search.dart';
import '../models/pre_attendance.dart';
import '../models/terminal_context.dart';
import '../models/terminal_visual_identity.dart';
import '../services/terminal_api.dart';
import '../widgets/loading_content.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/terminal_error_content.dart';
import '../widgets/terminal_not_found_content.dart';
import 'client_code_identification_content.dart';
import 'cpf_identification_content.dart';
import 'client_confirmation_content.dart';
import 'identification_options_content.dart';
import 'pre_attendance_exams_content.dart';
import 'pre_attendance_guides_content.dart';
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
    required this.loadPreAttendance,
  });

  final String? terminalName;
  final int resetCount;
  final VisualIdentityLoader loadVisualIdentity;
  final TerminalContextLoader loadTerminalContext;
  final ClientAuthenticator authenticateClient;
  final ClientUpdater updateClient;
  final PreAttendanceLoader loadPreAttendance;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<TerminalVisualIdentity>? _visualIdentity;
  Future<TerminalContext>? _terminalContext;
  ClientAuthentication? _clientAuthentication;
  Future<PreAttendanceQuery>? _preAttendance;
  PreAttendanceGuide? _selectedGuide;
  Future<List<ProcedureExamSearch>>? _selectedGuideExamSearch;
  String? _clientCode;
  bool _isAuthenticatingClient = false;
  String? _clientAuthenticationErrorMessage;
  int _clientAuthenticationFailureCount = 0;
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
      _preAttendance = null;
      _clientCode = null;
      _isAuthenticatingClient = false;
      _clientAuthenticationErrorMessage = null;
      _selectedService = null;
      _selectedIdentificationOption = null;
    });
  }

  void _backToServices() {
    setState(() {
      _selectedService = null;
      _clientAuthentication = null;
      _preAttendance = null;
      _selectedGuide = null;
      _selectedGuideExamSearch = null;
      _clientCode = null;
      _isAuthenticatingClient = false;
      _clientAuthenticationErrorMessage = null;
      _selectedIdentificationOption = null;
    });
  }

  void _backToIdentificationOptions() {
    setState(() {
      _selectedIdentificationOption = null;
      _clientAuthentication = null;
      _preAttendance = null;
      _clientCode = null;
      _isAuthenticatingClient = false;
      _clientAuthenticationErrorMessage = null;
    });
  }

  void _backToCpfIdentification() {
    setState(() {
      _clientAuthentication = null;
      _preAttendance = null;
      _selectedGuide = null;
      _selectedGuideExamSearch = null;
      _clientCode = null;
      _isAuthenticatingClient = false;
      _clientAuthenticationErrorMessage = null;
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
    if (option == IdentificationOption.barcode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leitura por codigo de barras ainda depende da rota legada.',
          ),
        ),
      );

      return;
    }

    if (option == IdentificationOption.cpf ||
        option == IdentificationOption.clientCode) {
      setState(() {
        _selectedIdentificationOption = option;
      });

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Identificacao selecionada: ${option.label}')),
    );
  }

  Future<void> _handleCpfIdentificationSubmit(
    CpfIdentificationData data,
  ) async {
    setState(() {
      _isAuthenticatingClient = true;
      _clientAuthenticationErrorMessage = null;
    });

    try {
      final authentication = await widget.authenticateClient(
        ClientCredentials(
          cpf: data.cpf,
          password: data.password,
          birthDate: data.birthDate,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _clientAuthentication = authentication;
        _isAuthenticatingClient = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _clientAuthentication = null;
        _isAuthenticatingClient = false;
        _clientAuthenticationErrorMessage =
            'Nao foi possivel validar seus dados. Confira as informacoes e tente novamente.';
        _clientAuthenticationFailureCount++;
      });
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperacao de senha ainda nao disponivel'),
      ),
    );
  }

  void _handleSelectPreAttendanceGuide(PreAttendanceGuide guide) {
    setState(() {
      _selectedGuide = guide;
    });
  }

  Future<void> _handleClientCodeSubmit(ClientCodeIdentificationData data) async {
    final clientCode = data.clientCode.trim();

    if (clientCode.isEmpty) {
      return;
    }

    setState(() {
      _isAuthenticatingClient = true;
      _clientAuthenticationErrorMessage = null;
    });

    try {
      final authentication = await widget.authenticateClient(
        ClientCredentials(
          clientCode: clientCode,
          password: data.password,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _clientAuthentication = authentication;
        _clientCode = authentication.user.clientId ?? clientCode;
        _isAuthenticatingClient = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _clientAuthentication = null;
        _clientCode = null;
        _isAuthenticatingClient = false;
        _clientAuthenticationErrorMessage =
            'Nao foi possivel validar seus dados. Confira o codigo e a senha e tente novamente.';
        _clientAuthenticationFailureCount++;
      });
    }
  }

  Future<void> _handlePreAttendanceNext() async {
    if (_selectedGuide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um pre atendimento antes de avancar.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedGuideExamSearch = _searchExamsForGuide(_selectedGuide!);
    });
  }

  Future<List<ProcedureExamSearch>> _searchExamsForGuide(
    PreAttendanceGuide guide,
  ) async {
    final keywords = guide.exams
        .map((exam) => exam.code.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList();

    return Future.wait(
      keywords.map((keyword) async {
        try {
          final results = await fetchExamSearch(
            keyword,
            _clientAuthentication?.token,
            healthPlan: guide.healthPlan.isNotEmpty ? guide.healthPlan : null,
            unit: '1',
          );
          return ProcedureExamSearch(keyword: keyword, results: results);
        } catch (error) {
          return ProcedureExamSearch(
            keyword: keyword,
            results: const [],
            error: error.toString(),
          );
        }
      }),
    );
  }

  void _handlePreAttendanceBackToSelection() {
    setState(() {
      _selectedGuideExamSearch = null;
    });
  }

  Future<void> _handleClientConfirmation(
    ClientProfileUpdate profileUpdate,
  ) async {
    if (!profileUpdate.hasChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados confirmados.')));
      _loadPreAttendance(profileUpdate.clientId);
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
      _loadPreAttendance(profileUpdate.clientId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar dados: $error')),
      );
    }
  }

  void _loadPreAttendance(String clientId, {String? clientToken}) {
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel localizar o codigo do cliente.'),
        ),
      );
      return;
    }

    setState(() {
      _preAttendance = widget.loadPreAttendance(
        clientId,
        clientToken ?? _clientAuthentication?.token,
      );
      _clientCode = clientId;
      _selectedGuide = null;
      _selectedGuideExamSearch = null;
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

              final selectedService = _selectedService;
              if (selectedService != null && selectedService.isPreAttendance) {
                if (_selectedIdentificationOption ==
                    IdentificationOption.clientCode) {
                  final clientAuthentication = _clientAuthentication;
                  final preAttendance = _preAttendance;

                  if (clientAuthentication != null && preAttendance != null) {
                    return FutureBuilder<PreAttendanceQuery>(
                      future: preAttendance,
                      builder: (context, preAttendanceSnapshot) {
                        if (preAttendanceSnapshot.connectionState !=
                            ConnectionState.done) {
                          return PageScaffold(
                            identity: identity,
                            child: const LoadingContent(
                              message: 'Carregando guias pre atendimento...',
                            ),
                          );
                        }

                        if (preAttendanceSnapshot.hasError ||
                            !preAttendanceSnapshot.hasData) {
                          return PageScaffold(
                            alignment: Alignment.topCenter,
                            identity: identity,
                            maxWidth: 980,
                            child: TerminalErrorContent(
                              terminalName: terminalName,
                              error: preAttendanceSnapshot.error,
                              title:
                                  'Nao foi possivel carregar as guias de pre atendimento.',
                              subtitle:
                                  'Tente novamente ou procure um atendente.',
                            ),
                          );
                        }

                        if (_selectedGuideExamSearch != null &&
                            _selectedGuide != null) {
                          return PageScaffold(
                            alignment: Alignment.topCenter,
                            identity: identity,
                            maxWidth: 980,
                            scrollable: false,
                            child: PreAttendanceExamsContent(
                              identity: identity,
                              flowTitle: 'Checkin Pre Atendimento',
                              authentication: clientAuthentication,
                              clientCode: clientAuthentication.user.clientId,
                              guide: _selectedGuide!,
                              examSearchFuture: _selectedGuideExamSearch!,
                              onBack: _handlePreAttendanceBackToSelection,
                              onHome: _backToHome,
                            ),
                          );
                        }

                        return PageScaffold(
                          alignment: Alignment.topCenter,
                          identity: identity,
                          maxWidth: 980,
                          scrollable: false,
                          child: PreAttendanceGuidesContent(
                            identity: identity,
                            flowTitle: 'Checkin Pre Atendimento',
                            authentication: clientAuthentication,
                            clientCode: clientAuthentication.user.clientId,
                            preAttendance: preAttendanceSnapshot.data!,
                            selectedGuide: _selectedGuide,
                            onSelectGuide: _handleSelectPreAttendanceGuide,
                            onBack: () {
                              setState(() {
                                _preAttendance = null;
                                _selectedGuide = null;
                              });
                            },
                            onHome: _backToHome,
                            onCancel: _backToCpfIdentification,
                            onNext: _handlePreAttendanceNext,
                          ),
                        );
                      },
                    );
                  }

                  if (clientAuthentication != null) {
                    return PageScaffold(
                      alignment: Alignment.topCenter,
                      identity: identity,
                      maxWidth: 980,
                      scrollable: false,
                      child: ClientConfirmationContent(
                        identity: identity,
                        flowTitle: 'Checkin Pre Atendimento',
                        authentication: clientAuthentication,
                        onBack: _backToCpfIdentification,
                        onHome: _backToHome,
                        onReject: _backToCpfIdentification,
                        onConfirm: _handleClientConfirmation,
                      ),
                    );
                  }

                  return PageScaffold(
                    alignment: Alignment.topCenter,
                    identity: identity,
                    maxWidth: 980,
                    child: ClientCodeIdentificationContent(
                      identity: identity,
                      flowTitle: 'Checkin Pre Atendimento',
                      onHome: _backToHome,
                      onBack: _backToIdentificationOptions,
                      onSubmit: _handleClientCodeSubmit,
                      isSubmitting: _isAuthenticatingClient,
                      errorMessage: _clientAuthenticationErrorMessage,
                      failureCount: _clientAuthenticationFailureCount,
                    ),
                  );
                }

                if (_selectedIdentificationOption == IdentificationOption.cpf) {
                  final clientAuthentication = _clientAuthentication;
                  final preAttendance = _preAttendance;

                  if (clientAuthentication != null && preAttendance != null) {
                    return FutureBuilder<PreAttendanceQuery>(
                      future: preAttendance,
                      builder: (context, preAttendanceSnapshot) {
                        if (preAttendanceSnapshot.connectionState !=
                            ConnectionState.done) {
                          return PageScaffold(
                            identity: identity,
                            child: const LoadingContent(
                              message: 'Carregando guias pre atendimento...',
                            ),
                          );
                        }

                        if (preAttendanceSnapshot.hasError ||
                            !preAttendanceSnapshot.hasData) {
                          return PageScaffold(
                            alignment: Alignment.topCenter,
                            identity: identity,
                            maxWidth: 980,
                            child: TerminalErrorContent(
                              terminalName: terminalName,
                              error: preAttendanceSnapshot.error,
                              title:
                                  'Nao foi possivel carregar as guias de pre atendimento.',
                              subtitle:
                                  'Tente novamente ou procure um atendente.',
                            ),
                          );
                        }

                        if (_selectedGuideExamSearch != null &&
                            _selectedGuide != null) {
                          return PageScaffold(
                            alignment: Alignment.topCenter,
                            identity: identity,
                            maxWidth: 980,
                            scrollable: false,
                            child: PreAttendanceExamsContent(
                              identity: identity,
                              flowTitle: 'Checkin Pre Atendimento',
                              authentication: clientAuthentication,
                              clientCode: clientAuthentication.user.clientId,
                              guide: _selectedGuide!,
                              examSearchFuture: _selectedGuideExamSearch!,
                              onBack: _handlePreAttendanceBackToSelection,
                              onHome: _backToHome,
                            ),
                          );
                        }

                        return PageScaffold(
                          alignment: Alignment.topCenter,
                          identity: identity,
                          maxWidth: 980,
                          scrollable: false,
                          child: PreAttendanceGuidesContent(
                            identity: identity,
                            flowTitle: 'Checkin Pre Atendimento',
                            authentication: clientAuthentication,
                            clientCode: clientAuthentication.user.clientId,
                            preAttendance: preAttendanceSnapshot.data!,
                            selectedGuide: _selectedGuide,
                            onSelectGuide: _handleSelectPreAttendanceGuide,
                            onBack: () {
                              setState(() {
                                _preAttendance = null;
                                _selectedGuide = null;
                              });
                            },
                            onHome: _backToHome,
                            onCancel: _backToCpfIdentification,
                            onNext: _handlePreAttendanceNext,
                          ),
                        );
                      },
                    );
                  }

                  if (clientAuthentication != null) {
                    return PageScaffold(
                      alignment: Alignment.topCenter,
                      identity: identity,
                      maxWidth: 980,
                      scrollable: false,
                      child: ClientConfirmationContent(
                        identity: identity,
                        flowTitle: 'Checkin Pre Atendimento',
                        authentication: clientAuthentication,
                        onBack: _backToCpfIdentification,
                        onHome: _backToHome,
                        onReject: _backToCpfIdentification,
                        onConfirm: _handleClientConfirmation,
                      ),
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
                      isSubmitting: _isAuthenticatingClient,
                      errorMessage: _clientAuthenticationErrorMessage,
                      failureCount: _clientAuthenticationFailureCount,
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
