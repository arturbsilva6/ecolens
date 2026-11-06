import 'package:flutter/material.dart';

/// Indicador com a identidade visual do EcoLens, sem spinner circular.
/// A animação respeita a preferência do sistema para reduzir movimento.
class EcoLensLoadingIndicator extends StatefulWidget {
  const EcoLensLoadingIndicator({
    super.key,
    this.message = 'Carregando...',
    this.size = 88,
    this.showMessage = true,
  });

  final String message;
  final double size;
  final bool showMessage;

  @override
  State<EcoLensLoadingIndicator> createState() =>
      _EcoLensLoadingIndicatorState();
}

class _EcoLensLoadingIndicatorState extends State<EcoLensLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.5,
    );
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final visibleMessage = widget.message.isEmpty
        ? 'Carregando...'
        : widget.message;

    return Semantics(
      label: visibleMessage,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              child: Image.asset(
                'assets/branding/ecolens_logo_loader.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              builder: (context, child) => Transform.scale(
                scale: reduceMotion ? 1.0 : _pulse.value,
                child: Opacity(
                  opacity: reduceMotion ? 1.0 : 0.86 + _controller.value * 0.14,
                  child: child,
                ),
              ),
            ),
            if (widget.showMessage) ...[
              const SizedBox(height: 12),
              Text(
                visibleMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
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
