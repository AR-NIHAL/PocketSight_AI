# PocketSight

> **On-Device Object & Plant Micro-Inspector** — an offline-first smart local inventory & physical inspection tool. 100% on-device ML, zero cloud.

PocketSight turns your phone's camera into a portable inspection workstation: point it at an object or plant, get a live bounding-box detection with category classification, tag the result with notes and an inspection schedule, and keep everything in a fully offline local inventory with search, filtering, and JSON backup.

## Highlights

- **Fully offline.** Object detection runs on-device via Google ML Kit. Nothing leaves the device.
- **Live scanning.** Throttled camera frame pipeline (10/12/15 FPS) with real-time bounding-box overlays.
- **Tap-to-inspect.** Tap a detection to freeze the frame, crop a thumbnail, and tag it into the inventory.
- **Local inventory.** Hive-backed gallery with search, category filters, Markdown notes, inspection schedules, and edit/delete.
- **JSON backup.** Export the whole inventory to the share sheet and import it back via the file picker.
- **Performance controls.** Confidence threshold slider + FPS mode, applied live to the detection pipeline.

## Stack

| Area | Choice |
|---|---|
| UI / state | Flutter · Riverpod 3 (codegen) · Freezed |
| Navigation | GoRouter (stateful shell) |
| Detection | `google_mlkit_object_detection` (bundled model, category classification) |
| Storage | Hive (`hive_ce` + `hive_ce_flutter`) |
| Imaging | `image` (thumbnail cropping) · `camera` (frame stream) |
| Backup | `share_plus` (export) · `file_picker` (import) |
| Notes | `flutter_markdown_plus` |

## Architecture

Feature-first Clean Architecture. Each feature is split into three layers with a strict dependency direction:

```
lib/
  core/                         # app shell, router, theme
    app.dart
    router/app_router.dart
    theme/app_theme.dart
    presentation/app_shell.dart
  features/
    scanner/                    # Live on-device vision engine
      domain/                   # pure Dart: entities, contracts, use cases
      data/                     # camera + ML Kit + thumbnail datasources, repos
      presentation/             # scanner screen, notifier, painters, form sheet
    inventory/                  # offline local inventory
      domain/                   # InspectionItem, schedule, repository contract, use cases
      data/                     # Hive repository, backup service, providers
      presentation/             # gallery grid, detail screen, providers
    settings/                   # performance & model controls
      domain/                   # InspectionSettings, FpsMode, contract, use cases
      data/                     # Hive settings repository
      presentation/             # settings screen, SettingsController
```

- **Domain** is pure Dart — no Flutter, Riverpod, or SDK imports.
- **Data** implements domain contracts and owns all platform I/O (camera, ML Kit, Hive, files).
- **Presentation** renders state and dispatches actions; business logic lives in Riverpod notifiers.

## Getting started

Requires Flutter with Dart SDK ^3.11.5.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after edits to annotated sources
flutter run                                                # on an Android/iOS device
```

> The scanner needs a real camera — it is not functional on desktop/web scaffolds (mobile only).

## Testing

```bash
flutter analyze          # static analysis (0 issues expected)
flutter test             # unit + widget tests
flutter test integration_test -d <device-id>   # on-device sanity check (boot + tab navigation)
```

Current coverage focuses on: domain entities/use cases, the camera→NV21→ML Kit conversion and detection mapping, thumbnail cropping, the Hive repositories (inventory + settings), and widget tests for the scanner shell, inventory grid/detail, and settings controls.

## Roadmap / status

See [`PLAN.md`](PLAN.md) — the single source of truth for architecture decisions and the phased build plan.

| Phase | Description | Status |
|---|---|---|
| 0–1 | Scaffold, foundation, domain layer | ✅ |
| 2 | Scanner: camera + ML pipeline | ✅ |
| 3 | Tap-to-inspect & local tagging | ✅ |
| 4 | Inventory: Hive, gallery, detail, backup | ✅ |
| 5 | Settings: live confidence + FPS controls | ✅ |
| 6 | Polish, tests & docs | ✅ |

## License

Private project. Not for public distribution.
