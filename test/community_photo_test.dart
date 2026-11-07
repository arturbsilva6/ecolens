import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecolens/services/community_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    're-encoding strips ancillary PNG metadata including location text',
    () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
          .drawColor(const ui.Color(0xff123456), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      image.dispose();
      picture.dispose();
      // A PNG tEXt chunk carrying GPS, with valid CRC32.
      final payload = Uint8List.fromList(
        'tEXtGPS\u0000-23.5226,-47.1357'.codeUnits,
      );
      int crc = 0xffffffff;
      for (final b in payload) {
        crc ^= b;
        for (int n = 0; n < 8; n++) {
          crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
        }
      }
      final chunk = BytesBuilder()
        ..add(
          (ByteData(4)..setUint32(0, payload.length - 4)).buffer.asUint8List(),
        )
        ..add(payload)
        ..add(
          (ByteData(4)..setUint32(0, crc ^ 0xffffffff)).buffer.asUint8List(),
        );
      final input = Uint8List.fromList([
        ...bytes.sublist(0, 33),
        ...chunk.toBytes(),
        ...bytes.sublist(33),
      ]);
      expect(String.fromCharCodes(input), contains('GPS'));
      final output = await CommunityPhotoService().sanitize(input);
      expect(String.fromCharCodes(output), isNot(contains('GPS')));
      expect(String.fromCharCodes(output), isNot(contains('-23.5226')));
      final codec = await ui.instantiateImageCodec(output);
      final decoded = (await codec.getNextFrame()).image;
      expect(decoded.width, 2);
      decoded.dispose();
      codec.dispose();
    },
  );
  test('JPEG EXIF GPS is discarded when pixels are encoded as PNG', () async {
    final original = await File('assets/images/jararaca.jpg').readAsBytes();
    // Valid little-endian TIFF: IFD0 points at a GPS IFD containing latitude.
    final tiff = ByteData(92);
    tiff.setUint16(0, 0x4949);
    tiff.setUint16(2, 42, Endian.little);
    tiff.setUint32(4, 8, Endian.little);
    tiff.setUint16(8, 1, Endian.little);
    tiff.setUint16(10, 0x8825, Endian.little);
    tiff.setUint16(12, 4, Endian.little);
    tiff.setUint32(14, 1, Endian.little);
    tiff.setUint32(18, 26, Endian.little);
    tiff.setUint16(26, 3, Endian.little);
    for (final entry in [
      (28, 0, 1, 4, 0x302),
      (40, 1, 2, 2, 83),
      (52, 2, 5, 3, 68),
    ]) {
      tiff.setUint16(entry.$1, entry.$2, Endian.little);
      tiff.setUint16(entry.$1 + 2, entry.$3, Endian.little);
      tiff.setUint32(entry.$1 + 4, entry.$4, Endian.little);
      tiff.setUint32(entry.$1 + 8, entry.$5, Endian.little);
    }
    for (final entry in [(68, 23, 1), (76, 31, 1), (84, 1356, 100)]) {
      tiff.setUint32(entry.$1, entry.$2, Endian.little);
      tiff.setUint32(entry.$1 + 4, entry.$3, Endian.little);
    }
    final exif = [...'Exif'.codeUnits, 0, 0, ...tiff.buffer.asUint8List()];
    final length = exif.length + 2;
    final input = Uint8List.fromList([
      0xff,
      0xd8,
      0xff,
      0xe1,
      length >> 8,
      length & 255,
      ...exif,
      ...original.sublist(2),
    ]);
    expect(String.fromCharCodes(input), contains('Exif'));
    final output = await CommunityPhotoService().sanitize(input);
    expect(output.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(String.fromCharCodes(output), isNot(contains('Exif')));
    expect(String.fromCharCodes(output), isNot(contains('eXIf')));
  });
  test('rejects invalid and excessive input without upload', () async {
    final service = CommunityPhotoService();
    await expectLater(service.sanitize(Uint8List(0)), throwsStateError);
    await expectLater(
      service.sanitize(Uint8List(21 * 1024 * 1024)),
      throwsStateError,
    );
    await expectLater(
      service.sanitize(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
}
