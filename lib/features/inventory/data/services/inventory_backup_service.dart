import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/repositories/inventory_repository.dart';

/// Platform I/O for backing the inventory up to (and restoring it from) a
/// JSON file via the OS share sheet and file picker.
class InventoryBackupService {
  const InventoryBackupService(this._repository);

  final InventoryRepository _repository;

  /// Serializes the inventory and hands the JSON file to the share sheet.
  /// Returns the path of the shared file, or `null` if sharing was dismissed.
  Future<String?> exportToShareSheet() async {
    final json = await _repository.exportJson();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(p.join(dir.path, 'pocketsight_backup_$timestamp.json'));
    await file.writeAsString(json);

    final result = await SharePlus.instance.share(
      ShareParams(
        title: 'PocketSight backup',
        files: [XFile(file.path)],
        fileNameOverrides: [p.basename(file.path)],
      ),
    );
    return result.status == ShareResultStatus.success ? file.path : null;
  }

  /// Lets the user pick a JSON backup and merges it into the inventory.
  /// Returns the number of items imported (0 if cancelled or empty).
  Future<int> importFromFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;

    final picked = result.files.single;
    final content = picked.bytes != null
        ? utf8.decode(picked.bytes!)
        : await File(picked.path!).readAsString();
    await _repository.importJson(content);
    return (jsonDecode(content) as List<dynamic>).length;
  }
}
