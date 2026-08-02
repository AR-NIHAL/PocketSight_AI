import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/detection_image.dart';
import '../../domain/entities/normalized_rect.dart';
import 'thumbnail_cropper.dart';

/// Crops and persists a local JPEG thumbnail for a tapped detection.
class ThumbnailDatasource {
  const ThumbnailDatasource({Future<Directory> Function()? documentsDirectory})
      : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;
  static const _uuid = Uuid();

  /// Crops the [box] region out of [frame], writes a JPEG thumbnail to the
  /// app documents directory, and returns its absolute path.
  Future<String> cropAndSave({
    required DetectionImage frame,
    required NormalizedRect box,
  }) async {
    final upright = ThumbnailCropper.toUprightRgba(frame);
    final square = ThumbnailCropper.cropSquare(upright, box);
    final bytes = ThumbnailCropper.encodeJpeg(square);

    final documents = await _documentsDirectory();
    final thumbnailsDir = Directory(p.join(documents.path, 'thumbnails'));
    await thumbnailsDir.create(recursive: true);

    final file = File(p.join(thumbnailsDir.path, '${_uuid.v4()}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
