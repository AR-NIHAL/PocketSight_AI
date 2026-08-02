import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'detection_image_format.dart';

part 'detection_image.freezed.dart';

/// An opaque single frame to be passed to the object detection engine.
///
/// Kept free of platform types (camera frames, ML Kit `InputImage`) so the
/// domain stays pure Dart; data sources map to/from it.
@freezed
abstract class DetectionImage with _$DetectionImage {
  const factory DetectionImage({
    required Uint8List bytes,
    required int width,
    required int height,
    @Default(DetectionImageFormat.yuv420) DetectionImageFormat format,
  }) = _DetectionImage;

  const DetectionImage._();
}
