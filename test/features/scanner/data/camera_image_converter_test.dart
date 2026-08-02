import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/scanner/data/datasources/camera_image_converter.dart';

void main() {
  group('CameraImageConverter.toNv21', () {
    test('merges planes without padding', () {
      final y = List<int>.generate(16, (i) => i);
      final u = [100, 101, 102, 103];
      final v = [200, 201, 202, 203];

      final out = CameraImageConverter.toNv21(
        width: 4,
        height: 4,
        yPlane: y,
        yRowStride: 4,
        uPlane: u,
        vPlane: v,
        uvRowStride: 2,
        uvPixelStride: 1,
      );

      expect(
        out,
        Uint8List.fromList([
          ...y,
          200, 100, 201, 101,
          202, 102, 203, 103,
        ]),
      );
      expect(out.length, 24);
    });

    test('strips Y row-stride padding and honors chroma pixel stride', () {
      final yWithPadding = <int>[
        0, 1, 2, 3, 99, 99,
        4, 5, 6, 7, 99, 99,
        8, 9, 10, 11, 99, 99,
        12, 13, 14, 15, 99, 99,
      ];
      final uWithStride = [100, 0, 101, 0, 102, 0, 103, 0];
      final vWithStride = [200, 0, 201, 0, 202, 0, 203, 0];

      final out = CameraImageConverter.toNv21(
        width: 4,
        height: 4,
        yPlane: yWithPadding,
        yRowStride: 6,
        uPlane: uWithStride,
        vPlane: vWithStride,
        uvRowStride: 4,
        uvPixelStride: 2,
      );

      expect(
        out,
        Uint8List.fromList([
          0, 1, 2, 3,
          4, 5, 6, 7,
          8, 9, 10, 11,
          12, 13, 14, 15,
          200, 100, 201, 101,
          202, 102, 203, 103,
        ]),
      );
    });
  });
}
