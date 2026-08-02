import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/detected_object.dart';
import '../notifiers/scanner_controller.dart';
import '../notifiers/scanner_state.dart';
import '../widgets/bounding_box_painter.dart';
import '../widgets/inspection_form_sheet.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerControllerProvider.notifier).start();
    });
  }

  Future<void> _openForm(DetectedObject selected) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InspectionFormSheet(detection: selected),
    );
    if (result == null) return;

    final controller = ref.read(scannerControllerProvider.notifier);
    final saved = await controller.saveSelected(
      title: result['title'] as String,
      category: result['category'] as String,
      markdownNotes: result['markdownNotes'] as String,
      schedule: result['schedule'] as dynamic,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved != null
            ? 'Saved "${saved.title}" to inventory'
            : 'Could not save item'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerControllerProvider);
    return Scaffold(
      body: switch (state) {
        ScannerIdle() => const _CenteredMessage(
            icon: Icons.camera_alt_outlined,
            title: 'Scanner idle',
          ),
        ScannerInitializing() => const Center(
            child: CircularProgressIndicator(),
          ),
        ScannerError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref
                .read(scannerControllerProvider.notifier)
                .start(),
          ),
        ScannerReady(:final controller, :final detections) =>
          _LiveCameraView(
            controller: controller,
            detections: detections,
            selectedId: null,
            onTapBox: (object) =>
                ref.read(scannerControllerProvider.notifier).select(object),
          ),
        ScannerFocused(
          :final controller,
          :final detections,
          :final selected,
        ) =>
          _LiveCameraView(
            controller: controller,
            detections: detections,
            selectedId: selected.id,
            onTapBox: null,
            overlay: _FocusedOverlay(
              selected: selected,
              onSave: () => _openForm(selected),
              onCancel: () => ref
                  .read(scannerControllerProvider.notifier)
                  .dismissSelection(),
            ),
          ),
      },
    );
  }
}

class _LiveCameraView extends StatelessWidget {
  const _LiveCameraView({
    required this.controller,
    required this.detections,
    required this.selectedId,
    required this.onTapBox,
    this.overlay,
  });

  final CameraController controller;
  final List<DetectedObject> detections;
  final String? selectedId;
  final void Function(DetectedObject)? onTapBox;
  final Widget? overlay;

  DetectedObject? _hitTest(Offset position, Size size) {
    if (size.isEmpty) return null;
    final x = (position.dx / size.width).clamp(0.0, 1.0);
    final y = (position.dy / size.height).clamp(0.0, 1.0);
    for (final object in detections) {
      if (object.boundingBox.isValid && object.boundingBox.contains(x, y)) {
        return object;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: onTapBox == null
                    ? null
                    : (details) {
                        final hit = _hitTest(
                          details.localPosition,
                          constraints.biggest,
                        );
                        if (hit != null) onTapBox!(hit);
                      },
                child: CameraPreview(
                  controller,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: BoundingBoxPainter(
                          detections: detections,
                          selectedId: selectedId,
                        ),
                      ),
                      ?overlay,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FocusedOverlay extends StatelessWidget {
  const _FocusedOverlay({
    required this.selected,
    required this.onSave,
    required this.onCancel,
  });

  final DetectedObject selected;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.center_focus_strong,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  selected.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                ),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.add_to_photos_outlined),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('Camera unavailable'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
