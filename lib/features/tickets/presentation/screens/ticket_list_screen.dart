import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_status.dart';
import '../providers/ticket_providers.dart';
import 'new_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today $timeStr';
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return 'Yesterday $timeStr';
    } else {
      return DateFormat('dd MMM HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final filteredTickets = ref.watch(filteredTicketsProvider);
    final activeFilter = ref.watch(ticketStatusFilterProvider);
    final searchQuery = ref.watch(ticketSearchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Intake',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Workshop tickets',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ticket, customer or serial',
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => ref
                            .read(ticketSearchQueryProvider.notifier)
                            .setQuery(''),
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF0D5C56), width: 1.5),
                ),
              ),
              onChanged: (val) {
                ref.read(ticketSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),
          const SizedBox(height: 8),

          // 2. Filter Chips Row (All, Received, In progress, Ready)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: activeFilter == null,
                  onTap: () =>
                      ref.read(ticketStatusFilterProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Received',
                  isSelected: activeFilter == TicketStatus.received,
                  onTap: () => ref
                      .read(ticketStatusFilterProvider.notifier)
                      .setFilter(activeFilter == TicketStatus.received
                          ? null
                          : TicketStatus.received),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'In progress',
                  isSelected: activeFilter == TicketStatus.inProgress,
                  onTap: () => ref
                      .read(ticketStatusFilterProvider.notifier)
                      .setFilter(activeFilter == TicketStatus.inProgress
                          ? null
                          : TicketStatus.inProgress),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Ready',
                  isSelected: activeFilter == TicketStatus.ready,
                  onTap: () => ref
                      .read(ticketStatusFilterProvider.notifier)
                      .setFilter(activeFilter == TicketStatus.ready
                          ? null
                          : TicketStatus.ready),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Tickets List
          Expanded(
            child: ticketsAsync.when(
              data: (_) {
                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isNotEmpty || activeFilter != null
                              ? 'No tickets match the selected filters.'
                              : 'No workshop tickets yet.\nTap "+ New repair" below to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filteredTickets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ticket = filteredTickets[i];

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                TicketDetailScreen(ticketId: ticket.id),
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Device icon / thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF334155),
                                  child: const Icon(
                                    Icons.laptop_chromebook,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Center info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.shortTicketNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ticket.device.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      ticket.customer.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      ticket.reportedIssue,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right status pill & timestamp
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ticket.status.backgroundColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      ticket.status.displayName,
                                      style: TextStyle(
                                        color: ticket.status.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatRelativeTime(ticket.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // 4. Fixed Bottom "+ New repair" Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.transparent,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NewTicketScreen(),
                  ));
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  '+ New repair',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D5C56) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D5C56) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
