import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_authentication.dart';
import '../models/pre_attendance.dart';
import '../models/terminal_context.dart';
import '../models/terminal_visual_identity.dart';

const bffBaseUrl = String.fromEnvironment(
  'BFF_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

typedef VisualIdentityLoader =
    Future<TerminalVisualIdentity> Function(String terminalName);

typedef TerminalContextLoader =
    Future<TerminalContext> Function(String terminalName);

typedef ClientAuthenticator =
    Future<ClientAuthentication> Function(ClientCredentials credentials);

typedef ClientUpdater =
    Future<void> Function(ClientProfileUpdate profileUpdate);

typedef PreAttendanceLoader =
    Future<PreAttendanceQuery> Function(String clientId);

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

Future<TerminalContext> fetchTerminalContext(String terminalName) async {
  final uri = Uri.parse(
    '$bffBaseUrl/terminal-context',
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

  final context = payload['contexto'];

  if (context is! Map<String, dynamic>) {
    throw Exception('Resposta sem contexto.');
  }

  return TerminalContext.fromJson(context);
}

Future<ClientAuthentication> authenticateClientWithCpf(
  ClientCredentials credentials,
) async {
  final uri = Uri.parse('$bffBaseUrl/client-token');
  final response = await http.post(
    uri,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'cpf': credentials.cpf,
      'password': credentials.password,
      'birthDate': _toApiBirthDate(credentials.birthDate),
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'BFF retornou HTTP ${response.statusCode}: ${_truncate(response.body)}',
    );
  }

  final payload = jsonDecode(response.body);

  if (payload is! Map<String, dynamic>) {
    throw Exception('Resposta do BFF nao e um objeto JSON.');
  }

  return ClientAuthentication.fromJson(payload);
}

Future<void> updateClientProfile(ClientProfileUpdate profileUpdate) async {
  if (profileUpdate.clientId.isEmpty) {
    throw Exception('Resposta de autenticacao sem ID do cliente.');
  }

  final uri = Uri.parse(
    '$bffBaseUrl/client',
  ).replace(queryParameters: {'id': profileUpdate.clientId});
  final response = await http.put(
    uri,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode(profileUpdate.toJson()),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'BFF retornou HTTP ${response.statusCode}: ${_truncate(response.body)}',
    );
  }
}

Future<PreAttendanceQuery> fetchPreAttendance(String clientId) async {
  final uri = Uri.parse(
    '$bffBaseUrl/pre-attendance',
  ).replace(queryParameters: {'clientId': clientId});
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

  return PreAttendanceQuery.fromJson(payload);
}

String _truncate(String value) {
  const maxLength = 300;
  return value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}...';
}

String _toApiBirthDate(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);

  if (match == null) {
    return value;
  }

  return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
}
