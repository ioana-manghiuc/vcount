import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../models/direction_line.dart';

class DrawOnImage extends StatefulWidget {
  final String imageUrl;

  const DrawOnImage({super.key, required this.imageUrl});

  @override
  State<DrawOnImage> createState() => _DrawOnImageState();
}

class _DrawOnImageState extends State<DrawOnImage> {
  Offset? _cursorPosition;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _cursorPosition = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox;
          provider.addPoint(details.localPosition, box.size);
        },
        child: Stack(
          children: [
            Image.network(widget.imageUrl, fit: BoxFit.contain),
            CustomPaint(
              size: Size.infinite,
              painter: _DirectionsPainter(
                directions: provider.directions,
                currentColor: provider.currentColor,
                cursorPosition: _cursorPosition,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionsPainter extends CustomPainter {
  final List<DirectionLine> directions;
  final Color currentColor;
  final Offset? cursorPosition;

  _DirectionsPainter({
    required this.directions,
    required this.currentColor,
    this.cursorPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in directions) {
      final paint = Paint()
        ..color = d.color
        ..strokeWidth = d.isLocked ? 3 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (d.points.isEmpty) continue;

      for (int i = 0; i < d.points.length - 1; i++) {
        final p1 = d.points[i];
        final p2 = d.points[i + 1];
        canvas.drawLine(
          Offset(p1.dx * size.width, p1.dy * size.height),
          Offset(p2.dx * size.width, p2.dy * size.height),
          paint,
        );
      }

      final pointPaint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;

      for (final p in d.points) {
        canvas.drawCircle(
          Offset(p.dx * size.width, p.dy * size.height),
          4,
          pointPaint,
        );
      }
    }

    if (cursorPosition != null && directions.isNotEmpty) {
      final activeDir = directions.firstWhereOrNull(
        (d) => !d.isLocked && d.points.isNotEmpty,
      );

      if (activeDir != null) {
        final previewPaint = Paint()
          ..color = activeDir.color.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final lastPoint = activeDir.points.last;
        canvas.drawLine(
          Offset(lastPoint.dx * size.width, lastPoint.dy * size.height),
          cursorPosition!,
          previewPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionsPainter oldDelegate) => true;
}

extension on List<DirectionLine> {
  DirectionLine? firstWhereOrNull(bool Function(DirectionLine) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
