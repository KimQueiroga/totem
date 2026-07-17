class ThirdPartyAuthorization {
  const ThirdPartyAuthorization({
    required this.name,
    required this.relationship,
    required this.documentType,
    required this.documentNumber,
    this.unidentified = false,
  });

  final String name;
  final String relationship;
  final String documentType;
  final String documentNumber;
  final bool unidentified;
}

