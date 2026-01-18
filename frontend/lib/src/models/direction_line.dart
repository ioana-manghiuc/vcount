import 'dart:ui';
import '../models/direction_model.dart';
import '../models/point_model.dart';
class DirectionLine {
  final String id;
  final List<Offset> points;
  String labelFrom;
  String labelTo;
  Color color;
  bool isLocked;

  DirectionLine({
    required this.id,
    required this.points,
    required this.labelFrom,
    required this.labelTo,
    required this.color,
    this.isLocked = false,
  });

  bool get canLock =>
      points.length >= 2 &&
      labelFrom.isNotEmpty &&
      labelTo.isNotEmpty;

  Map<String, dynamic> toJson() {
    if (points.length < 2) {
      throw Exception("Direction must have at least 2 points");
    }
    return {
      'id': id,
      'from': labelFrom,
      'to': labelTo,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }

  DirectionModel toDirectionModel() {
  return DirectionModel(
    label: '$labelFrom → $labelTo',
    colorHex: '#${color.value.toRadixString(16).padLeft(8, '0')}',
    points: points
        .take(2)
        .map((p) => PointModel(p.dx, p.dy))
        .toList(),
  );

}
}