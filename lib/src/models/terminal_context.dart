class TerminalContext {
  const TerminalContext({
    required this.company,
    required this.store,
    required this.printer,
    required this.location,
    required this.services,
  });

  factory TerminalContext.fromJson(Map<String, dynamic> json) {
    final services = json['servicos'];

    return TerminalContext(
      company: json['empresa']?.toString() ?? '',
      store: json['loja']?.toString() ?? '',
      printer: json['impressora']?.toString() ?? '',
      location: json['localidade']?.toString() ?? '',
      services: services is List
          ? services
                .whereType<Map<String, dynamic>>()
                .map(TerminalService.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String company;
  final String store;
  final String printer;
  final String location;
  final List<TerminalService> services;
}

class TerminalService {
  const TerminalService({
    required this.id,
    required this.name,
    required this.hostName,
    required this.termsOfUse,
  });

  factory TerminalService.fromJson(Map<String, dynamic> json) {
    return TerminalService(
      id: json['idServico']?.toString() ?? '',
      name: json['nomeServico']?.toString() ?? '',
      hostName: json['hostname']?.toString() ?? '',
      termsOfUse: json['termoUso']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String hostName;
  final String termsOfUse;

  bool get isPreAttendance => name.trim().toUpperCase() == 'PRE_ATENDIMENTO';

  String get displayName {
    final words = name
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');

    final value = words.join(' ');

    return value.isEmpty ? 'Servico $id' : value;
  }
}
