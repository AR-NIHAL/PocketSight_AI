import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../backup/data/services/backup_service.dart';
import '../../../ocr/data/services/mlkit_ocr_service.dart';
import '../../data/services/photo_storage_service.dart';
import '../../domain/entities/repair_ticket.dart';
import '../../domain/entities/shop_profile.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/repositories/ticket_repository.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  throw UnimplementedError('ticketRepositoryProvider must be initialized in main()');
});

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final repo = ref.watch(ticketRepositoryProvider);
  final photoService = ref.watch(photoStorageServiceProvider);
  return BackupService(
    ticketRepository: repo,
    photoStorageService: photoService,
  );
});

final mlkitOcrServiceProvider = Provider<MlKitOcrService>((ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ticketsStreamProvider = StreamProvider<List<RepairTicket>>((ref) {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.watchTickets();
});

class TicketSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final ticketSearchQueryProvider =
    NotifierProvider<TicketSearchQueryNotifier, String>(
        TicketSearchQueryNotifier.new);

class TicketStatusFilterNotifier extends Notifier<TicketStatus?> {
  @override
  TicketStatus? build() => null;

  void setFilter(TicketStatus? status) => state = status;
}

final ticketStatusFilterProvider =
    NotifierProvider<TicketStatusFilterNotifier, TicketStatus?>(
        TicketStatusFilterNotifier.new);

final filteredTicketsProvider = Provider<List<RepairTicket>>((ref) {
  final ticketsAsync = ref.watch(ticketsStreamProvider);
  final allTickets = ticketsAsync.value ?? [];

  final query = ref.watch(ticketSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(ticketStatusFilterProvider);

  return allTickets.where((ticket) {
    if (statusFilter != null && ticket.status != statusFilter) {
      return false;
    }

    if (query.isNotEmpty) {
      final matchesNumber =
          ticket.ticketNumber.toLowerCase().contains(query);
      final matchesCustomer =
          ticket.customer.name.toLowerCase().contains(query);
      final matchesPhone =
          ticket.customer.phone.toLowerCase().contains(query);
      final matchesSerial = (ticket.device.serialNumber ?? '')
          .toLowerCase()
          .contains(query);
      final matchesModel =
          ticket.device.displayName.toLowerCase().contains(query);

      return matchesNumber ||
          matchesCustomer ||
          matchesPhone ||
          matchesSerial ||
          matchesModel;
    }

    return true;
  }).toList();
});

class ShopProfileNotifier extends Notifier<ShopProfile> {
  @override
  ShopProfile build() {
    final repo = ref.watch(ticketRepositoryProvider);
    repo.getShopProfile().then((p) {
      state = p;
    });
    return const ShopProfile();
  }

  Future<void> updateProfile(ShopProfile newProfile) async {
    state = newProfile;
    final repo = ref.read(ticketRepositoryProvider);
    await repo.saveShopProfile(newProfile);
  }
}

final shopProfileProvider =
    NotifierProvider<ShopProfileNotifier, ShopProfile>(
        ShopProfileNotifier.new);
