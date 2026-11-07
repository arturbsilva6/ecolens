import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Explica o uso da câmera antes da primeira foto.
///
/// O EcoLens não pede a permissão de câmera do Android: a foto é tirada pelo
/// app de câmera do aparelho. Este aviso aparece uma vez e diz o que acontece
/// com a imagem.
class CameraNotice {
  static const storageKey = 'ecolens_camera_notice_seen_v1';

  final SharedPreferencesAsync? preferences;

  const CameraNotice({this.preferences});

  /// Retorna `true` quando a câmera pode ser aberta.
  Future<bool> confirm(BuildContext context) async {
    final SharedPreferencesAsync store;
    try {
      store = preferences ?? SharedPreferencesAsync();
      if (await store.getBool(storageKey) == true) return true;
    } catch (_) {
      // Sem armazenamento local, não bloqueia a câmera.
      return true;
    }
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.photo_camera_outlined),
        title: const Text('Usar a câmera'),
        content: const Text(
          'O EcoLens vai abrir o app de câmera do seu aparelho. A foto fica só '
          'no celular até você decidir analisar com IA ou compartilhar um '
          'avistamento. Fotografe de longe e não se aproxime de animais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    try {
      await store.setBool(storageKey, true);
    } catch (_) {
      // O aviso volta a aparecer na próxima vez; a câmera abre mesmo assim.
    }
    return true;
  }
}
