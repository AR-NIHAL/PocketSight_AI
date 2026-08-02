import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:pocketsite_ai/core/app.dart';
import 'package:pocketsite_ai/features/settings/data/providers.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';
import 'package:pocketsite_ai/features/settings/domain/repositories/settings_repository.dart';

const _cameraChannel = MethodChannel('plugins.flutter.io/camera');

/// In-memory settings store. Hive's disk I/O never completes under
/// `testWidgets` FakeAsync, so the app-level tests inject a fake to keep the
/// Settings tab from spinning forever.
class _FakeSettingsRepository implements SettingsRepository {
  InspectionSettings? stored;

  @override
  Future<InspectionSettings?> load() async => stored;

  @override
  Future<void> save(InspectionSettings settings) async {
    stored = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pocketsight_widget_test');
    Hive.init(tempDir.path);

    // No camera exists in the test environment: make `availableCameras()`
    // resolve immediately (empty list) so the scanner fails fast into its
    // error state instead of waiting forever on a real platform channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_cameraChannel, (call) async {
          if (call.method == 'availableCameras') return <dynamic>[];
          return null;
        });
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Widget app() => ProviderScope(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(_FakeSettingsRepository()),
        ],
        child: const PocketSightApp(),
      );

  testWidgets('app boots and shows the scanner shell', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(find.text('Camera unavailable'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    expect(find.text('No items yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Confidence threshold'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsOneWidget);
  });
}
