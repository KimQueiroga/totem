class BarcodeResultPrint {
  const BarcodeResultPrint({
    required this.barcode,
    required this.printed,
    required this.released,
    required this.message,
    this.orderStatus,
    this.clientCode,
    this.status,
  });

  factory BarcodeResultPrint.fromJson(Map<String, dynamic> json) {
    return BarcodeResultPrint(
      barcode: json['barcode']?.toString() ?? '',
      printed: json['printed'] == true,
      released: json['released'] == true,
      message: json['message']?.toString() ?? '',
      orderStatus: _intValue(json['orderStatus']),
      clientCode: json['clientCode']?.toString(),
      status: json['status']?.toString(),
    );
  }

  final String barcode;
  final bool printed;
  final bool released;
  final String message;
  final int? orderStatus;
  final String? clientCode;
  final String? status;
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
