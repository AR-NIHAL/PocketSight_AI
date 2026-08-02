import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../../domain/entities/detection_image.dart';
import '../../domain/entities/detection_image_format.dart';

/// Converts raw [CameraImage] frames into domain [DetectionImage] values
/// that the ML pipeline can consume.
abstract final class CameraImageConverter {
  /// Maps a [CameraImage] to a [DetectionImage].
  ///
  /// Android `yuv420` frames are converted to NV21 (single buffer, reliably
  /// accepted by ML Kit); iOS `bgra8888` frames are passed through as-is.
  static DetectionImage toDetectionImage(CameraImage image, int rotationDegrees) {
    final format = _mapFormat(image.format.group);
    final bytes = switch (format) {
      DetectionImageFormat.bgra8888 => image.planes.first.bytes,
      _ => _toNv21(image),
    };
    return DetectionImage(
      bytes: bytes,
      width: image.width,
      height: image.height,
      format: format,
      rotationDegrees: rotationDegrees,
      bytesPerRow: format == DetectionImageFormat.bgra8888
          ? image.planes.first.bytesPerRow
          : image.width,
    );
  }

  static DetectionImageFormat _mapFormat(ImageFormatGroup group) {
    return switch (group) {
      ImageFormatGroup.yuv420 => DetectionImageFormat.yuv420,
      ImageFormatGroup.nv21 => DetectionImageFormat.nv21,
      ImageFormatGroup.jpeg => DetectionImageFormat.jpeg,
      ImageFormatGroup.bgra8888 => DetectionImageFormat.bgra8888,
      _ => DetectionImageFormat.rgba8888,
    };
  }

  /// Merges the three planar YUV_420_888 buffers into a single NV21 buffer
  /// (full-size Y plane followed by interleaved VU chroma), handling row-stride
  /// padding and chroma pixel strides.
  static Uint8List toNv21({
    required int width,
    required int height,
    required List<int> yPlane,
    required int yRowStride,
    required List<int> uPlane,
    required List<int> vPlane,
    required int uvRowStride,
    required int uvPixelStride,
  }) {
    final ySize = width * height;
    final out = Uint8List(ySize + ySize ~/ 2);

    for (var row = 0; row < height; row++) {
      out.setRange(
        row * width,
        (row + 1) * width,
        yPlane,
        row * yRowStride,
      );
    }

    var outOffset = ySize;
    for (var row = 0; row < height ~/ 2; row++) {
      var inOffset = row * uvRowStride;
      for (var col = 0; col < width ~/ 2; col++) {
        out[outOffset++] = vPlane[inOffset];
        out[outOffset++] = uPlane[inOffset];
        inOffset += uvPixelStride;
      }
    }

    return out;
  }

  static Uint8List _toNv21(CameraImage image) {
    return toNv21(
      width: image.width,
      height: image.height,
      yPlane: image.planes[0].bytes,
      yRowStride: image.planes[0].bytesPerRow,
      uPlane: image.planes[1].bytes,
      vPlane: image.planes[2].bytes,
      uvRowStride: image.planes[1].bytesPerRow,
      uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
    );
  }
}
