import 'package:flutter/material.dart';

import '../../domain/entities/detected_object.dart';

/// Paints live detection bounding boxes over the camera preview.
class BoundingBoxPainter extends CustomPainter {
  const BoundingBoxPainter({required this.detections});

  final List<DetectedObject> detections;

  static const _plantColor = Color(0xFF66BB6A);
  static const _genericColor = Color(0xFF4DD0E1);

  @override
  void paint(Canvas canvas, Size size) {
    for (final object in detections) {
      final box = object.boundingBox;
      if (!box.isValid) continue;

      final rect = Rect.fromLTRB(
        box.left * size.width,
        box.top * size.height,
        box.right * size.width,
        box.bottom * size.height,
      );
      final color = object.label.toLowerCase() == 'plant'
          ? _plantColor
          : _genericColor;

      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color,
      );

      _paintLabel(canvas, object, rect, color);
    }
  }

  void _paintLabel(Canvas canvas, DetectedObject object, Rect rect, Color color) {
    final text = '${object.label} ${(object.confidence * 100).round()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          backgroundColor: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final top = rect.top - textPainter.height < 0
        ? rect.top
        : rect.top - textPainter.height;
    textPainter.paint(canvas, Offset(rect.left, top));
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) =>
      oldDelegate.detections != detections;
}
