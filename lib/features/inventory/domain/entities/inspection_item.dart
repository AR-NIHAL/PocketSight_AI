import 'package:freezed_annotation/freezed_annotation.dart';

import 'inspection_schedule.dart';

part 'inspection_item.freezed.dart';
part 'inspection_item.g.dart';

/// An inventory item captured and tagged from the scanner.
@freezed
abstract class InspectionItem with _$InspectionItem {
  const factory InspectionItem({
    required String id,
    required String title,
    @Default('Uncategorized') String category,
    @Default('') String markdownNotes,
    String? thumbnailPath,
    String? detectionLabel,
    double? detectionConfidence,
    InspectionSchedule? schedule,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InspectionItem;

  factory InspectionItem.fromJson(Map<String, dynamic> json) =>
      _$InspectionItemFromJson(json);

  const InspectionItem._();
}
