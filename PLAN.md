# PocketSight — Development Plan & Project Guide

> On-Device Object & Plant Micro-Inspector — 100% offline ML, zero cloud.

This document is the **single source of truth** for PocketSight's architecture, decisions, and phased build plan. It is updated with a **completion status** after every phase so the project stays self-documenting.

---

## 1. Project Identity

- **App Name:** PocketSight — On-Device Object & Plant Micro-Inspector
- **Core Purpose:** An offline-first smart local inventory & physical inspection tool.
- **Key Differentiation:** 100% On-Device ML execution (zero API costs, zero privacy exposure, zero cloud dependencies like Firebase or OpenAI).
- **Primary Tech Stack:** Flutter · Riverpod 3.x (Codegen) · Feature-First Clean Architecture · Google ML Kit Object Detection (`google_mlkit_object_detection`) · Hive local storage · GoRouter · Freezed.

## 2. Locked Decisions

| Area | Decision | Rationale |
|---|---|---|
| Detection engine | Google ML Kit **bundled** object detector with category classification (incl. `plant`) | Zero model files, fastest to a working app. Species-level ID explicitly out of scope. |
| Storage backend | **Hive** via `hive_ce` (maintained community fork, identical API) | Pure Dart, simple, pairs well with Freezed. |
| Target platforms | **Android + iOS only** | Camera + ML Kit are mobile-only. Desktop/web scaffold folders will not be wired up. |
| Inspection schedules | **Stored metadata only** (date + notes on item) | No notifications/reminders; keeps the app dependency-free. |
| Camera package | Official `camera` plugin (`startImageStream` for frames) | Standard, integrates with ML Kit. |

## 3. Enforced Architecture Rules (Feature-First Clean Architecture)

1. **Domain Layer** (`lib/features/[feature]/domain/`)
   - Pure Dart **only**. Zero dependencies on Flutter UI, Riverpod, or third-party SDKs.
   - Contains pure **Entities**, **Repository Interfaces (Contracts)**, and **Use Cases**.
2. **Data Layer** (`lib/features/[feature]/data/`)
   - Implements Repository contracts defined in the Domain layer.
   - Manages **DataSources** (Camera Streams, ML Engine, Hive boxes).
   - Contains **Data Models** with explicit mappers to Domain Entities.
3. **Presentation Layer** (`lib/features/[feature]/presentation/`)
   - Flutter Widgets, CustomPainters, and Riverpod Notifiers/Providers.
   - Widgets **only** render state and dispatch actions. Business logic lives inside Riverpod Notifiers or Use Cases.

### Target Folder Structure

```
lib/
  core/
    app.dart                # MaterialApp.router + theme
    router/
      app_router.dart       # GoRouter shell + routes
    theme/
      app_theme.dart        # light/dark ThemeData
  features/
    scanner/                # Live On-Device Vision Engine
      domain/
      data/
      presentation/
    inspection/             # Tap-to-Inspect & Local Tagging
      domain/
      data/
      presentation/
    inventory/              # Offline Local Inventory Database
      domain/
      data/
      presentation/
    settings/               # Performance & Model Controls
      domain/
      data/
      presentation/
```

## 4. Dependency Stack

