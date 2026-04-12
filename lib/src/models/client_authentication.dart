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
    this.clientId,
    required this.fullName,
    required this.socialName,
    required this.cpf,
    required this.birthDate,
    this.gender,
    required this.email,
    required this.mobilePhoneNumber,
    required this.homePhoneNumber,
    this.workPhoneNumber,
    this.fatherName,
    required this.motherName,
    this.responsibleName,
    this.nationality,
    this.documentType,
    this.documentNumber,
    this.street,
    required this.streetAndComplement,
    this.numberStreet,
    this.neighbourhood,
    this.complement,
    this.postalCode,
    required this.city,
    required this.uf,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      clientId: json['clienteId']?.toString(),
      fullName: json['fullName']?.toString() ?? '',
      socialName: json['socialName']?.toString(),
      cpf: json['cpf']?.toString() ?? '',
      birthDate: json['birthDate']?.toString() ?? '',
      gender: json['gender']?.toString(),
      email: json['email']?.toString(),
      mobilePhoneNumber: json['mobilePhoneNumber']?.toString(),
      homePhoneNumber: json['homePhoneNumber']?.toString(),
      workPhoneNumber: json['workPhoneNumber']?.toString(),
      fatherName: json['fatherName']?.toString(),
      motherName: json['motherName']?.toString(),
      responsibleName: json['responsibleName']?.toString(),
      nationality: json['nationality']?.toString(),
      documentType: json['documentType']?.toString(),
      documentNumber: json['documentNumber']?.toString(),
      street: json['street']?.toString(),
      streetAndComplement: json['streetAndComplement']?.toString(),
      numberStreet: json['numberStreet']?.toString(),
      neighbourhood: json['neighbourhood']?.toString(),
      complement: json['complement']?.toString(),
      postalCode: json['postalCode']?.toString(),
      city: json['city']?.toString(),
      uf: json['uf']?.toString(),
    );
  }

  final String? clientId;
  final String fullName;
  final String? socialName;
  final String cpf;
  final String birthDate;
  final String? gender;
  final String? email;
  final String? mobilePhoneNumber;
  final String? homePhoneNumber;
  final String? workPhoneNumber;
  final String? fatherName;
  final String? motherName;
  final String? responsibleName;
  final String? nationality;
  final String? documentType;
  final String? documentNumber;
  final String? street;
  final String? streetAndComplement;
  final String? numberStreet;
  final String? neighbourhood;
  final String? complement;
  final String? postalCode;
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

class ClientProfileUpdate {
  const ClientProfileUpdate({
    required this.authentication,
    required this.email,
    required this.mobilePhoneNumber,
    required this.homePhoneNumber,
    required this.motherName,
    required this.streetAndComplement,
    required this.cityAndState,
  });

  final ClientAuthentication authentication;
  final String email;
  final String mobilePhoneNumber;
  final String homePhoneNumber;
  final String motherName;
  final String streetAndComplement;
  final String cityAndState;

  String get clientId => authentication.user.clientId?.trim() ?? '';

  bool get hasChanges {
    final user = authentication.user;

    return _normalized(email) != _normalized(user.email) ||
        _normalized(mobilePhoneNumber) != _normalized(user.mobilePhoneNumber) ||
        _normalized(homePhoneNumber) != _normalized(user.homePhoneNumber) ||
        _normalized(motherName) != _normalized(user.motherName) ||
        _normalized(streetAndComplement) !=
            _normalized(user.streetAndComplement) ||
        _normalized(cityAndState) != _normalized(user.cityAndState);
  }

  Map<String, Object?> toJson() {
    final user = authentication.user;
    final parsedCityAndState = _parseCityAndState(cityAndState, user);
    final addressStreet =
        _normalized(streetAndComplement) ==
            _normalized(user.streetAndComplement)
        ? user.street ?? streetAndComplement.trim()
        : streetAndComplement.trim();

    return {
      'name': user.fullName,
      'socialName': user.socialName ?? '',
      'cpf': user.cpf,
      'gender': user.gender ?? '',
      'birthDate': user.birthDate,
      'disabled': 0,
      'title': 0,
      'socialTitle': 0,
      'socialGender': 0,
      'address': {
        'street': addressStreet,
        'typeStreet': '',
        'zipCode': user.postalCode ?? '',
        'number': user.numberStreet ?? '',
        'neighborhood': user.neighbourhood ?? '',
        'complement': user.complement ?? '',
        'state': parsedCityAndState.state,
        'city': parsedCityAndState.city,
        'reference': '',
      },
      'documentType': user.documentType ?? 'CPF',
      'document': user.documentNumber ?? user.cpf,
      'cns': '',
      'nationality': user.nationality ?? 'Brasileiro',
      'fatherName': user.fatherName ?? '',
      'motherName': motherName.trim(),
      'responsibleName': user.responsibleName ?? '',
      'weight': 0,
      'height': 0,
      'maritalStatus': '',
      'contacts': {
        'mainPhone': mobilePhoneNumber.trim(),
        'secondaryPhone': homePhoneNumber.trim(),
        'email': email.trim(),
        'via': <String, Object?>{},
      },
      'veterinarian': {'species': '', 'breed': ''},
    };
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

String _normalized(String? value) => value?.trim() ?? '';

_CityAndState _parseCityAndState(String value, ClientUser user) {
  final trimmedValue = value.trim();

  if (trimmedValue.isEmpty) {
    return const _CityAndState(city: '', state: '');
  }

  final parts = trimmedValue.split(' - ');

  if (parts.length >= 2) {
    return _CityAndState(city: parts.first.trim(), state: parts.last.trim());
  }

  return _CityAndState(city: trimmedValue, state: user.uf ?? '');
}

class _CityAndState {
  const _CityAndState({required this.city, required this.state});

  final String city;
  final String state;
}
