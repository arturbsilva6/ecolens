import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um passo do tour: o que destacar e o que dizer sobre ele.
class TourStep {
  const TourStep({
    required this.target,
    required this.title,
    required this.text,
    this.area,
  });

  /// Widget destacado (o retângulo dele na tela).
  final GlobalKey target;
  final String title;
  final String text;

  /// Ajusta a área destacada a partir do retângulo do alvo (por exemplo,
  /// só alguns botões da barra inferior).
  final Rect Function(Rect bounds)? area;
}

/// Tour de primeiro contato: a tela escurece e cada recurso é destacado,
/// um por vez, com uma explicação curta.
///
/// Acessibilidade: cada passo é anunciado pelo leitor de tela ("Passo 2 de
/// 5..."), nunca avança sozinho, pode ser pulado a qualquer momento (inclusive
/// com o botão voltar) e não anima com "Remover animações" ligado.
class OnboardingTour {
  static const _seenKey = 'onboarding_tour_seen_v1';

  static Future<bool> seen({SharedPreferencesAsync? preferences}) async {
    try {
      return await (preferences ?? SharedPreferencesAsync()).getBool(
            _seenKey,
          ) ??
          false;
    } catch (_) {
      // Sem armazenamento, melhor não insistir no tour.
      return true;
    }
  }

  static Future<void> markSeen({SharedPreferencesAsync? preferences}) async {
    try {
      await (preferences ?? SharedPreferencesAsync()).setBool(_seenKey, true);
    } catch (_) {
      // Na pior hipótese, o tour aparece de novo na próxima abertura.
    }
  }

  /// Mostra o tour e devolve quando a pessoa termina ou pula.
  static Future<void> show(
    BuildContext context,
    List<TourStep> steps, {
    SharedPreferencesAsync? preferences,
  }) async {
    if (steps.isEmpty) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _TourView(steps: steps),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    await markSeen(preferences: preferences);
  }
}

class _TourView extends StatefulWidget {
  const _TourView({required this.steps});

  final List<TourStep> steps;

  @override
  State<_TourView> createState() => _TourViewState();
}

class _TourViewState extends State<_TourView> {
  int _index = 0;

  TourStep get _step => widget.steps[_index];

  Rect? _targetRect() {
    final box = _step.target.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    return (_step.area?.call(bounds) ?? bounds).inflate(8);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect();
    if (rect == null) {
      // Alvo fora da tela (por exemplo, lista ainda carregando): pula o passo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _next();
      });
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final size = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;
    final cardBelow = rect.center.dy < size.height / 2;

    return PopScope(
      // Voltar no Android encerra o tour (conta como pular).
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: TweenAnimationBuilder<Rect?>(
                    tween: RectTween(end: rect),
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    builder: (context, hole, _) => CustomPaint(
                      painter: _SpotlightPainter(
                        hole: hole ?? rect,
                        shade: Colors.black.withValues(alpha: .72),
                        ring: colors.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: cardBelow ? rect.bottom + 16 : null,
              bottom: cardBelow ? null : size.height - rect.top + 16,
              child: SafeArea(
                top: !cardBelow,
                bottom: cardBelow,
                child: _TourCard(
                  key: ValueKey(_index),
                  step: _step,
                  index: _index,
                  total: widget.steps.length,
                  last: last,
                  onNext: _next,
                  onBack: _index == 0 ? null : _back,
                  onSkip: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.last,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final TourStep step;
  final int index, total;
  final bool last;
  final VoidCallback onNext, onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anunciado inteiro pelo TalkBack a cada passo.
            Semantics(
              liveRegion: true,
              container: true,
              label: 'Passo ${index + 1} de $total. ${step.title}. ${step.text}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passo ${index + 1} de $total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(step.text),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (!last)
                  TextButton(onPressed: onSkip, child: const Text('Pular'))
                else
                  const SizedBox(width: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onBack != null)
                      TextButton(onPressed: onBack, child: const Text('Voltar')),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: onNext,
                      child: Text(last ? 'Começar a usar' : 'Próximo'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Escurece a tela inteira, menos a área destacada, que ganha um contorno.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.shade,
    required this.ring,
  });

  final Rect hole;
  final Color shade, ring;

  @override
  void paint(Canvas canvas, Size size) {
    // Itens pequenos ficam num círculo; áreas grandes, em cantos arredondados.
    final radius = Radius.circular(
      hole.shortestSide / 2 < 36 ? hole.shortestSide / 2 : 28,
    );
    final spot = RRect.fromRectAndRadius(hole, radius);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(spot),
      Paint()..color = shade,
    );
    canvas.drawRRect(
      spot,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.shade != shade || old.ring != ring;
}
