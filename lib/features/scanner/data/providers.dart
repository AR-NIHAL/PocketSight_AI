import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/object_detection_repository.dart';
import '../data/datasources/camera_datasource.dart';
import '../data/datasources/thumbnail_datasource.dart';
import '../data/repositories/mlkit_object_detection_repository.dart';

part 'providers.g.dart';

/// Shared camera datasource (kept alive for the app lifetime).
@Riverpod(keepAlive: true)
CameraDatasource cameraDatasource(Ref ref) => CameraDatasource();

/// Shared ML Kit object detection engine (created once, reused per frame).
@Riverpod(keepAlive: true)
ObjectDetectionRepository objectDetectionRepository(Ref ref) =>
    MlKitObjectDetectionRepository();

/// Crops and persists thumbnails for tapped detections.
@Riverpod(keepAlive: true)
ThumbnailDatasource thumbnailDatasource(Ref ref) => ThumbnailDatasource();
