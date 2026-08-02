import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scanner/presentation/widgets/inspection_form_sheet.dart';
import '../../data/providers.dart';
import '../../domain/entities/inspection_item.dart';

class InspectionItemDetailScreen extends ConsumerStatefulWidget {
  const InspectionItemDetailScreen({super.key, required this.item});

  final InspectionItem item;

  @override
  ConsumerState<InspectionItemDetailScreen> createState() =>
      _InspectionItemDetailScreenState();
}

class _InspectionItemDetailScreenState
    extends ConsumerState<InspectionItemDetailScreen> {
  late InspectionItem _item = widget.item;

  Future<void> _edit() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InspectionFormSheet(initial: _item),
    );
    if (result == null || !mounted) return;

    final updated = _item.copyWith(
      title: result['title'] as String,
      category: result['category'] as String,
      markdownNotes: result['markdownNotes'] as String,
      schedule: result['schedule'] as dynamic,
      updatedAt: DateTime.now(),
    );
    await ref.read(inventoryRepositoryProvider).saveItem(updated);
    if (!mounted) return;
    setState(() => _item = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item updated')),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Remove "${_item.title}" from your inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(inventoryRepositoryProvider).deleteItem(_item.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = _item.schedule;
    final overdue = schedule != null &&
        schedule.nextDueDate.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailThumbnail(path: _item.thumbnailPath),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_item.category)),
              if (_item.detectionLabel != null)
                Chip(label: Text(_item.detectionLabel!)),
              if (_item.detectionConfidence != null)
                Chip(
                  label: Text(
                    '${(_item.detectionConfidence! * 100).round()}% confidence',
                  ),
                ),
            ],
          ),
          if (schedule != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  overdue ? Icons.warning_amber : Icons.event_outlined,
                  color: overdue ? theme.colorScheme.error : null,
                ),
                title: Text(overdue ? 'Inspection overdue' : 'Inspection due'),
                subtitle: Text(
                  '${_formatDate(schedule.nextDueDate)}'
                  '${schedule.note != null ? ' · ${schedule.note}' : ''}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_item.markdownNotes.isEmpty)
            Text('No notes', style: theme.textTheme.bodySmall)
          else
            MarkdownBody(
              data: _item.markdownNotes,
              styleSheet: MarkdownStyleSheet.fromTheme(theme),
            ),
          const SizedBox(height: 24),
          Text(
            'Added ${_formatDate(_item.createdAt)} · '
            'Updated ${_formatDate(_item.updatedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailThumbnail extends StatelessWidget {
  const _DetailThumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.center_focus_weak,
        size: 64,
        color: theme.colorScheme.outline,
      ),
    );
    final filePath = path;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: filePath != null
            ? Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
