import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_info.dart';

/// Abertura animada do EcoLens.
///
/// 1. O anel do logo é desenhado num giro, começando embaixo à esquerda,
///    e as folhas brotam quando o traço passa por elas.
/// 2. Com o logo completo, o lema entra pela esquerda.
/// 3. Por último aparece a versão; depois a abertura some.
///
/// Um toque pula a animação. Com "Remover animações" ativo no Android,
/// o logo aparece pronto e a abertura fecha logo em seguida.
class AppIntro extends StatefulWidget {
  const AppIntro({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 4600),
    this.startDelay = const Duration(milliseconds: 300),
    this.waitForImages = true,
  });

  final VoidCallback onFinished;
  final Duration duration;

  /// Pausa depois do primeiro quadro, para a Home terminar de montar por
  /// baixo sem engasgar o começo da animação.
  final Duration startDelay;

  /// Só começa quando as camadas do logo já estão decodificadas.
  final bool waitForImages;

  static const layers = ['ring', 'leaf_top', 'leaf_side'];

  @override
  State<AppIntro> createState() => _AppIntroState();
}

class _AppIntroState extends State<AppIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);

  /// Momento em que tudo já está na tela e só falta sumir.
  static const _shown = 0.94;

  bool _started = false, _finished = false;

  Animation<double> _step(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  late final _logoIn = _step(0, .06, Curves.easeOut);
  late final _draw = _step(.02, .52, Curves.easeInOutCubic);
  late final _spin = _step(0, .56, Curves.easeOutCubic);
  late final _leafTop = _step(.36, .54, Curves.easeOutBack);
  late final _leafSide = _step(.42, .60, Curves.easeOutBack);

  /// O lema vem do fundo em duas partes: "Identificar" e, um pouco
  /// depois, "e proteger".
  late final _words = [
    _step(.58, .70, Curves.easeOutBack),
    _step(.70, .82, Curves.easeOutBack),
  ];
  late final _version = _step(.84, .91, Curves.easeOut);
  late final _fadeOut = _step(_shown + .01, 1, Curves.easeIn);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = _shown;
      Future<void>.delayed(const Duration(milliseconds: 900), _skip);
    } else {
      _start();
    }
  }

  /// Sem esta espera, no primeiro carregamento (principalmente em modo
  /// debug) a animação corria enquanto o app ainda não desenhava nada e
  /// terminava sem ser vista.
  Future<void> _start() async {
    if (widget.waitForImages) {
      try {
        await Future.wait([
          for (final name in AppIntro.layers)
            precacheImage(
              AssetImage('assets/branding/intro/$name.png'),
              context,
            ),
        ]).timeout(const Duration(seconds: 3));
      } catch (_) {
        // Se a imagem demorar, a animação segue mesmo assim.
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(widget.startDelay);
    if (mounted && !_finished && _controller.value == 0) {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_finished) {
      _finished = true;
      widget.onFinished();
    }
  }

  void _skip() {
    if (!mounted || _finished) return;
    if (_controller.value < _shown) _controller.value = _shown;
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logo = math.min(shortest * .42, 180.0);
    return Semantics(
      label: 'EcoLens. ${AppInfo.tagline}. Versão ${AppInfo.version}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Opacity(
            opacity: 1 - _fadeOut.value,
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _logo(logo),
                          const SizedBox(height: 28),
                          _tagline(
                            theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: .4,
                            ),
                            dark: theme.brightness == Brightness.dark,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Opacity(
                        opacity: _version.value,
                        child: Text(
                          'Versão ${AppInfo.version}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Identificar" no ciano do logo e "e proteger" no verde, cada parte
  /// vindo do fundo (zoom in). No tema claro os tons são um pouco mais
  /// escuros para o texto continuar legível sobre o fundo claro.
  Widget _tagline(TextStyle? style, {required bool dark}) {
    final cyan = dark ? const Color(0xFF2CB5A0) : const Color(0xFF1E9584);
    final green = dark ? const Color(0xFF7ED957) : const Color(0xFF3E9E2C);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      children: [
        _zoomIn(
          AppInfo.taglineFirst,
          _words[0].value,
          style?.copyWith(color: cyan),
        ),
        _zoomIn(
          AppInfo.taglineSecond,
          _words[1].value,
          style?.copyWith(color: green),
        ),
      ],
    );
  }

  Widget _zoomIn(String text, double t, TextStyle? style) => Opacity(
    opacity: t.clamp(0.0, 1.0),
    child: Transform.scale(
      scale: .35 + .65 * t,
      child: Text(text, style: style),
    ),
  );

  Widget _logo(double size) {
    Widget layer(String name) => Image.asset(
      'assets/branding/intro/$name.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );

    // As folhas crescem a partir do caule, com um leve giro.
    Widget leaf(String name, Animation<double> grow, Alignment base) {
      final t = grow.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform(
          alignment: base,
          transform: Matrix4.rotationZ(-.5 * (1 - t))
            ..multiply(Matrix4.diagonal3Values(t, t, 1)),
          child: layer(name),
        ),
      );
    }

    return Opacity(
      opacity: _logoIn.value,
      child: Transform.rotate(
        angle: -.6 * (1 - _spin.value),
        child: Transform.scale(
          scale: .86 + .14 * _spin.value,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                ClipPath(
                  clipper: _SweepClipper(_draw.value),
                  child: layer('ring'),
                ),
                leaf('leaf_top', _leafTop, const Alignment(.34, -.44)),
                leaf('leaf_side', _leafSide, const Alignment(.43, -.32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Revela o anel como um ponteiro girando no sentido anti-horário,
/// a partir da posição de 8 horas (como a seta do esboço).
class _SweepClipper extends CustomClipper<Path> {
  _SweepClipper(this.progress);

  final double progress;

  // Centro do anel dentro da imagem (366, 398 de 768 px).
  static const _center = Offset(366 / 768, 398 / 768);
  static const _start = 140 * math.pi / 180;

  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final center = Offset(size.width * _center.dx, size.height * _center.dy);
    if (progress <= 0) return Path();
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.longestSide),
        _start,
        -2 * math.pi * progress,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_SweepClipper oldClipper) =>
      oldClipper.progress != progress;
}
