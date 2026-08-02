import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/detected_object.dart';
import '../notifiers/scanner_controller.dart';
import '../notifiers/scanner_state.dart';
import '../widgets/bounding_box_painter.dart';

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
          _LiveCameraView(controller: controller, detections: detections),
      },
    );
  }
}

class _LiveCameraView extends StatelessWidget {
  const _LiveCameraView({required this.controller, required this.detections});

  final CameraController controller;
  final List<DetectedObject> detections;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: CameraPreview(
            controller,
            child: CustomPaint(
              painter: BoundingBoxPainter(detections: detections),
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
