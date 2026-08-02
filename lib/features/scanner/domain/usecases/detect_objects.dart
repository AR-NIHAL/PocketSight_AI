import '../entities/detected_object.dart';
import '../entities/detection_image.dart';
import '../repositories/object_detection_repository.dart';

/// Runs on-device object detection on a single [DetectionImage].
class DetectObjects {
  const DetectObjects(this._repository);

  final ObjectDetectionRepository _repository;

  Future<List<DetectedObject>> call(DetectionImage image) =>
      _repository.detect(image);
}
