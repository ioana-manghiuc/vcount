import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/direction_model.dart';

class DirectionOverlayPainter extends CustomPainter {
  final List<DirectionModel> directions;
  final Offset? previewStart;
  final Offset? previewEnd;

  DirectionOverlayPainter({
    required this.directions,
    this.previewStart,
    this.previewEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;

    for (final d in directions) {
      final start = Offset(
        d.start.dx * size.width,
        d.start.dy * size.height,
      );
      final end = Offset(
        d.end.dx * size.width,
        d.end.dy * size.height,
      );
      canvas.drawLine(start, end, paint);
    }

    if (previewStart != null && previewEnd != null) {
      canvas.drawLine(previewStart!, previewEnd!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}