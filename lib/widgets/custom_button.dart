import 'package:flutter/material.dart';

/// Ação principal ou tonal, com estilos herdados do tema e suporte a desabilitar.
class EcoLensButton extends StatelessWidget {
  const EcoLensButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final content = Text(label, textAlign: TextAlign.center);
    if (icon == null) {
      return tonal
          ? FilledButton.tonal(onPressed: onPressed, child: content)
          : FilledButton(onPressed: onPressed, child: content);
    }
    if (tonal) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: content,
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: content,
    );
  }
}
