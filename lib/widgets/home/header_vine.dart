import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../intro/intro_status.dart';

/// Galho que cresce do símbolo do EcoLens para a direita, na base do
/// cabeçalho, logo depois da abertura. Folhas brotam ao longo do caminho;
/// depois de alguns segundos o galho some e o cabeçalho volta ao normal.
///
/// Toca uma vez por abertura do app e não aparece com "Remover animações".
class HeaderVine extends StatefulWidget {
  const HeaderVine({super.key, this.startX = 50});

  /// Onde o galho nasce (borda direita do símbolo).
  final double startX;

  /// Permite tocar de novo nos testes.
  @visibleForTesting
  static void resetForTest() => _HeaderVineState._played = false;

  @override
  State<HeaderVine> createState() => _HeaderVineState();
}

class _HeaderVineState extends State<HeaderVine>
    with SingleTickerProviderStateMixin {
  static bool _played = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_played || reduceMotion || !IntroStatus.doneOf(context)) return;
    _played = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _VinePainter(
              _controller,
              startX: widget.startX,
              stem: dark ? AppColors.accent : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VinePainter extends CustomPainter {
  _VinePainter(this.animation, {required this.startX, required this.stem})
    : super(repaint: animation);

  final Animation<double> animation;
  final double startX;
  final Color stem;

  static const _leafColors = [
    Color(0xFF2CB5A0),
    Color(0xFF7ED957),
    Color(0xFF3FA34D),
  ];

  /// (posição ao longo do galho, para cima?, tamanho)
  static const _leaves = [
    (.13, true, 8.0),
    (.22, false, 5.0),
    (.33, true, 9.0),
    (.45, false, 5.5),
    (.55, true, 8.0),
    (.66, true, 6.5),
    (.76, false, 5.0),
    (.86, true, 8.5),
    (.985, true, 7.0),
  ];

  static double _part(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final grow = Curves.easeInOutCubic.transform(_part(t, .08, .55));
    final fade = 1 - Curves.easeIn.transform(_part(t, .8, 1));
    final end = size.width - 64;
    if (grow <= 0 || fade <= 0 || end <= startX + 60) return;

    // Nasce embaixo do símbolo, desce até a base e segue ondulando.
    final y = size.height - 6;
    final path = Path()
      ..moveTo(startX - 4, size.height * .66)
      ..quadraticBezierTo(startX + 4, y, startX + 30, y - 1);
    var x = startX + 30;
    var up = true;
    while (x < end) {
      final next = math.min(x + 48, end);
      path.quadraticBezierTo((x + next) / 2, up ? y - 6 : y + 2, next, y - 1);
      x = next;
      up = !up;
    }
    path.quadraticBezierTo(end + 12, y - 2, end + 14, y - 12);

    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * grow),
      Paint()
        ..color = stem.withValues(alpha: .85 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < _leaves.length; i++) {
      final (at, upward, length) = _leaves[i];
      final scale = Curves.easeOutBack.transform(
        ((grow - at) / .08).clamp(0.0, 1.0),
      );
      if (scale <= 0) continue;
      final tangent = metric.getTangentForOffset(metric.length * at);
      if (tangent == null) continue;
      final direction = math.atan2(tangent.vector.dy, tangent.vector.dx);
      canvas
        ..save()
        ..translate(tangent.position.dx, tangent.position.dy)
        ..rotate(direction + (upward ? -.95 : .8))
        ..scale(scale);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(length * .5, -length * .45, length, 0)
          ..quadraticBezierTo(length * .5, length * .45, 0, 0),
        Paint()
          ..color = _leafColors[i % _leafColors.length].withValues(
            alpha: fade,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_VinePainter oldDelegate) =>
      oldDelegate.stem != stem || oldDelegate.startX != startX;
}
