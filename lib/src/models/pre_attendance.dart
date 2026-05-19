import 'dart:convert';

class PreAttendanceQuery {
  const PreAttendanceQuery({
    required this.message,
    required this.status,
    required this.preAttendances,
  });

  factory PreAttendanceQuery.fromJson(Map<String, dynamic> json) {
    final result = json['ConsultaResult'];
    final payload = result is Map<String, dynamic> ? result : json;
    final preAttendances = payload['preAtendimentos'];

    return PreAttendanceQuery(
      message: payload['mensagem']?.toString() ?? '',
      status: payload['status']?.toString() ?? '',
      preAttendances: preAttendances is List
          ? preAttendances
                .whereType<Map<String, dynamic>>()
                .map(PreAttendance.fromJson)
                .toList()
          : const [],
    );
  }

  factory PreAttendanceQuery.fromResponseBody(String body) {
    return PreAttendanceQuery.fromJson(_decodePreAttendanceBody(body));
  }

  final String message;
  final String status;
  final List<PreAttendance> preAttendances;

  List<PreAttendanceGuide> get guides {
    return [
      for (final preAttendance in preAttendances)
        for (final guide in preAttendance.guides)
          guide.copyWith(
            preAttendanceNumber: preAttendance.number,
            type: preAttendance.type,
          ),
    ];
  }
}

Map<String, dynamic> _decodePreAttendanceBody(String body) {
  try {
    final payload = jsonDecode(body);

    if (payload is Map<String, dynamic>) {
      return payload;
    }
  } on FormatException {
    final repairedBody = _repairPreAttendanceJson(body);
    final payload = jsonDecode(repairedBody);

    if (payload is Map<String, dynamic>) {
      return payload;
    }
  }

  throw Exception('Resposta do BFF nao e um objeto JSON.');
}

String _repairPreAttendanceJson(String body) {
  final unquotedScalarValue = RegExp(
    r'("[^"\\]*(?:\\.[^"\\]*)*"\s*:\s*)(?!["{\[]|null\b|true\b|false\b)([^,}\]]*)',
    caseSensitive: false,
  );

  return body.replaceAllMapped(unquotedScalarValue, (match) {
    final prefix = match.group(1)!;
    final value = match.group(2)!.trim();

    if (value.isEmpty) {
      return '${prefix}null';
    }

    return '$prefix${_isJsonScalar(value) ? value : jsonEncode(value)}';
  });
}

bool _isJsonScalar(String value) {
  try {
    jsonDecode('[$value]');

    return true;
  } on FormatException {
    return false;
  }
}

class PreAttendance {
  const PreAttendance({
    required this.number,
    required this.origin,
    required this.type,
    required this.attendanceType,
    required this.guides,
  });

  factory PreAttendance.fromJson(Map<String, dynamic> json) {
    final guides = json['guias'];

    return PreAttendance(
      number: json['numeroPreAtendimento']?.toString() ?? '',
      origin: json['origem']?.toString() ?? '',
      type: json['tipo']?.toString() ?? '',
      attendanceType: json['tipoAtendimento']?.toString() ?? '',
      guides: guides is List
          ? guides
                .whereType<Map<String, dynamic>>()
                .map(PreAttendanceGuide.fromJson)
                .toList()
          : const [],
    );
  }

  final String number;
  final String origin;
  final String type;
  final String attendanceType;
  final List<PreAttendanceGuide> guides;
}

class PreAttendanceGuide {
  const PreAttendanceGuide({
    required this.operatorGuideNumber,
    required this.authorizationPassword,
    required this.requesterName,
    required this.issueDate,
    required this.exams,
    this.healthPlan = '',
    this.preAttendanceNumber = '',
    this.type = '',
  });

  factory PreAttendanceGuide.fromJson(Map<String, dynamic> json) {
    final requester = json['solicitante'];
    final authorization = json['autorizacao'];
    final exams = json['exames'];

    return PreAttendanceGuide(
      operatorGuideNumber: json['numeroGuiaOperadora']?.toString() ?? '',
      authorizationPassword: authorization is Map<String, dynamic>
          ? authorization['senha']?.toString() ?? ''
          : '',
      requesterName: requester is Map<String, dynamic>
          ? requester['nome']?.toString() ?? ''
          : '',
      issueDate: json['dataEmissao']?.toString() ?? '',
      healthPlan: _extractHealthPlan(json),
      exams: exams is List
          ? exams
                .whereType<Map<String, dynamic>>()
                .map(PreAttendanceExam.fromJson)
                .toList()
          : const [],
    );
  }

  final String preAttendanceNumber;
  final String type;
  final String operatorGuideNumber;
  final String authorizationPassword;
  final String requesterName;
  final String issueDate;
  final String healthPlan;
  final List<PreAttendanceExam> exams;

  PreAttendanceGuide copyWith({
    String? preAttendanceNumber,
    String? type,
    String? healthPlan,
  }) {
    return PreAttendanceGuide(
      preAttendanceNumber: preAttendanceNumber ?? this.preAttendanceNumber,
      type: type ?? this.type,
      operatorGuideNumber: operatorGuideNumber,
      authorizationPassword: authorizationPassword,
      requesterName: requesterName,
      issueDate: issueDate,
      healthPlan: healthPlan ?? this.healthPlan,
      exams: exams,
    );
  }
}

String _extractHealthPlan(Map<String, dynamic> json) {
  final candidate = json['operadora'] ??
      json['convenio'] ??
      json['codigoConvenio'] ??
      json['codigoOperadora'] ??
      json['idOperadora'];

  if (candidate is String && candidate.isNotEmpty) {
    return candidate;
  }

  if (candidate is num) {
    return candidate.toString();
  }

  if (candidate is Map<String, dynamic>) {
    for (final key in ['codigo', 'id', 'nome', 'sigla']) {
      final nested = candidate[key];
      if (nested is String && nested.isNotEmpty) {
        return nested;
      }
      if (nested is num) {
        return nested.toString();
      }
    }
  }

  return '';
}

class PreAttendanceExam {
  const PreAttendanceExam({
    required this.code,
    required this.description,
    required this.materialDescription,
  });

  factory PreAttendanceExam.fromJson(Map<String, dynamic> json) {
    return PreAttendanceExam(
      code: json['codigoExame']?.toString() ?? '',
      description: json['descricaoExame']?.toString() ?? '',
      materialDescription: json['descricaoMaterial']?.toString() ?? '',
    );
  }

  final String code;
  final String description;
  final String materialDescription;
}
