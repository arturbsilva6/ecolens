import 'dart:typed_data';
import 'dart:ui' as ui;

/// Re-encodes decoded pixels, never uploading the original file or filename.
/// The engine's PNG encoder writes pixels, not input EXIF/XMP/GPS chunks.
class CommunityPhotoService {
  static const maxBytes = 4 * 1024 * 1024;
  static const maxInputBytes = 20 * 1024 * 1024;
  Future<Uint8List> sanitize(Uint8List input) async {
    if (input.isEmpty || input.length > maxInputBytes) {
      throw StateError('Escolha uma foto de até 20 MB.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(input);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 40000000) {
        throw StateError('Foto muito grande. Escolha uma imagem menor.');
      }
      final scale =
          1600 /
          (descriptor.width > descriptor.height
              ? descriptor.width
              : descriptor.height);
      codec = await descriptor.instantiateCodec(
        targetWidth: scale < 1 ? (descriptor.width * scale).round() : null,
        targetHeight: scale < 1 ? (descriptor.height * scale).round() : null,
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > maxBytes) {
        throw StateError(
          'Foto muito grande após processamento. Escolha outra.',
        );
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
