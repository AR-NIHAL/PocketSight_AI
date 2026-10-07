import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/receipt_share_service.dart';
import '../../domain/entities/delivery_record.dart';
import '../../domain/entities/repair_ticket.dart';
import '../../domain/entities/ticket_status.dart';
import '../providers/ticket_providers.dart';
import '../widgets/handover_dialog.dart';
import '../widgets/status_update_dialog.dart';
import 'device_history_screen.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  Future<void> _addPhotoToTicket(
    BuildContext context,
    WidgetRef ref,
    RepairTicket ticket,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null) {
      final photoStorage = ref.read(photoStorageServiceProvider);
      final savedPath = await photoStorage.savePhoto(
        ticketId: ticket.id,
        sourcePath: picked.path,
        customPrefix: 'condition_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updatedPhotos = List<String>.from(ticket.intakeDetails.photoPaths)
        ..add(savedPath);
      final updatedIntake =
          ticket.intakeDetails.copyWith(photoPaths: updatedPhotos);
      final updatedTicket = ticket.copyWith(
        intakeDetails: updatedIntake,
        updatedAt: DateTime.now(),
      );
      await ref.read(ticketRepositoryProvider).saveTicket(updatedTicket);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return ticketsAsync.when(
      data: (tickets) {
        final ticket = tickets.where((t) => t.id == ticketId).firstOrNull;

        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ticket Not Found')),
            body: const Center(child: Text('This ticket may have been removed.')),
          );
        }

        final profile = ref.watch(shopProfileProvider);

        return Scaffold(
          backgroundColor: AppTheme.surfaceWhite,
          appBar: AppBar(
            title: Text(
              ticket.shortTicketNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              // Status Pill in App Bar (Screen 06)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.status.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.status.displayName,
                    style: TextStyle(
                      color: ticket.status.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Popup menu for extra operations
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
                onSelected: (val) async {
                  if (val == 'history' && ticket.device.serialNumber != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DeviceHistoryScreen(
                        serialNumber: ticket.device.serialNumber!,
                        deviceDisplayName: ticket.device.displayName,
                      ),
                    ));
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Ticket?'),
                        content: Text(
                            'Are you sure you want to delete ticket ${ticket.shortTicketNumber}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref
                          .read(ticketRepositoryProvider)
                          .deleteTicket(ticket.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  }
                },
                itemBuilder: (_) => [
                  if (ticket.device.serialNumber != null &&
                      ticket.device.serialNumber!.isNotEmpty)
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18, color: AppTheme.primaryTeal),
                          SizedBox(width: 8),
                          Text('Device History'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete Ticket',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Outlined button: Share receipt
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ReceiptShareService.shareReceipt(
                            ticket: ticket,
                            profile: profile,
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textDark,
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Primary full/expanded action button
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: ticket.isClosed
                            ? null
                            : () async {
                                if (ticket.status == TicketStatus.ready) {
                                  // Mark delivered / Handover
                                  final record = await showDialog<DeliveryRecord>(
                                    context: context,
                                    builder: (_) =>
                                        HandoverDialog(ticket: ticket),
                                  );
                                  if (record != null) {
                                    await ref
                                        .read(ticketRepositoryProvider)
                                        .completeHandover(
                                          ticketId: ticket.id,
                                          deliveryRecord: record,
                                        );
                                  }
                                } else {
                                  // Update status
                                  final res =
                                      await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (_) => StatusUpdateDialog(
                                      currentStatus: ticket.status,
                                    ),
                                  );
                                  if (res != null) {
                                    await ref
                                        .read(ticketRepositoryProvider)
                                        .updateTicketStatus(
                                          ticketId: ticket.id,
                                          newStatus:
                                              res['status'] as TicketStatus,
                                          workNote: res['note'] as String,
                                          technicianName:
                                              res['technician'] as String?,
                                        );
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: ticket.isClosed
                              ? Colors.grey.shade400
                              : AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          ticket.isClosed
                              ? 'Delivered'
                              : (ticket.status == TicketStatus.ready
                                  ? 'Mark delivered'
                                  : 'Update status'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Device Card (Photo, Model, Serial, Verified Chip)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Thumbnail or Laptop Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: const Color(0xFFF1F5F9),
                        child: _getFirstAvailablePhoto(ticket) != null
                            ? Image.file(
                                File(_getFirstAvailablePhoto(ticket)!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.laptop_chromebook,
                                size: 30,
                                color: AppTheme.primaryTeal,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Model & Serial
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.device.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                ticket.device.serialNumber != null
                                    ? 'S/N: ${ticket.device.serialNumber}'
                                    : (ticket.device.missingSerialReason ??
                                        'No serial'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (ticket.device.isSerialVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check,
                                          size: 12, color: Color(0xFF15803D)),
                                      SizedBox(width: 2),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (ticket.device.missingSerialReason !=
                                  null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Shop ID',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Customer Row Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.customer.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.customer.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.phone_outlined,
                      color: AppTheme.primaryTeal,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Metadata Section (Complaint, Received with, Condition)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint
                    _buildMetaBlock(
                      label: 'COMPLAINT',
                      content: ticket.reportedIssue,
                    ),
                    const Divider(height: 20, color: AppTheme.borderLight),

                    // Received with & Condition in two columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMetaBlock(
                            label: 'RECEIVED WITH',
                            content: ticket.intakeDetails.suppliedAccessories
                                    .isEmpty
                                ? 'Device only'
                                : ticket.intakeDetails.suppliedAccessories
                                    .join(', '),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetaBlock(
                            label: 'CONDITION',
                            content: ticket
                                    .intakeDetails.physicalCondition.isNotEmpty
                                ? ticket.intakeDetails.physicalCondition
                                : 'Normal wear',
                          ),
                        ),
                      ],
                    ),

                    if (ticket.estimatedCost != null ||
                        ticket.storageLocation != null) ...[
                      const Divider(height: 20, color: AppTheme.borderLight),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ticket.estimatedCost != null)
                            Expanded(
                              child: _buildMetaBlock(
                                label: 'ESTIMATED COST',
                                content:
                                    '৳ ${ticket.estimatedCost!.toStringAsFixed(0)}',
                              ),
                            ),
                          if (ticket.storageLocation != null)
                            Expanded(
                              child: _buildMetaBlock(
                                label: 'SHELF / BIN',
                                content: ticket.storageLocation!,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Photos Row with Dashed/Outlined "+" tile
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Sticker photo
                    if (ticket.intakeDetails.stickerPhotoPath != null &&
                        File(ticket.intakeDetails.stickerPhotoPath!).existsSync())
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(ticket.intakeDetails.stickerPhotoPath!),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // Intake photos
                    ...ticket.intakeDetails.photoPaths
                        .where((p) => File(p).existsSync())
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(p),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )),

                    // Dashed / Outlined "+" tile to add more photos
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _addPhotoToTicket(context, ref, ticket),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: AppTheme.primaryTeal,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Activity Timeline Section
              const Text(
                'Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    if (ticket.workLogs.isEmpty)
                      const Text(
                        'No activity recorded yet.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      )
                    else
                      ...List.generate(ticket.workLogs.length, (index) {
                        final log = ticket.workLogs[index];
                        final isLast = index == ticket.workLogs.length - 1;
                        final dotColor = _getTimelineDotColor(log.statusChange);

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline dot and connecting vertical line
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Timeline event content
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(bottom: isLast ? 0 : 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${log.statusChange?.displayName ?? "Update"} • ${DateFormat('HH:mm').format(log.timestamp)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: dotColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        log.note,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      if (log.technicianName != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tech: ${log.technicianName}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading ticket: $err')),
      ),
    );
  }

  Widget _buildMetaBlock({required String label, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  String? _getFirstAvailablePhoto(RepairTicket ticket) {
    if (ticket.intakeDetails.stickerPhotoPath != null &&
        File(ticket.intakeDetails.stickerPhotoPath!).existsSync()) {
      return ticket.intakeDetails.stickerPhotoPath;
    }
    for (final p in ticket.intakeDetails.photoPaths) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  Color _getTimelineDotColor(TicketStatus? status) {
    switch (status) {
      case TicketStatus.received:
        return const Color(0xFF0284C7); // Sky blue
      case TicketStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case TicketStatus.ready:
        return const Color(0xFF16A34A); // Green
      case TicketStatus.delivered:
        return const Color(0xFF64748B); // Slate
      case TicketStatus.closedWithoutRepair:
        return const Color(0xFFDC2626); // Red
      default:
        return AppTheme.primaryTeal;
    }
  }
}
