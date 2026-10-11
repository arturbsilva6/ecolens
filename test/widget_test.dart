import 'package:flutter_test/flutter_test.dart';
import 'package:ecolens/app.dart';
import 'package:ecolens/screens/home/home_screen.dart';

void main() {
  testWidgets('EcoLens deve iniciar na HomeScreen', (tester) async {
    // Inicializa o aplicativo no ambiente de teste
    await tester.pumpWidget(const EcoLensApp());

    // Verifica se a tela inicial foi carregada
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
