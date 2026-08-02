import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pocketsite_ai/features/scanner/data/datasources/thumbnail_cropper.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image_format.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/normalized_rect.dart';

DetectionImage _nv21Frame({
  int width = 4,
  int height = 4,
  int rotationDegrees = 0,
}) {
  final ySize = width * height;
  final buffer = Uint8List(ySize + (ySize ~/ 2));
  return DetectionImage(
    bytes: buffer,
    width: width,
    height: height,
    format: DetectionImageFormat.nv21,
    rotationDegrees: rotationDegrees,
  );
}

void main() {
  group('ThumbnailCropper.toUprightRgba', () {
    test('converts an NV21 frame to an upright RGBA image', () {
      final frame = _nv21Frame(width: 4, height: 4);
      // Full bright Y with neutral chroma -> white pixels.
      for (var i = 0; i < frame.width * frame.height; i++) {
        frame.bytes[i] = 255;
      }
      // Neutral chroma: U=128, V=128.
      final chromaStart = frame.width * frame.height;
      for (var i = chromaStart; i < frame.bytes.length; i += 2) {
        frame.bytes[i] = 128; // V
        frame.bytes[i + 1] = 128; // U
      }

      final image = ThumbnailCropper.toUprightRgba(frame);

      expect(image.width, 4);
      expect(image.height, 4);
      final pixel = image.getPixel(0, 0);
      expect(pixel.r, greaterThan(250));
      expect(pixel.g, greaterThan(250));
      expect(pixel.b, greaterThan(250));
    });

    test('bakes the rotation so pixels match upright coordinates', () {
      final frame = _nv21Frame(width: 4, height: 2, rotationDegrees: 90);
      for (var i = 0; i < frame.width * frame.height; i++) {
        frame.bytes[i] = 255;
      }
      final chromaStart = frame.width * frame.height;
      for (var i = chromaStart; i < frame.bytes.length; i += 2) {
        frame.bytes[i] = 128;
        frame.bytes[i + 1] = 128;
      }

      final image = ThumbnailCropper.toUprightRgba(frame);

      // 90-degree rotation swaps the dimensions.
      expect(image.width, 2);
      expect(image.height, 4);
    });

    test('throws for unsupported formats', () {
      final frame = DetectionImage(
        bytes: Uint8List(0),
        width: 4,
        height: 4,
        format: DetectionImageFormat.jpeg,
      );

      expect(
        () => ThumbnailCropper.toUprightRgba(frame),
        throwsUnsupportedError,
      );
    });
  });

  group('ThumbnailCropper.cropSquare', () {
    test('crops the region behind the box', () {
      final image = img.Image(width: 100, height: 100, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));

      final cropped = ThumbnailCropper.cropSquare(
        image,
        const NormalizedRect(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75),
      );

      expect(cropped.width, lessThanOrEqualTo(
        ThumbnailCropper.maxThumbnailSize,
      ));
      expect(cropped.height, lessThanOrEqualTo(
        ThumbnailCropper.maxThumbnailSize,
      ));
      for (final pixel in cropped) {
        expect(pixel.r, greaterThan(250));
        expect(pixel.g, lessThan(10));
        expect(pixel.b, lessThan(10));
      }
    });

    test('crops from a non-square box preserving the source aspect ratio',
        () {
      final image = img.Image(width: 200, height: 100, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(0, 0, 255, 255));

      final cropped = ThumbnailCropper.cropSquare(
        image,
        const NormalizedRect(left: 0, top: 0, right: 0.5, bottom: 1),
      );

      // Source region is 100x100; scaled to max size keeps it square.
      expect(cropped.width, ThumbnailCropper.maxThumbnailSize);
      expect(cropped.height, ThumbnailCropper.maxThumbnailSize);
    });
  });

  group('ThumbnailCropper.encodeJpeg', () {
    test('produces decodable JPEG bytes', () {
      final image = img.Image(width: 8, height: 8, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(10, 200, 30, 255));

      final bytes = ThumbnailCropper.encodeJpeg(image);
      final decoded = img.decodeImage(bytes);

      expect(decoded, isNotNull);
      expect(decoded!.width, 8);
      expect(decoded.height, 8);
    });
  });
}
