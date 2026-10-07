import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pocketsite_ai/features/tickets/data/services/photo_storage_service.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/repair_ticket.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/shop_profile.dart';
import 'package:pocketsite_ai/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:share_plus/share_plus.dart';

class RestoreResult {
  final int ticketsCount;
  final int photosCount;
  final bool success;
  final String? errorMessage;

  const RestoreResult({
    required this.ticketsCount,
    required this.photosCount,
    this.success = true,
    this.errorMessage,
  });
}

class BackupService {
  final TicketRepository ticketRepository;
  final PhotoStorageService photoStorageService;

  BackupService({
    required this.ticketRepository,
    required this.photoStorageService,
  });

  /// Exports all tickets and photos into a single zip archive and triggers the system share sheet.
  Future<String> exportBackup() async {
    final tickets = await ticketRepository.getAllTickets();
    final profile = await ticketRepository.getShopProfile();

    final manifestData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'shopProfile': profile.toMap(),
      'tickets': tickets.map((t) => t.toMap()).toList(),
    };

    final archive = Archive();

    // 1. Add manifest JSON
    final jsonBytes = utf8.encode(jsonEncode(manifestData));
    archive.addFile(
        ArchiveFile('backup_data.json', jsonBytes.length, jsonBytes));

    // 2. Add photos
    final photosRoot = await photoStorageService.getPhotosRootDirectory();
    int photoCount = 0;
    if (photosRoot.existsSync()) {
      for (final entity in photosRoot.listSync(recursive: true)) {
        if (entity is File) {
          final relative = p.relative(entity.path, from: photosRoot.path);
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile('photos/$relative', bytes.length, bytes));
          photoCount++;
        }
      }
    }

    // 3. Compress to Zip
    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 12);
    final backupFileName = 'repair_backup_$timestamp.zip';
    final backupFile = File(p.join(tempDir.path, backupFileName));
    await backupFile.writeAsBytes(encodedZip);

    // 4. Share with user
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupFile.path)],
        subject: 'Repair Intake Assistant Backup ($timestamp - $photoCount photos)',
      ),
    );

    return backupFile.path;
  }

  /// Restores tickets and photos from a picked zip backup file.
  Future<RestoreResult> restoreBackup(String zipFilePath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!zipFile.existsSync()) {
        return const RestoreResult(
          ticketsCount: 0,
          photosCount: 0,
          success: false,
          errorMessage: 'Backup file not found.',
        );
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? manifestFile;
      final List<ArchiveFile> photoFiles = [];

      for (final file in archive) {
        if (file.name == 'backup_data.json') {
          manifestFile = file;
        } else if (file.name.startsWith('photos/')) {
          photoFiles.add(file);
        }
      }

      if (manifestFile == null) {
        return const RestoreResult(
          ticketsCount: 0,
          photosCount: 0,
          success: false,
          errorMessage: 'Invalid backup: missing backup_data.json.',
        );
      }

      // 1. Parse manifest
      final jsonString = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(jsonString) as Map<String, dynamic>;

      // 2. Restore shop profile
      if (manifest['shopProfile'] is Map) {
        final profile = ShopProfile.fromMap(
            manifest['shopProfile'] as Map<String, dynamic>);
        await ticketRepository.saveShopProfile(profile);
      }

      // 3. Restore photos
      final photosRoot = await photoStorageService.getPhotosRootDirectory();
      int restoredPhotosCount = 0;
      for (final pf in photoFiles) {
        final relativePath = pf.name.replaceFirst('photos/', '');
        final targetPath = p.join(photosRoot.path, relativePath);
        final targetFile = File(targetPath);
        targetFile.parent.createSync(recursive: true);
        await targetFile.writeAsBytes(pf.content as List<int>);
        restoredPhotosCount++;
      }

      // 4. Restore tickets
      int restoredTicketsCount = 0;
      final rawTickets = manifest['tickets'] as List? ?? [];
      for (final raw in rawTickets) {
        if (raw is Map) {
          final ticket =
              RepairTicket.fromMap(Map<String, dynamic>.from(raw));
          await ticketRepository.saveTicket(ticket);
          restoredTicketsCount++;
        }
      }

      return RestoreResult(
        ticketsCount: restoredTicketsCount,
        photosCount: restoredPhotosCount,
        success: true,
      );
    } catch (e) {
      return RestoreResult(
        ticketsCount: 0,
        photosCount: 0,
        success: false,
        errorMessage: 'Failed to restore backup: $e',
      );
    }
  }
}
