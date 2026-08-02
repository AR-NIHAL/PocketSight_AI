import 'package:freezed_annotation/freezed_annotation.dart';

part 'normalized_rect.freezed.dart';

/// A bounding box with coordinates normalized to the `0.0..1.0` range,
/// relative to the source image dimensions.
@freezed
abstract class NormalizedRect with _$NormalizedRect {
  const factory NormalizedRect({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) = _NormalizedRect;

  const NormalizedRect._();

  /// Whether all coordinates are within the unit range and the box has
  /// positive area (`right > left` and `bottom > top`).
  bool get isValid =>
      left >= 0 &&
      top >= 0 &&
      right <= 1 &&
      bottom <= 1 &&
      right > left &&
      bottom > top;

  /// Whether the normalized point ([x], [y]) falls inside this box.
  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;
}
