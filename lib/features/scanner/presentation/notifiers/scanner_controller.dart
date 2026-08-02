import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/settings/domain/entities/fps_mode.dart';
import '../../domain/entities/detection_image.dart';
import '../../domain/repositories/object_detection_repository.dart';
import '../../data/datasources/camera_datasource.dart';
import '../../data/providers.dart';
import 'scanner_state.dart';

part 'scanner_controller.g.dart';

@riverpod
class ScannerController extends _$ScannerController {
  CameraDatasource? _datasource;
  ObjectDetectionRepository? _repository;
  StreamSubscription<DetectionImage>? _subscription;
  bool _disposed = false;

  @override
  ScannerState build() {
    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
      _datasource?.dispose();
      _repository?.dispose();
    });
    return const ScannerIdle();
  }

  Future<void> start() async {
    state = const ScannerInitializing();
    try {
      final datasource = ref.read(cameraDatasourceProvider);
      await datasource.initialize(targetFps: FpsMode.balanced.targetFps);
      _datasource = datasource;

      final repository = ref.read(objectDetectionRepositoryProvider);
      _repository = repository;

      state = ScannerReady(
        controller: datasource.controller!,
        detections: const [],
      );
      _subscription = datasource.frames.listen(_onFrame);
    } catch (error) {
      if (!_disposed) {
        state = ScannerError(error.toString());
      }
    }
  }

  Future<void> _onFrame(DetectionImage frame) async {
    final repository = _repository;
    final current = state;
    if (repository == null || current is! ScannerReady) return;
    try {
      final detections = await repository.detect(frame);
      if (_disposed || state != current) return;
      state = ScannerReady(
        controller: current.controller,
        detections: detections,
      );
    } catch (_) {
      // Drop the frame; keep the previous detections on screen.
    }
  }
}
