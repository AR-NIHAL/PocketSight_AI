import 'package:freezed_annotation/freezed_annotation.dart';

part 'inspection_schedule.freezed.dart';
part 'inspection_schedule.g.dart';

/// Metadata describing when an item should next be inspected.
///
/// Stored metadata only — no reminders or notifications.
@freezed
abstract class InspectionSchedule with _$InspectionSchedule {
  const factory InspectionSchedule({
    required DateTime nextDueDate,
    String? note,
  }) = _InspectionSchedule;

  factory InspectionSchedule.fromJson(Map<String, dynamic> json) =>
      _$InspectionScheduleFromJson(json);

  const InspectionSchedule._();
}
