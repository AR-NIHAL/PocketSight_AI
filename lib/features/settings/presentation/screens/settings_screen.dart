import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fps_mode.dart';
import '../notifiers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text('Failed to load settings'),
              ],
            ),
          ),
        ),
        data: (settings) {
          final notifier = ref.read(settingsControllerProvider.notifier);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Detection', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Confidence threshold'),
                  const Spacer(),
                  Text(
                    '${(settings.confidenceThreshold * 100).round()}%',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              Slider(
                value: settings.confidenceThreshold,
                min: 0.1,
                max: 0.9,
                divisions: 16,
                label:
                    '${(settings.confidenceThreshold * 100).round()}%',
                onChanged: (value) => notifier.setConfidenceThreshold(value),
              ),
              Text(
                'Objects detected below this confidence are hidden from '
                'the scan results.',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 32),
              Text('Performance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<FpsMode>(
                segments: const [
                  ButtonSegment(
                    value: FpsMode.low,
                    icon: Icon(Icons.battery_saver_outlined),
                    label: Text('10'),
                  ),
                  ButtonSegment(
                    value: FpsMode.balanced,
                    icon: Icon(Icons.balance_outlined),
                    label: Text('12'),
                  ),
                  ButtonSegment(
                    value: FpsMode.high,
                    icon: Icon(Icons.bolt_outlined),
                    label: Text('15'),
                  ),
                ],
                selected: {settings.fpsMode},
                onSelectionChanged: (selection) =>
                    notifier.setFpsMode(selection.single),
              ),
              const SizedBox(height: 8),
              Text(
                '${settings.fpsMode.targetFps} frames per second — '
                '${switch (settings.fpsMode) {
                  FpsMode.low => 'maximum battery savings',
                  FpsMode.balanced => 'balanced responsiveness',
                  FpsMode.high => 'highest responsiveness',
                }}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
