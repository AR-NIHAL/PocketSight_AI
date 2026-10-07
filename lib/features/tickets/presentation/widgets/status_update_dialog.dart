import 'package:flutter/material.dart';
import '../../domain/entities/ticket_status.dart';

class StatusUpdateDialog extends StatefulWidget {
  final TicketStatus currentStatus;

  const StatusUpdateDialog({
    super.key,
    required this.currentStatus,
  });

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  late TicketStatus _selectedStatus;
  final _noteController = TextEditingController();
  final _technicianController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _technicianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Ticket Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TicketStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'New Status'),
              items: TicketStatus.values
                  .where((s) => s != TicketStatus.delivered) // Delivered handled in Handover Dialog
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(s.icon, size: 18, color: s.color),
                            const SizedBox(width: 8),
                            Text(s.displayName),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Work Note / Action Taken *',
                hintText: 'e.g. Diagnosed short on 19V rail; ordered charging IC chip.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _technicianController,
              decoration: const InputDecoration(
                labelText: 'Technician Name (Optional)',
                hintText: 'e.g. Rafiq',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final note = _noteController.text.trim();
            if (note.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a work note.')),
              );
              return;
            }
            Navigator.of(context).pop({
              'status': _selectedStatus,
              'note': note,
              'technician': _technicianController.text.trim().isNotEmpty
                  ? _technicianController.text.trim()
                  : null,
            });
          },
          child: const Text('Save Update'),
        ),
      ],
    );
  }
}
