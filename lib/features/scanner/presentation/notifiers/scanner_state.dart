import 'package:camera/camera.dart';

import '../../domain/entities/detected_object.dart';

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
