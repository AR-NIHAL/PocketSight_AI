import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  Future<String> savePhoto({
    required String ticketId,
    required String sourcePath,
    String? customPrefix,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final ticketPhotoDir =
        Directory(p.join(appDir.path, 'repair_photos', ticketId));
    if (!ticketPhotoDir.existsSync()) {
      ticketPhotoDir.createSync(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final prefix = customPrefix != null ? '${customPrefix}_' : '';
    final filename =
        '$prefix${DateTime.now().millisecondsSinceEpoch}$ext';
    final destination = p.join(ticketPhotoDir.path, filename);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destination);
    return destination;
  }

  Future<void> deleteTicketPhotos(String ticketId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ticketPhotoDir =
          Directory(p.join(appDir.path, 'repair_photos', ticketId));
      if (ticketPhotoDir.existsSync()) {
        ticketPhotoDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  Future<Directory> getPhotosRootDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'repair_photos'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
