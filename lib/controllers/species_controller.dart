
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/camera_service.dart';

class SpeciesController extends ChangeNotifier {
  final CameraService _cameraService;

  SpeciesController({CameraService? cameraService})
      : _cameraService = cameraService ?? CameraService();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // Informações disponíveis para a interface
  Uint8List? get imageBytes => _imageBytes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Captura uma fotografia
  Future<void> takePhoto() async {
    await _selectImage(fromCamera: true);
  }

  // Seleciona uma fotografia da galeria
  Future<void> pickFromGallery() async {
    await _selectImage(fromCamera: false);
  }

  Future<void> _selectImage({
    required bool fromCamera,
  }) async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final image = fromCamera
          ? await _cameraService.takePhoto()
          : await _cameraService.pickFromGallery();

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (!_disposed) {
          _imageBytes = bytes;
        }
      }
    } catch (_) {
      if (!_disposed) {
        _errorMessage =
            'Não foi possível carregar a imagem. Tente novamente.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Remove a imagem selecionada
  void clearImage() {
    if (_disposed || _isLoading) return;

    _imageBytes = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
