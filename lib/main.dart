import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const bffBaseUrl = String.fromEnvironment(
  'BFF_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

typedef VisualIdentityLoader =
    Future<TerminalVisualIdentity> Function(String terminalName);

void main() {
  runApp(const TotemApp());
}

class TotemApp extends StatelessWidget {
  const TotemApp({super.key, this.initialUri, this.loadVisualIdentity});

  final Uri? initialUri;
  final VisualIdentityLoader? loadVisualIdentity;

  @override
  Widget build(BuildContext context) {
    final terminalName = extractTerminalName(initialUri ?? Uri.base);

    return MaterialApp(
      title: 'Totem Autoatendimento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A71)),
        useMaterial3: true,
      ),
      home: HomePage(
        terminalName: terminalName,
        loadVisualIdentity: loadVisualIdentity ?? fetchTerminalVisualIdentity,
      ),
    );
  }
}

String? extractTerminalName(Uri uri) {
  final queryValue = uri.queryParameters['terminal'];
  if (queryValue != null && queryValue.trim().isNotEmpty) {
    return queryValue.trim();
  }

  final hostNameValue = uri.queryParameters['hostName'];
  if (hostNameValue != null && hostNameValue.trim().isNotEmpty) {
    return hostNameValue.trim();
  }

  for (final segment in uri.pathSegments) {
    if (segment.startsWith('terminal=')) {
      final value = segment.substring('terminal='.length).trim();
      return value.isEmpty ? null : value;
    }
  }

  return null;
}

Future<TerminalVisualIdentity> fetchTerminalVisualIdentity(
  String terminalName,
) async {
  final uri = Uri.parse(
    '$bffBaseUrl/terminal-visual',
  ).replace(queryParameters: {'hostName': terminalName});

  final response = await http.get(uri, headers: {'Accept': 'application/json'});

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'BFF retornou HTTP ${response.statusCode}: ${_truncate(response.body)}',
    );
  }

  final payload = jsonDecode(response.body);

  if (payload is! Map<String, dynamic>) {
    throw Exception('Resposta do BFF nao e um objeto JSON.');
  }

  final identity = payload['identidadeVisual'];

  if (identity is! Map<String, dynamic>) {
    throw Exception('Resposta sem identidadeVisual');
  }

  return TerminalVisualIdentity.fromJson(identity);
}

String _truncate(String value) {
  const maxLength = 300;
  return value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}...';
}

class TerminalVisualIdentity {
  const TerminalVisualIdentity({
    required this.alias,
    required this.primaryColor,
    required this.primaryHoverColor,
    required this.buttonColor,
    required this.patientNameColor,
    required this.logoBase64,
  });

  factory TerminalVisualIdentity.fromJson(Map<String, dynamic> json) {
    return TerminalVisualIdentity(
      alias: json['apelido']?.toString() ?? '',
      primaryColor: parseHexColor(json['corPrincipal']?.toString()),
      primaryHoverColor: parseHexColor(json['corPrincipalHover']?.toString()),
      buttonColor: parseHexColor(json['corBotoes']?.toString()),
      patientNameColor: parseHexColor(json['corNomePaciente']?.toString()),
      logoBase64: json['iconeEmpresa']?.toString() ?? '',
    );
  }

  final String alias;
  final Color? primaryColor;
  final Color? primaryHoverColor;
  final Color? buttonColor;
  final Color? patientNameColor;
  final String logoBase64;

  Uint8List? get logoBytes {
    if (logoBase64.isEmpty) {
      return null;
    }

    final value =
        (logoBase64.contains(',') ? logoBase64.split(',').last : logoBase64)
            .replaceAll(RegExp(r'\s+'), '');

    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }
}

Color? parseHexColor(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final normalized = value.trim().replaceFirst('#', '');

  if (normalized.length != 6) {
    return null;
  }

  final colorValue = int.tryParse('FF$normalized', radix: 16);

  return colorValue == null ? null : Color(colorValue);
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.terminalName,
    required this.loadVisualIdentity,
  });

  final String? terminalName;
  final VisualIdentityLoader loadVisualIdentity;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<TerminalVisualIdentity>? _visualIdentity;

  @override
  void initState() {
    super.initState();

    final terminalName = widget.terminalName;
    if (terminalName != null) {
      _visualIdentity = widget.loadVisualIdentity(terminalName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminalName = widget.terminalName;

    if (terminalName == null) {
      return const _PageScaffold(child: _TerminalNotFoundContent());
    }

    return FutureBuilder<TerminalVisualIdentity>(
      future: _visualIdentity,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PageScaffold(child: _LoadingContent());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _PageScaffold(
            child: _TerminalErrorContent(
              terminalName: terminalName,
              error: snapshot.error,
            ),
          );
        }

        return _PageScaffold(
          identity: snapshot.data,
          child: _TerminalHomeContent(
            terminalName: terminalName,
            identity: snapshot.data!,
          ),
        );
      },
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child, this.identity});

  final Widget child;
  final TerminalVisualIdentity? identity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          identity?.primaryColor?.withValues(alpha: 0.08) ??
          const Color(0xFFF4F8F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(padding: const EdgeInsets.all(32), child: child),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text('Carregando identidade visual...'),
      ],
    );
  }
}

class _TerminalNotFoundContent extends StatelessWidget {
  const _TerminalNotFoundContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 88,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 32),
        Text(
          'Terminal nao informado',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Acesse usando /terminal=nome-do-terminal.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _TerminalErrorContent extends StatelessWidget {
  const _TerminalErrorContent({required this.terminalName, this.error});

  final String terminalName;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 88,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 32),
        Text(
          'Nao foi possivel carregar este terminal.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          terminalName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (kDebugMode && error != null) ...[
          const SizedBox(height: 24),
          SelectableText(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _TerminalHomeContent extends StatelessWidget {
  const _TerminalHomeContent({
    required this.terminalName,
    required this.identity,
  });

  final String terminalName;
  final TerminalVisualIdentity identity;

  @override
  Widget build(BuildContext context) {
    final logoBytes = identity.logoBytes;
    final primaryColor =
        identity.primaryColor ?? Theme.of(context).colorScheme.primary;
    final buttonColor = identity.buttonColor ?? primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logoBytes != null)
          Image.memory(
            logoBytes,
            height: 112,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.local_hospital_outlined,
                size: 88,
                color: primaryColor,
              );
            },
          )
        else
          Icon(Icons.local_hospital_outlined, size: 88, color: primaryColor),
        const SizedBox(height: 32),
        Text(
          'Autoatendimento',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: identity.patientNameColor ?? primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          identity.alias.isEmpty ? terminalName : identity.alias,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: buttonColor),
            onPressed: () {},
            child: const Text('Iniciar atendimento'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
            onPressed: () {},
            child: const Text('Consultar senha'),
          ),
        ),
      ],
    );
  }
}
