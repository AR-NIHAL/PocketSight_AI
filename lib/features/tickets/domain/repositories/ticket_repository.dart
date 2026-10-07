import '../entities/delivery_record.dart';
import '../entities/repair_ticket.dart';
import '../entities/shop_profile.dart';
import '../entities/ticket_status.dart';

abstract class TicketRepository {
  Future<void> init();
  Future<List<RepairTicket>> getAllTickets();
  Future<RepairTicket?> getTicketById(String id);
  Future<List<RepairTicket>> getTicketsByDeviceSerial(String serial);
  Future<void> saveTicket(RepairTicket ticket);
  Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    required String workNote,
    String? technicianName,
  });
  Future<void> completeHandover({
    required String ticketId,
    required DeliveryRecord deliveryRecord,
  });
  Future<void> deleteTicket(String id);
  Future<int> getNextSequenceNumber();
  Future<ShopProfile> getShopProfile();
  Future<void> saveShopProfile(ShopProfile profile);
  Stream<List<RepairTicket>> watchTickets();
}
