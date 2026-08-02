import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/detection_image.dart';
import '../../domain/entities/detection_image_format.dart';
import '../../domain/entities/normalized_rect.dart';

/// Pure pixel transformations: converts a raw [DetectionImage] into an RGB
/// [img.Image], rotates it upright, and crops the region behind a
/// [NormalizedRect] to a square thumbnail.
abstract final class ThumbnailCropper {
  /// Max thumbnail edge length (pixels).
  static const int maxThumbnailSize = 160;

  /// Converts [frame] bytes to an upright RGB [img.Image].
  ///
  /// The frame is stored in sensor orientation; [DetectionImage.rotationDegrees]
  /// is the rotation ML Kit applied, so we bake the same rotation to make the
  /// pixels match the normalized detection coordinates.
  static img.Image toUprightRgba(DetectionImage frame) {
    final rgba = switch (frame.format) {
      DetectionImageFormat.nv21 || DetectionImageFormat.yuv420 =>
        _fromNv21(frame),
      DetectionImageFormat.bgra8888 => _fromBgra(frame),
      _ => throw UnsupportedError(
          'Thumbnail cropping unsupported for format ${frame.format}',
        ),
    };
    return img.copyRotate(rgba, angle: frame.rotationDegrees);
  }

  /// Crops [box] from the upright [image] and scales the result down to a
  /// [maxThumbnailSize]-edge square (letterboxed to preserve aspect ratio).
  static img.Image cropSquare(img.Image image, NormalizedRect box) {
    final width = (box.right - box.left) * image.width;
    final height = (box.bottom - box.top) * image.height;
    final x = box.left * image.width;
    final y = box.top * image.height;

    final cropped = img.copyCrop(
      image,
      x: x.round().clamp(0, image.width - 1),
      y: y.round().clamp(0, image.height - 1),
      width: width.ceil().clamp(1, image.width),
      height: height.ceil().clamp(1, image.height),
    );

    final scale = maxThumbnailSize / (cropped.width > cropped.height
        ? cropped.width
        : cropped.height);
    final targetWidth = (cropped.width * scale).round();
    final targetHeight = (cropped.height * scale).round();
    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Encodes [image] as JPEG bytes.
  static Uint8List encodeJpeg(img.Image image) =>
      Uint8List.fromList(img.encodeJpg(image, quality: 85));

  /// NV21 (single buffer: Y plane then interleaved VU) to RGBA.
  static img.Image _fromNv21(DetectionImage frame) {
    final bytes = frame.bytes;
    final width = frame.width;
    final height = frame.height;
    final image = img.Image(width: width, height: height, numChannels: 4);
    final ySize = width * height;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = ySize + ((y ~/ 2) * (width ~/ 2) + (x ~/ 2)) * 2;
        final yValue = bytes[yIndex];
        final v = bytes[uvIndex];
        final u = bytes[uvIndex + 1];

        // ITU-R BT.601 YUV -> RGB.
        final c = yValue - 16;
        final d = u - 128;
        final e = v - 128;
        int r = (298 * c + 409 * e + 128) >> 8;
        int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
        int b = (298 * c + 516 * d + 128) >> 8;

        image.setPixelRgba(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
          255,
        );
      }
    }
    return image;
  }

  /// BGRA 8-bit-per-channel (iOS) to RGBA.
  static img.Image _fromBgra(DetectionImage frame) {
    final rowStride = frame.bytesPerRow ?? frame.width * 4;
    final image = img.Image(
      width: frame.width,
      height: frame.height,
      numChannels: 4,
    );
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final i = y * rowStride + x * 4;
        final b = frame.bytes[i];
        final g = frame.bytes[i + 1];
        final r = frame.bytes[i + 2];
        final a = frame.bytes[i + 3];
        image.setPixelRgba(x, y, r, g, b, a);
      }
    }
    return image;
  }
}
