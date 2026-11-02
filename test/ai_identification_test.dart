import 'dart:typed_data';

import 'package:ecolens/models/ai_identification_result.dart';
import 'package:ecolens/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JPEG válido é reconhecido sem enviar dados', () {
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]);
    expect(AiService.validateImage(bytes), 'image/jpeg');
  });

  test('PNG válido é reconhecido sem enviar dados', () {
    final bytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ]);
    expect(AiService.validateImage(bytes), 'image/png');
  });

  test('Formato desconhecido é rejeitado', () {
    final bytes = Uint8List.fromList([0x00, 0x01, 0x02]);
    expect(() => AiService.validateImage(bytes), throwsFormatException);
  });

  test('Fotos maiores que 4 MB são rejeitadas', () {
    final bytes = Uint8List(4 * 1024 * 1024 + 1);
    expect(() => AiService.validateImage(bytes), throwsFormatException);
  });

  test('A IA não atribui identificação sem nome', () {
    final result = AiIdentificationResult.fromJson({
      'identified': true,
      'commonName': ' ',
      'scientificName': '',
      'explanation': 'Foto sem detalhes suficientes',
    });
    expect(result.identified, isFalse);
    expect(result.scientificName, isNull);
  });

  test('Resposta inconclusiva não mostra espécie inventada', () {
    final result = AiIdentificationResult.fromJson({
      'identified': false,
      'commonName': 'Jararaca',
      'scientificName': 'Bothrops jararaca',
      'explanation': 'Imagem insuficiente',
    });
    expect(result.identified, isFalse);
    expect(result.commonName, isNull);
    expect(result.scientificName, isNull);
  });

  test('Sugestão conserva apenas os dados declarados', () {
    final result = AiIdentificationResult.fromJson({
      'identified': true,
      'commonName': 'Jararaca',
      'scientificName': 'Bothrops jararaca',
      'explanation': 'Padrão de manchas observado',
    });
    expect(result.identified, isTrue);
    expect(result.scientificName, 'Bothrops jararaca');
  });
}
