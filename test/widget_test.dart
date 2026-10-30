import 'package:flutter_test/flutter_test.dart';

import 'package:ecolens/app.dart';
import 'package:ecolens/screens/home/home_screen.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // Simula as preferências do dispositivo nos testes
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('EcoLens deve iniciar na HomeScreen', (tester) async {
    // Inicializa o aplicativo
    await tester.pumpWidget(const EcoLensApp());

    // Verifica se a Home foi carregada
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
