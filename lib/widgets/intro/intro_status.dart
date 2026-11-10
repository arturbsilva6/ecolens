import 'package:flutter/widgets.dart';

/// Avisa a árvore de widgets quando a abertura animada terminou, para que
/// detalhes da Home (como o galho do cabeçalho) só comecem depois dela.
class IntroStatus extends InheritedNotifier<ValueNotifier<bool>> {
  const IntroStatus({
    super.key,
    required ValueNotifier<bool> done,
    required super.child,
  }) : super(notifier: done);

  /// Sem abertura na árvore (testes, telas isoladas), considera concluída.
  static bool doneOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<IntroStatus>()
          ?.notifier
          ?.value ??
      true;
}
