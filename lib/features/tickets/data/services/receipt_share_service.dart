import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/repair_ticket.dart';
import '../../domain/entities/shop_profile.dart';

class ReceiptShareService {
  static String generateReceiptText({
    required RepairTicket ticket,
    required ShopProfile profile,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final dateStr = dateFormat.format(ticket.createdAt);

    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln(profile.shopName.toUpperCase());
    if (profile.phone.isNotEmpty) buffer.writeln('Phone: ${profile.phone}');
    if (profile.address.isNotEmpty) buffer.writeln('Address: ${profile.address}');
    buffer.writeln('====================================');
    buffer.writeln('REPAIR INTAKE RECEIPT');
    buffer.writeln('Ticket #: ${ticket.ticketNumber}');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('------------------------------------');
    buffer.writeln('CUSTOMER DETAILS');
    buffer.writeln('Name: ${ticket.customer.name}');
    buffer.writeln('Phone: ${ticket.customer.phone}');
    if (ticket.customer.alternatePhone != null &&
        ticket.customer.alternatePhone!.isNotEmpty) {
      buffer.writeln('Alt Phone: ${ticket.customer.alternatePhone}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('DEVICE DETAILS');
    buffer.writeln('Device: ${ticket.device.displayName}');
    buffer.writeln('Serial / S/N: ${ticket.device.displaySerial} ${ticket.device.isSerialVerified ? "[Verified]" : ""}');
    if (ticket.device.specs != null && ticket.device.specs!.isNotEmpty) {
      buffer.writeln('Specs: ${ticket.device.specs}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('REPORTED ISSUE / COMPLAINT');
    buffer.writeln(ticket.reportedIssue);
    buffer.writeln('------------------------------------');
    buffer.writeln('PHYSICAL CONDITION');
    buffer.writeln(ticket.intakeDetails.physicalCondition.isNotEmpty
        ? ticket.intakeDetails.physicalCondition
        : 'Normal wear & tear');
    buffer.writeln('------------------------------------');
    buffer.writeln('SUPPLIED ACCESSORIES');
    if (ticket.intakeDetails.suppliedAccessories.isEmpty) {
      buffer.writeln('• None (Device Only)');
    } else {
      for (final acc in ticket.intakeDetails.suppliedAccessories) {
        buffer.writeln('• $acc');
      }
    }
    if (ticket.intakeDetails.customAccessoriesNote != null &&
        ticket.intakeDetails.customAccessoriesNote!.isNotEmpty) {
      buffer.writeln('Note: ${ticket.intakeDetails.customAccessoriesNote}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('STATUS: ${ticket.status.displayName.toUpperCase()}');
    if (ticket.estimatedCost != null) {
      buffer.writeln('Est. Cost: ৳${ticket.estimatedCost!.toStringAsFixed(0)}');
    }
    buffer.writeln('====================================');
    if (profile.termsNote.isNotEmpty) {
      buffer.writeln(profile.termsNote);
      buffer.writeln('====================================');
    }

    return buffer.toString();
  }

  static Future<void> shareReceipt({
    required RepairTicket ticket,
    required ShopProfile profile,
  }) async {
    final text = generateReceiptText(ticket: ticket, profile: profile);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Repair Ticket #${ticket.ticketNumber} - ${ticket.device.displayName}',
      ),
    );
  }
}
