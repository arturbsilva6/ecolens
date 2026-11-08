import 'package:flutter/material.dart';

import 'eco_spinner.dart';

/// Símbolo do EcoLens girando, com uma mensagem opcional embaixo.
class EcoLensLoadingIndicator extends StatelessWidget {
  const EcoLensLoadingIndicator({
    super.key,
    this.message = 'Carregando...',
    this.size = 56,
    this.showMessage = true,
  });

  final String message;
  final double size;
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    final visibleMessage = message.isEmpty ? 'Carregando...' : message;
    return Semantics(
      label: visibleMessage,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EcoSpinner(size: size),
            if (showMessage) ...[
              const SizedBox(height: 12),
              Text(
                visibleMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Conteúdo de um diálogo de carregamento. O chamador controla sua abertura
/// e fechamento, sem alterar o fluxo assíncrono existente.
class EcoLensLoadingDialog extends StatelessWidget {
  const EcoLensLoadingDialog({super.key, this.message = 'Carregando...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: EcoLensLoadingIndicator(message: message),
      ),
    );
  }
}
