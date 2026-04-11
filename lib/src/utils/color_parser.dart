import 'package:flutter/material.dart';

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