> **Resolved versions (Flutter 3.41.7 / Dart 3.11.5, verified 2026-08-02).** Several packages are pinned below latest because Dart 3.11.5 + Flutter's `meta 1.17.0` pin constrain the analyzer graph (analyzer 8.4.0 was selected).

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` / `riverpod_annotation` | **3.0.3** | State management (codegen) |
| `riverpod_generator` | **3.0.3** | Codegen (works on analyzer 8.x) |
| `freezed_annotation` / `freezed` | 3.1.0 / **3.2.2** | Immutable entities |
| `json_annotation` / `json_serializable` | **4.9.0** / **6.11.2** | JSON models |
| `build_runner` | **2.8.0** | Codegen runner (needs `build 4.0.0`) |
| `go_router` | ^17.3.0 | Navigation |
| `google_mlkit_object_detection` | ^0.16.0 | On-device object detection |
| `camera` | ^0.12.0+2 | Live camera feed + frame stream |
| `hive_ce` + `hive_ce_flutter` | ^2.19.3 / ^2.3.4 | Offline local storage |
| `image` | ^4.9.1 | Bounding-box thumbnail cropping |
| `path_provider` / `path` | ^2.1.6 / ^1.9.1 | App dirs / path handling |
| `uuid` | ^4.6.0 | Entity IDs |
| `file_picker` | **11.0.1** | JSON import (11.0.0 had broken Android build) |
| `share_plus` | **12.0.1** | JSON export (≥13.1 needs win32 6, conflicts with file_picker 11) |
| `flutter_markdown_plus` | ^1.0.12 | Render Markdown notes (original `flutter_markdown` is discontinued) |

> **Dev:** `flutter_test`, `flutter_lints ^6.0.0`, `mocktail ^1.0.5`.
> **Dropped:** `riverpod_lint` / `custom_lint` — incompatible with Dart 3.11.5 (needs `freezed_annotation ^2.2.0` or Dart ≥3.12). Optional linting, not required by the architecture.

## 5. Domain Model Overview (subject to Phase 1 confirmation)

- `DetectedObject` — `id`, `label`, `confidence`, `boundingBox` (normalized rect), `trackingId?`.
- `InspectionItem` — `id`, `title`, `category`, `markdownNotes`, `thumbnailPath?`, `detectionLabel?`, `detectionConfidence?`, `schedule?`, `createdAt`, `updatedAt`.
- `InspectionSchedule` — `nextDueDate`, `note?` (metadata only).
- `InspectionSettings` — `confidenceThreshold`, `fpsMode` (performance toggle).

### Repository Contracts
- `ObjectDetectionRepository` — detect objects from an input image/frame.
- `InventoryRepository` — CRUD + reactive watch on items, search/filter, JSON export/import.

### Use Cases
- Scanner: `DetectObjects`, throttle/frame pipeline config.
- Inspection: `CreateInspectionItem`, `UpdateInspectionItem`, `DeleteInspectionItem`, `CropThumbnail`.
- Inventory: `WatchInventoryItems`, `SearchInventoryItems`, `ExportInventory`, `ImportInventory`.
- Settings: `LoadSettings`, `SaveSettings`.

---

## 6. Phased Build Plan

### Phase 0 — Scaffold & Foundation ✅
- Clean default `main.dart`; introduce `core/` bootstrap (app + router + theme).
- Add dependencies + codegen (`build_runner`) smoke test — verified: `riverpod_generator` generated `app_router.g.dart`.
- Create feature-first folder skeleton with placeholder screens.
- GoRouter shell: Scanner (home), Inventory, Settings routes.
- **Exit criteria:** `flutter analyze` clean; app builds & navigates between placeholder screens.
- **Verified:** analyze 0 issues, 2/2 widget tests pass, `flutter build apk --debug` succeeds.

### Phase 1 — Domain Layer (pure Dart)
- Freezed entities, repository contracts, use cases in `domain/` (zero Flutter imports).
- Unit tests for use cases & entity immutability.
- **Exit criteria:** `flutter test` green; domain layer verified pure Dart.

### Phase 2 — Scanner (Camera + ML Pipeline)
- `camera` datasource (`startImageStream`), frame throttling to **10–15 FPS**.
- `google_mlkit_object_detection` datasource (bundled model, classification enabled).
- `ScannerController` notifier orchestrating frames → detections.
- `CameraFeedScreen` + `BoundingBoxPainter` overlay drawing live boxes.
- **Exit criteria:** live bounding boxes over camera preview on device/emulator.

### Phase 3 — Tap-to-Inspect & Local Tagging
- Tap hit-testing on bounding boxes → freeze/highlight target.
- Bottom-sheet form: title, category, Markdown notes, inspection schedule.
- Crop bounding-box region (`image`), save local thumbnail via data layer.
- Persist `InspectionItem` through `InventoryRepository`.
- **Exit criteria:** tap box → fill form → item saved with cropped thumbnail.

### Phase 4 — Inventory
- Hive box wiring (`hive_ce`), `HiveInventoryRepository` + model mappers.
- Gallery/List view with search + filter.
- Item detail screen rendering Markdown notes.
- JSON export/import backup (file_picker + share_plus).
- **Exit criteria:** full CRUD + search/filter + working backup round-trip.

### Phase 5 — Settings
- Hive-backed `InspectionSettings` + `SettingsNotifier`.
- Confidence threshold slider + performance/FPS modes.
- Settings wired **live** into the scanner pipeline.
- **Exit criteria:** toggles persist and affect detection behavior.

### Phase 6 — Polish, Tests & Docs
- Widget tests, integration sanity checks.
- Final README + keep `PLAN.md` status accurate.
- **Exit criteria:** ship-ready Android/iOS build.

---

## 7. Execution Guardrails (STRICT)

1. **No unsanctioned features.** No cloud sync, auth, social sharing, external APIs, or notifications unless explicitly approved. New ideas are proposed to the user and wait for **explicit approval**.
2. **Clarify, don't assume.** Ambiguity in business logic, UI workflow, or package selection → stop and ask structured questions.
3. **Phase-by-phase execution.** One phase at a time. Each phase ends with verification; the user confirms before the next phase begins.

## 8. Phase Completion Log

| Phase | Description | Status | Date |
|---|---|---|---|
| 0 | Scaffold & Foundation | ✅ Done | 2026-08-02 |
| 1 | Domain Layer | ⬜ Pending | — |
| 2 | Scanner (Camera + ML) | ⬜ Pending | — |
| 3 | Tap-to-Inspect & Tagging | ⬜ Pending | — |
| 4 | Inventory | ⬜ Pending | — |
| 5 | Settings | ⬜ Pending | — |
| 6 | Polish, Tests & Docs | ⬜ Pending | — |
