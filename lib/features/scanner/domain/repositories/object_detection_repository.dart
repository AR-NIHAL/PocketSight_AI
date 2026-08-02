import '../entities/detected_object.dart';
import '../entities/detection_image.dart';

/// Contract for the on-device object detection engine.
abstract interface class ObjectDetectionRepository {
  /// Runs detection on [input] and returns the detected objects
  /// (already filtered by the active confidence threshold).
  Future<List<DetectedObject>> detect(DetectionImage input);

  /// Releases underlying platform resources (e.g. the ML detector).
  Future<void> dispose();
}
