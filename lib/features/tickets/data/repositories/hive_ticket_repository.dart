import 'dart:async';
import 'package:hive_ce/hive.dart';
import '../../domain/entities/delivery_record.dart';
import '../../domain/entities/repair_ticket.dart';
import '../../domain/entities/shop_profile.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/entities/work_log_entry.dart';
import '../../domain/repositories/ticket_repository.dart';

class HiveTicketRepository implements TicketRepository {
  static const String ticketBoxName = 'repair_tickets';
  static const String profileBoxName = 'repair_shop_profile';

  Box? _ticketBox;
  Box? _profileBox;

  final StreamController<List<RepairTicket>> _streamController =
      StreamController<List<RepairTicket>>.broadcast();

  @override
  Future<void> init() async {
    _ticketBox = await Hive.openBox(ticketBoxName);
    _profileBox = await Hive.openBox(profileBoxName);
    _notify();
  }

  void _notify() {
    if (_streamController.hasListener) {
      _streamController.add(_allTicketsList());
    }
  }

  List<RepairTicket> _allTicketsList() {
    if (_ticketBox == null) return [];
    final List<RepairTicket> list = [];
    for (final key in _ticketBox!.keys) {
      final data = _ticketBox!.get(key);
      if (data is Map) {
        try {
          final stringMap = Map<String, dynamic>.from(data);
          list.add(RepairTicket.fromMap(stringMap));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<RepairTicket>> getAllTickets() async {
    return _allTicketsList();
  }

  @override
  Future<RepairTicket?> getTicketById(String id) async {
    final data = _ticketBox?.get(id);
    if (data is Map) {
      return RepairTicket.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  @override
  Future<List<RepairTicket>> getTicketsByDeviceSerial(String serial) async {
    final cleanSerial = serial.trim().toUpperCase();
    if (cleanSerial.isEmpty) return [];

    return _allTicketsList().where((t) {
      final s = t.device.serialNumber?.trim().toUpperCase();
      return s != null && s.isNotEmpty && s == cleanSerial;
    }).toList();
  }

  @override
  Future<void> saveTicket(RepairTicket ticket) async {
    await _ticketBox?.put(ticket.id, ticket.toMap());
    _notify();
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    required String workNote,
    String? technicianName,
  }) async {
    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;

    final updatedLogs = List<WorkLogEntry>.from(ticket.workLogs)
      ..add(WorkLogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        note: workNote,
        statusChange: newStatus,
        technicianName: technicianName,
      ));

    final updatedTicket = ticket.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      workLogs: updatedLogs,
    );

    await saveTicket(updatedTicket);
  }

  @override
  Future<void> completeHandover({
    required String ticketId,
    required DeliveryRecord deliveryRecord,
  }) async {
    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;

    final targetStatus = deliveryRecord.isRepaired
        ? TicketStatus.delivered
        : TicketStatus.closedWithoutRepair;

    final updatedLogs = List<WorkLogEntry>.from(ticket.workLogs)
      ..add(WorkLogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: deliveryRecord.deliveredAt,
        note: deliveryRecord.isRepaired
            ? 'Handover completed to ${deliveryRecord.receiverName}. Returned accessories verified: ${deliveryRecord.returnedAccessories.join(", ")}.'
            : 'Device returned without repair: ${deliveryRecord.unrepairedReason ?? "Customer requested return"}.',
        statusChange: targetStatus,
      ));

    final updatedTicket = ticket.copyWith(
      status: targetStatus,
      updatedAt: DateTime.now(),
      deliveryRecord: deliveryRecord,
      workLogs: updatedLogs,
    );

    await saveTicket(updatedTicket);
  }

  @override
  Future<void> deleteTicket(String id) async {
    await _ticketBox?.delete(id);
    _notify();
  }

  @override
  Future<int> getNextSequenceNumber() async {
    final tickets = _allTicketsList();
    return tickets.length + 1;
  }

  @override
  Future<ShopProfile> getShopProfile() async {
    final data = _profileBox?.get('profile');
    if (data is Map) {
      return ShopProfile.fromMap(Map<String, dynamic>.from(data));
    }
    return const ShopProfile();
  }

  @override
  Future<void> saveShopProfile(ShopProfile profile) async {
    await _profileBox?.put('profile', profile.toMap());
  }

  @override
  Stream<List<RepairTicket>> watchTickets() async* {
    yield _allTicketsList();
    yield* _streamController.stream;
  }

  void dispose() {
    _streamController.close();
  }
}
