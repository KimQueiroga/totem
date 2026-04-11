import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/color_parser.dart';

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
