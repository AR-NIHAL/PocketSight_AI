import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/inventory/domain/entities/inspection_item.dart';
import '../../../../features/inventory/domain/entities/inspection_schedule.dart';
import '../../../../features/inventory/data/providers.dart' show inventoryRepositoryProvider;
import '../../../../features/settings/domain/entities/fps_mode.dart';
import '../../domain/entities/detected_object.dart';
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
  DetectionImage? _lastFrame;
  bool _disposed = false;
  static const _uuid = Uuid();

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
      _subscribe();
    } catch (error) {
      if (!_disposed) {
        state = ScannerError(error.toString());
      }
    }
  }

  void _subscribe() {
    final datasource = _datasource;
    if (datasource == null) return;
    _subscription?.cancel();
    _subscription = datasource.frames.listen(_onFrame);
  }

  Future<void> _onFrame(DetectionImage frame) async {
    final repository = _repository;
    final current = state;
    if (repository == null || current is! ScannerReady) return;
    try {
      final detections = await repository.detect(frame);
      _lastFrame = frame;
      if (_disposed || state != current) return;
      state = ScannerReady(
        controller: current.controller,
        detections: detections,
      );
    } catch (_) {
      // Drop the frame; keep the previous detections on screen.
    }
  }

  /// Freezes the current frame on [selected] so the user can tag it.
  void select(DetectedObject selected) {
    final current = state;
    final frame = _lastFrame;
    if (current is! ScannerReady || frame == null) return;

    _subscription?.cancel();
    state = ScannerFocused(
      controller: current.controller,
      frame: frame,
      detections: current.detections,
      selected: selected,
    );
  }

  /// Dismisses the frozen selection and resumes live scanning.
  void dismissSelection() {
    final current = state;
    if (current is! ScannerFocused) return;
    _subscribe();
    state = ScannerReady(
      controller: current.controller,
      detections: const [],
    );
  }

  /// Crops a thumbnail from the frozen frame and persists a new
  /// [InspectionItem] for the selected detection.
  Future<InspectionItem?> saveSelected({
    required String title,
    String category = 'Uncategorized',
    String markdownNotes = '',
    InspectionSchedule? schedule,
  }) async {
    final current = state;
    if (current is! ScannerFocused) return null;

    try {
      final cropper = ref.read(thumbnailDatasourceProvider);
      final thumbnailPath = await cropper.cropAndSave(
        frame: current.frame,
        box: current.selected.boundingBox,
      );

      final now = DateTime.now();
      final item = InspectionItem(
        id: _uuid.v4(),
        title: title,
        category: category,
        markdownNotes: markdownNotes,
        thumbnailPath: thumbnailPath,
        detectionLabel: current.selected.label,
        detectionConfidence: current.selected.confidence,
        schedule: schedule,
        createdAt: now,
        updatedAt: now,
      );

      final repository = ref.read(inventoryRepositoryProvider);
      await repository.saveItem(item);

      if (_disposed) return item;
      dismissSelection();
      return item;
    } catch (_) {
      return null;
    }
  }
}
