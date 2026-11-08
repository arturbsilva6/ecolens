import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Indicador de carregamento com o símbolo do EcoLens em uma cor só.
///
/// Sem [value], o anel é desenhado e apagado em giro contínuo, como os
/// indicadores dos apps atuais, e as folhas brotam quando o traço passa
/// por elas. Com [value] (0 a 1), o anel se completa conforme o progresso.
///
/// A cor padrão é a do texto do tema: preta no claro e branca no escuro.
/// Com "Remover animações" ativo no Android, mostra o símbolo parado.
class EcoSpinner extends StatefulWidget {
  const EcoSpinner({
    super.key,
    this.size = 40,
    this.value,
    this.color,
    this.semanticsLabel = 'Carregando',
  });

  final double size;
  final double? value;
  final Color? color;
  final String semanticsLabel;

  @override
  State<EcoSpinner> createState() => _EcoSpinnerState();
}

class _EcoSpinnerState extends State<EcoSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EcoSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spin = widget.value == null && !_reduceMotion;
    if (spin && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!spin && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final value = widget.value?.clamp(0.0, 1.0);
    return Semantics(
      label: widget.semanticsLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: value != null || _reduceMotion
              ? _EcoMark(
                  size: widget.size,
                  color: color,
                  head: value ?? 1,
                  tail: 0,
                  turn: 0,
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    const curve = Curves.easeInOutCubic;
                    return _EcoMark(
                      size: widget.size,
                      color: color,
                      head: curve.transform((t / .62).clamp(0.0, 1.0)),
                      tail: curve.transform(((t - .45) / .55).clamp(0.0, 1.0)),
                      // O anel some por completo no fim de cada volta, então
                      // o giro pode recomeçar sem salto visível.
                      turn: -math.pi * t,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Símbolo monocromático com o anel visível entre [tail] e [head]
/// (frações da volta, no sentido anti-horário a partir das 8 horas).
class _EcoMark extends StatelessWidget {
  const _EcoMark({
    required this.size,
    required this.color,
    required this.head,
    required this.tail,
    required this.turn,
  });

  final double size, head, tail, turn;
  final Color color;

  /// Posição das folhas ao longo da volta do traço.
  static const _leafAt = .5;

  @override
  Widget build(BuildContext context) {
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Widget layer(String name) => Image.asset(
      'assets/branding/intro/$name.png',
      width: size,
      height: size,
      cacheWidth: pixels,
      cacheHeight: pixels,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );

    final shown = (head - _leafAt) / .15;
    final hidden = (tail - _leafAt) / .15;
    final grow = (shown.clamp(0.0, 1.0) * (1 - hidden.clamp(0.0, 1.0)));

    Widget leaf(String name, Alignment base, double delay) {
      final t = ((grow - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t == 0) return const SizedBox.shrink();
      return Transform(
        alignment: base,
        transform: Matrix4.rotationZ(-.5 * (1 - t))
          ..multiply(Matrix4.diagonal3Values(t, t, 1)),
        child: layer(name),
      );
    }

    return Transform.rotate(
      angle: turn,
      child: Stack(
        children: [
          ClipPath(clipper: EcoArcClipper(tail, head), child: layer('ring')),
          leaf('leaf_top', const Alignment(.34, -.44), 0),
          leaf('leaf_side', const Alignment(.43, -.32), .3),
        ],
      ),
    );
  }
}

/// Recorta o anel do logo entre duas frações da volta.
class EcoArcClipper extends CustomClipper<Path> {
  EcoArcClipper(this.from, this.to);

  final double from, to;

  // Centro do anel dentro da imagem (366, 398 de 768 px).
  static const _center = Offset(366 / 768, 398 / 768);
  static const _start = 140 * math.pi / 180;

  @override
  Path getClip(Size size) {
    final sweep = to - from;
    if (sweep >= 1) return Path()..addRect(Offset.zero & size);
    if (sweep <= 0) return Path();
    final center = Offset(size.width * _center.dx, size.height * _center.dy);
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.longestSide),
        _start - 2 * math.pi * from,
        -2 * math.pi * sweep,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(EcoArcClipper oldClipper) =>
      oldClipper.from != from || oldClipper.to != to;
}
