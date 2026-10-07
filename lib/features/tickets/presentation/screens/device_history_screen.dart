import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ticket_providers.dart';
import 'ticket_detail_screen.dart';

class DeviceHistoryScreen extends ConsumerWidget {
  final String serialNumber;
  final String deviceDisplayName;

  const DeviceHistoryScreen({
    super.key,
    required this.serialNumber,
    required this.deviceDisplayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Repair History: $deviceDisplayName'),
      ),
      body: ticketsAsync.when(
        data: (allTickets) {
          final historyTickets = allTickets.where((t) {
            final s = t.device.serialNumber?.trim().toUpperCase();
            return s != null && s.isNotEmpty && s == serialNumber.trim().toUpperCase();
          }).toList();

          if (historyTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No prior repair tickets found for S/N $serialNumber.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyTickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final ticket = historyTickets[i];
              return Card(
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.ticketNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          ticket.status.displayName,
                          style: TextStyle(color: ticket.status.color, fontSize: 11),
                        ),
                        backgroundColor: ticket.status.color.withValues(alpha: 0.1),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Customer: ${ticket.customer.name} (${ticket.customer.phone})'),
                      Text('Date: ${dateFormat.format(ticket.createdAt)}'),
                      const SizedBox(height: 4),
                      Text(
                        'Issue: ${ticket.reportedIssue}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                    ));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}
