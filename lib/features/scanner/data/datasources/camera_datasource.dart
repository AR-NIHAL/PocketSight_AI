import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';

import '../../domain/entities/detection_image.dart';
import 'camera_image_converter.dart';

/// Owns the live camera controller and emits throttled [DetectionImage]
/// frames for the detection pipeline.
///
/// Frames arrive from the platform at the camera's native rate and are
/// dropped down to [targetFps] before being emitted downstream, keeping the
/// pipeline at a steady 10-15 FPS.
class CameraDatasource {
  CameraController? _controller;
  StreamController<DetectionImage>? _frames;
  final Stopwatch _throttle = Stopwatch()..start();
  Duration _frameInterval = const Duration(milliseconds: 83);
  int _rotationDegrees = 0;

  /// The underlying camera controller (null until initialized).
  CameraController? get controller => _controller;

  /// Throttled stream of camera frames as [DetectionImage]s.
  Stream<DetectionImage> get frames => _frames?.stream ?? const Stream.empty();

  Future<void> initialize({required int targetFps}) async {
    if (_controller?.value.isInitialized ?? false) return;

    final cameras = await availableCameras();
    final description = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();

    _frameInterval = Duration(milliseconds: (1000 / targetFps).round());
    _rotationDegrees = _computeRotation(description.sensorOrientation);

    _frames = StreamController<DetectionImage>.broadcast();
    await controller.startImageStream(_onFrame);
  }

  int _computeRotation(int sensorOrientation) {
    if (Platform.isIOS) return 0;
    return sensorOrientation;
  }

  /// Updates the frame throttle interval live, so an FPS mode change takes
  /// effect without re-initializing the camera stream.
  void setTargetFps(int targetFps) {
    _frameInterval = Duration(milliseconds: (1000 / targetFps).round());
  }

  void _onFrame(CameraImage image) {
    if (_throttle.elapsed < _frameInterval) return;
    _throttle.reset();

    final detectionImage =
        CameraImageConverter.toDetectionImage(image, _rotationDegrees);
    _frames?.add(detectionImage);
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.stopImageStream();
    await controller?.dispose();
    await _frames?.close();
    _frames = null;
  }
}
