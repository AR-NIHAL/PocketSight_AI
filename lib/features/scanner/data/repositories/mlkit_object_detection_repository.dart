import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as ml;
import 'package:uuid/uuid.dart';

import '../../domain/entities/detected_object.dart';
import '../../domain/entities/detection_image.dart';
import '../../domain/entities/detection_image_format.dart';
import '../../domain/entities/normalized_rect.dart';
import '../../domain/repositories/object_detection_repository.dart';

/// [ObjectDetectionRepository] backed by Google ML Kit's bundled on-device
/// object detector with category classification enabled.
class MlKitObjectDetectionRepository implements ObjectDetectionRepository {
  MlKitObjectDetectionRepository({
    this.confidenceThreshold = 0.5,
    ml.ObjectDetector? detector,
  }) : _detector =
           detector ??
           ml.ObjectDetector(
             options: ml.ObjectDetectorOptions(
               mode: ml.DetectionMode.stream,
               classifyObjects: true,
               multipleObjects: true,
             ),
           );

  final ml.ObjectDetector _detector;
  final double confidenceThreshold;
  static const _uuid = Uuid();

  @override
  Future<List<DetectedObject>> detect(DetectionImage input) async {
    final results = await _detector.processImage(_toInputImage(input));
    return results
        .where((object) => _confidenceOf(object) >= confidenceThreshold)
        .map((object) => _toDomain(object, input))
        .toList();
  }

  @override
  Future<void> dispose() => _detector.close();

  double _confidenceOf(ml.DetectedObject object) {
    if (object.labels.isEmpty) return 0;
    return object.labels
        .map((label) => label.confidence)
        .reduce(math.max);
  }

  DetectedObject _toDomain(ml.DetectedObject object, DetectionImage input) {
    final topLabel = object.labels.isEmpty
        ? null
        : object.labels.reduce(
            (a, b) => a.confidence >= b.confidence ? a : b,
          );
    return DetectedObject(
      id: _uuid.v4(),
      label: topLabel?.text ?? 'object',
      confidence: topLabel?.confidence ?? _confidenceOf(object),
      boundingBox: _normalizeRect(object.boundingBox, input),
      trackingId: object.trackingId,
    );
  }

  NormalizedRect _normalizeRect(Rect rect, DetectionImage input) {
    final rotated =
        input.rotationDegrees == 90 || input.rotationDegrees == 270;
    final width = rotated ? input.height : input.width;
    final height = rotated ? input.width : input.height;
    return NormalizedRect(
      left: (rect.left / width).clamp(0.0, 1.0),
      top: (rect.top / height).clamp(0.0, 1.0),
      right: (rect.right / width).clamp(0.0, 1.0),
      bottom: (rect.bottom / height).clamp(0.0, 1.0),
    );
  }

  InputImage _toInputImage(DetectionImage input) {
    final format = switch (input.format) {
      DetectionImageFormat.yuv420 => InputImageFormat.yuv_420_888,
      DetectionImageFormat.nv21 => InputImageFormat.nv21,
      DetectionImageFormat.bgra8888 => InputImageFormat.bgra8888,
      _ => throw UnsupportedError(
          'Unsupported detection image format: ${input.format}',
        ),
    };
    final rotation = InputImageRotation.values.firstWhere(
      (r) => r.rawValue == input.rotationDegrees,
      orElse: () => InputImageRotation.rotation0deg,
    );
    return InputImage.fromBytes(
      bytes: input.bytes,
      metadata: InputImageMetadata(
        size: Size(input.width.toDouble(), input.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: input.bytesPerRow ?? input.width,
      ),
    );
  }
}
