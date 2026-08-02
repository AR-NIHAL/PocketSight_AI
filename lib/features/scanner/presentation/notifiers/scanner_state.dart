import 'package:camera/camera.dart';

import '../../domain/entities/detected_object.dart';
import '../../domain/entities/detection_image.dart';

/// Lifecycle + live detection state of the scanner.
sealed class ScannerState {
  const ScannerState();
}

/// Not yet started.
class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

/// Camera initializing.
class ScannerInitializing extends ScannerState {
  const ScannerInitializing();
}

/// Camera/ML pipeline failed to start.
class ScannerError extends ScannerState {
  const ScannerError(this.message);

  final String message;
}

/// Live camera running with the latest detections for the current frame.
class ScannerReady extends ScannerState {
  const ScannerReady({required this.controller, required this.detections});

  final CameraController controller;
  final List<DetectedObject> detections;
}

/// Live camera frozen on one tapped detection, awaiting a tag action.
///
/// [frame] is the raw frame the [selected] object was detected in, kept so a
/// thumbnail can be cropped from the exact pixels under the box.
class ScannerFocused extends ScannerState {
  const ScannerFocused({
    required this.controller,
    required this.frame,
    required this.detections,
    required this.selected,
  });

  final CameraController controller;
  final DetectionImage frame;
  final List<DetectedObject> detections;
  final DetectedObject selected;
}
