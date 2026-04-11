class ClientAuthentication {
  const ClientAuthentication({
    required this.id,
    required this.millisecondsToExpire,
    required this.user,
  });

  factory ClientAuthentication.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    if (user is! Map<String, dynamic>) {
      throw Exception('Resposta sem dados do cliente.');
    }

    return ClientAuthentication(
      id: json['id']?.toString() ?? '',
      millisecondsToExpire: _intValue(json['milisecondsToExpire']) ?? 0,
      user: ClientUser.fromJson(user),
    );
  }

  final String id;
  final int millisecondsToExpire;
  final ClientUser user;
}

class ClientUser {
  const ClientUser({
    required this.fullName,
    required this.socialName,
    required this.cpf,
    required this.birthDate,
    required this.email,
    required this.mobilePhoneNumber,
    required this.homePhoneNumber,
    required this.motherName,
    required this.streetAndComplement,
    required this.city,
    required this.uf,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      fullName: json['fullName']?.toString() ?? '',
      socialName: json['socialName']?.toString(),
      cpf: json['cpf']?.toString() ?? '',
      birthDate: json['birthDate']?.toString() ?? '',
      email: json['email']?.toString(),
      mobilePhoneNumber: json['mobilePhoneNumber']?.toString(),
      homePhoneNumber: json['homePhoneNumber']?.toString(),
      motherName: json['motherName']?.toString(),
      streetAndComplement: json['streetAndComplement']?.toString(),
      city: json['city']?.toString(),
      uf: json['uf']?.toString(),
    );
  }

  final String fullName;
  final String? socialName;
  final String cpf;
  final String birthDate;
  final String? email;
  final String? mobilePhoneNumber;
  final String? homePhoneNumber;
  final String? motherName;
  final String? streetAndComplement;
  final String? city;
  final String? uf;

  String get displayName {
    final value = socialName?.trim();

    return value == null || value.isEmpty ? fullName : value;
  }

  String get cityAndState {
    final values = [
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (uf != null && uf!.trim().isNotEmpty) uf!.trim(),
    ];

    return values.join(' - ');
  }
}

class ClientCredentials {
  const ClientCredentials({
    required this.cpf,
    required this.password,
    required this.birthDate,
  });

  final String cpf;
  final String password;
  final String birthDate;
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}
