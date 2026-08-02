import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/settings/data/providers.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/fps_mode.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';
import 'package:pocketsite_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:pocketsite_ai/features/settings/presentation/screens/settings_screen.dart';

class _FakeSettingsRepository implements SettingsRepository {
  InspectionSettings? stored;

  @override
  Future<InspectionSettings?> load() async => stored;

  @override
  Future<void> save(InspectionSettings settings) async {
    stored = settings;
  }
}

Widget _harness(_FakeSettingsRepository repository) {
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  testWidgets('renders persisted confidence and fps settings', (tester) async {
    final repository = _FakeSettingsRepository()
      ..stored = const InspectionSettings(
        confidenceThreshold: 0.7,
        fpsMode: FpsMode.high,
      );

    await tester.pumpWidget(_harness(repository));
    await tester.pumpAndSettle();

    expect(find.text('Confidence threshold'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);

    final segmented = tester
        .widget<SegmentedButton<FpsMode>>(find.byType(SegmentedButton<FpsMode>));
    expect(segmented.selected, {FpsMode.high});
  });

  testWidgets('moving the confidence slider persists the new value',
      (tester) async {
    final repository = _FakeSettingsRepository();

    await tester.pumpWidget(_harness(repository));
    await tester.pumpAndSettle();

    final before = tester.widget<Slider>(find.byType(Slider)).value;
    expect(before, 0.5);

    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pumpAndSettle();

    final after = tester.widget<Slider>(find.byType(Slider)).value;
    expect(after, greaterThan(before));
    expect(repository.stored?.confidenceThreshold, after);
  });

  testWidgets('selecting an fps mode persists it', (tester) async {
    final repository = _FakeSettingsRepository();

    await tester.pumpWidget(_harness(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(repository.stored?.fpsMode, FpsMode.low);
  });
}
