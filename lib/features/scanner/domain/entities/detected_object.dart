import 'package:freezed_annotation/freezed_annotation.dart';

import 'normalized_rect.dart';

part 'detected_object.freezed.dart';

/// A single object detected within a frame.
@freezed
abstract class DetectedObject with _$DetectedObject {
  const factory DetectedObject({
    required String id,
    required String label,
    required double confidence,
    required NormalizedRect boundingBox,
    int? trackingId,
  }) = _DetectedObject;

  const DetectedObject._();
}
