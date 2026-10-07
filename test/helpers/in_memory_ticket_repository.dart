import 'dart:async';
import 'package:pocketsite_ai/features/tickets/domain/entities/delivery_record.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/repair_ticket.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/shop_profile.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/ticket_status.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/work_log_entry.dart';
import 'package:pocketsite_ai/features/tickets/domain/repositories/ticket_repository.dart';

class InMemoryTicketRepository implements TicketRepository {
  final Map<String, RepairTicket> _tickets = {};
  ShopProfile _profile = const ShopProfile();

  final StreamController<List<RepairTicket>> _streamController =
      StreamController<List<RepairTicket>>.broadcast();

  @override
  Future<void> init() async {}

  void _notify() {
    if (_streamController.hasListener) {
      _streamController.add(getAllTicketsSync());
    }
  }

  List<RepairTicket> getAllTicketsSync() {
    final list = _tickets.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<RepairTicket>> getAllTickets() async => getAllTicketsSync();

  @override
  Future<RepairTicket?> getTicketById(String id) async => _tickets[id];

  @override
  Future<List<RepairTicket>> getTicketsByDeviceSerial(String serial) async {
    final clean = serial.trim().toUpperCase();
    return _tickets.values.where((t) {
      final s = t.device.serialNumber?.trim().toUpperCase();
      return s != null && s.isNotEmpty && s == clean;
    }).toList();
  }

  @override
  Future<void> saveTicket(RepairTicket ticket) async {
    _tickets[ticket.id] = ticket;
    _notify();
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    required String workNote,
    String? technicianName,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final updated = ticket.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      workLogs: [
        ...ticket.workLogs,
        WorkLogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          note: workNote,
          statusChange: newStatus,
          technicianName: technicianName,
        ),
      ],
    );
    _tickets[ticketId] = updated;
    _notify();
  }

  @override
  Future<void> completeHandover({
    required String ticketId,
    required DeliveryRecord deliveryRecord,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final updated = ticket.copyWith(
      status: deliveryRecord.isRepaired
          ? TicketStatus.delivered
          : TicketStatus.closedWithoutRepair,
      updatedAt: DateTime.now(),
      deliveryRecord: deliveryRecord,
    );
    _tickets[ticketId] = updated;
    _notify();
  }

  @override
  Future<void> deleteTicket(String id) async {
    _tickets.remove(id);
    _notify();
  }

  @override
  Future<int> getNextSequenceNumber() async => _tickets.length + 1;

  @override
  Future<ShopProfile> getShopProfile() async => _profile;

  @override
  Future<void> saveShopProfile(ShopProfile profile) async {
    _profile = profile;
  }

  @override
  Stream<List<RepairTicket>> watchTickets() async* {
    yield getAllTicketsSync();
    yield* _streamController.stream;
  }
}
