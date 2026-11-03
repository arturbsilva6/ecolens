import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_identification_result.dart';
import 'supabase_service.dart';

/// Envia fotos para uma Edge Function autenticada, nunca para a API da IA
/// diretamente do celular. Nenhuma imagem é salva pelo cliente.
class AiService {
  final SupabaseClient? _client;
  final SupabaseService _supabaseService;

  AiService({this._client, SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  static const maxImageBytes = 4 * 1024 * 1024;

  static String validateImage(Uint8List bytes) {
    if (bytes.isEmpty || bytes.lengthInBytes > maxImageBytes) {
      throw const FormatException(
        'Selecione uma foto de até 4 MB para a análise.',
      );
    }

    if (bytes.lengthInBytes >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    if (bytes.lengthInBytes >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    throw const FormatException(
      'Formato não suportado. Selecione uma foto JPEG ou PNG.',
    );
  }

  /// O usuário precisa autorizar explicitamente o envio da foto na interface.
  /// Requer Supabase Auth e uma função identify-species implantada.
  Future<AiIdentificationResult> suggestSpecies(Uint8List imageBytes) async {
    final mimeType = validateImage(imageBytes);
    final client = _client ?? await _supabaseService.requireClient();

    // Login temporário somente após o consentimento explícito da foto.
    // Exige habilitar Anonymous Sign-Ins no painel Supabase Auth.
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
    if (client.auth.currentSession == null) {
      throw StateError('Não foi possível autenticar no EcoLens.');
    }

    final response = await client.functions.invoke(
      'identify-species',
      body: {
        'imageBase64': base64Encode(imageBytes),
        'mimeType': mimeType,
      },
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        'O serviço de análise não respondeu corretamente.',
      );
    }

    final Object? value = response.data;
    final Object? payload = value is String ? jsonDecode(value) : value;

    if (payload is! Map) {
      throw const FormatException('Resposta inesperada do serviço de IA.');
    }

    return AiIdentificationResult.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }
}
