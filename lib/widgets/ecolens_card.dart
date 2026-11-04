import 'package:flutter/material.dart';

/// Superfície reutilizável que preserva recorte, foco e feedback de toque.
class EcoLensCard extends StatelessWidget {
  const EcoLensCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      margin: EdgeInsets.zero,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
