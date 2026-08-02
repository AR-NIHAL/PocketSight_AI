import 'package:flutter/material.dart';

import '../../../inventory/domain/entities/inspection_item.dart';
import '../../../inventory/domain/entities/inspection_schedule.dart';
import '../../domain/entities/detected_object.dart';

/// Bottom-sheet form for tagging a detection into the inventory, or for
/// editing an existing [InspectionItem].
///
/// Pops a `Map<String, dynamic>` with `title`, `category`, `markdownNotes`
/// and `schedule` when the user confirms. Pass either [detection] (new tag)
/// or [initial] (edit) — not both.
class InspectionFormSheet extends StatefulWidget {
  const InspectionFormSheet({super.key, this.detection, this.initial})
      : assert(detection != null || initial != null,
            'Either detection or initial must be provided');

  final DetectedObject? detection;
  final InspectionItem? initial;

  @override
  State<InspectionFormSheet> createState() => _InspectionFormSheetState();
}

class _InspectionFormSheetState extends State<InspectionFormSheet> {
  static const _categories = [
    'Uncategorized',
    'Plant',
    'Foliage',
    'Pest',
    'Tool',
    'Equipment',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _scheduleNoteController;
  late String _category;
  late bool _enableSchedule;
  late DateTime _dueDate;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final detection = widget.detection;
    _titleController = TextEditingController(
      text: initial?.title ?? detection?.label ?? '',
    );
    _notesController = TextEditingController(
      text: initial?.markdownNotes ?? '',
    );
    _scheduleNoteController = TextEditingController(
      text: initial?.schedule?.note ?? '',
    );
    _category = initial?.category ?? _categories.first;
    _enableSchedule = initial?.schedule != null;
    _dueDate =
        initial?.schedule?.nextDueDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _scheduleNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  InspectionSchedule? get _schedule => _enableSchedule
      ? InspectionSchedule(
          nextDueDate: _dueDate,
          note: _scheduleNoteController.text.trim().isEmpty
              ? null
              : _scheduleNoteController.text.trim(),
        )
      : null;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'category': _category,
        'markdownNotes': _notesController.text.trim(),
        'schedule': _schedule,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detection = widget.detection;
    final initial = widget.initial;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isEditing ? 'Edit item' : 'Tag detection',
                    style: textTheme.titleLarge),
                const SizedBox(height: 4),
                if (_isEditing)
                  Text(
                    'Category: ${initial!.category}',
                    style: textTheme.bodySmall,
                  )
                else if (detection != null)
                  Text(
                    '${detection.label} · '
                    '${(detection.confidence * 100).round()}% confidence',
                    style: textTheme.bodySmall,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Markdown)',
                    hintText: '**Height**: 12cm\nObservations…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set inspection schedule'),
                  value: _enableSchedule,
                  onChanged: (value) =>
                      setState(() => _enableSchedule = value),
                ),
                if (_enableSchedule) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      'Next inspection: '
                      '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: TextButton(
                      onPressed: _pickDueDate,
                      child: const Text('Change'),
                    ),
                  ),
                  TextFormField(
                    controller: _scheduleNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Save changes' : 'Save to inventory'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
