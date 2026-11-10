import 'package:flutter/material.dart';

/// Aviso no centro da tela confirmando o resultado de uma ação importante.
/// A pessoa precisa tocar em OK, então não perde a mensagem.
Future<void> showResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool success = true,
}) {
  final colors = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: Icon(
        success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        size: 48,
        color: success ? const Color(0xFF2E9E5B) : colors.primary,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
