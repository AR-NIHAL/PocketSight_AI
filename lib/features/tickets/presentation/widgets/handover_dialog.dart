import 'package:flutter/material.dart';
import '../../domain/entities/delivery_record.dart';
import '../../domain/entities/repair_ticket.dart';

class HandoverDialog extends StatefulWidget {
  final RepairTicket ticket;

  const HandoverDialog({
    super.key,
    required this.ticket,
  });

  @override
  State<HandoverDialog> createState() => _HandoverDialogState();
}

class _HandoverDialogState extends State<HandoverDialog> {
  bool _isRepaired = true;
  final _unrepairedReasonController = TextEditingController();
  late TextEditingController _receiverController;
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController();

  final Map<String, bool> _returnedAccessories = {};

  @override
  void initState() {
    super.initState();
    _receiverController =
        TextEditingController(text: widget.ticket.customer.name);
    if (widget.ticket.finalCost != null || widget.ticket.estimatedCost != null) {
      final cost = widget.ticket.finalCost ?? widget.ticket.estimatedCost;
      _amountPaidController.text = cost?.toStringAsFixed(0) ?? '';
    }

    for (final acc in widget.ticket.intakeDetails.suppliedAccessories) {
      _returnedAccessories[acc] = true; // default all checked
    }
  }

  @override
  void dispose() {
    _unrepairedReasonController.dispose();
    _receiverController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Device Handover / Delivery'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Repaired or Cancelled toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Repaired'),
                  icon: Icon(Icons.check_circle, color: Colors.green),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Unrepaired / Cancelled'),
                  icon: Icon(Icons.cancel, color: Colors.red),
                ),
              ],
              selected: {_isRepaired},
              onSelectionChanged: (set) {
                setState(() => _isRepaired = set.first);
              },
            ),
            const SizedBox(height: 14),

            if (!_isRepaired) ...[
              TextField(
                controller: _unrepairedReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Returning Unrepaired *',
                  hintText: 'e.g. Spare part unavailable, customer declined quote',
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Accessory Return Checklist
            if (widget.ticket.intakeDetails.suppliedAccessories.isNotEmpty) ...[
              const Text(
                'Verify Accessories Returned to Customer:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: widget.ticket.intakeDetails.suppliedAccessories.map((acc) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(acc),
                        value: _returnedAccessories[acc] ?? false,
                        onChanged: (val) {
                          setState(() => _returnedAccessories[acc] = val ?? false);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                '• No accessories were deposited at intake.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _receiverController,
              decoration: const InputDecoration(
                labelText: 'Received By (Person Name) *',
                hintText: 'Name of person collecting device',
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount Collected (৳)',
                prefixText: '৳ ',
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Handover Remarks (Optional)',
                hintText: 'e.g. Tested in front of customer, charger given',
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
            final receiver = _receiverController.text.trim();
            if (receiver.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter receiver name.')),
              );
              return;
            }
            if (!_isRepaired && _unrepairedReasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter unrepaired reason.')),
              );
              return;
            }

            final returnedList = _returnedAccessories.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

            final record = DeliveryRecord(
              deliveredAt: DateTime.now(),
              isRepaired: _isRepaired,
              unrepairedReason: !_isRepaired
                  ? _unrepairedReasonController.text.trim()
                  : null,
              returnedAccessories: returnedList,
              receiverName: receiver,
              handoverNotes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              amountPaid: double.tryParse(_amountPaidController.text.trim()),
            );

            Navigator.of(context).pop(record);
          },
          child: const Text('Confirm Handover'),
        ),
      ],
    );
  }
}
