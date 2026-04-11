import 'package:flutter/material.dart';

class LoadingContent extends StatelessWidget {
  const LoadingContent({
    super.key,
    this.message = 'Carregando identidade visual...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message),
      ],
    );
  }
}
