import 'dart:ui';
import 'line_model.dart';
import 'package:uuid/uuid.dart';

class Direction {
  final String id;
  String labelFrom;
  String labelTo;
  Color color;
  bool isLocked;
  List<LineModel> lines;

  Direction({
    String? id,
    required this.labelFrom,
    required this.labelTo,
    required this.color,
    this.isLocked = false,
    List<LineModel>? lines,
  })  : id = id ?? const Uuid().v4(),
        lines = lines ?? [];

  int get lineCount => lines.length;

  bool get canLock {
    if (lines.isEmpty) return false;
    if (labelFrom.isEmpty || labelTo.isEmpty) return false;
    return lines.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    if (lines.isEmpty) {
      throw Exception("Direction must have at least one line");
    }
    return {
      'id': id,
      'from': labelFrom,
      'to': labelTo,
      'color': color.toARGB32(),
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }

  factory Direction.fromJson(Map<String, dynamic> json) {
    return Direction(
      id: json['id'],
      labelFrom: json['from'],
      labelTo: json['to'],
      color: Color(json['color']),
      lines: (json['lines'] as List)
          .map((l) => LineModel.fromJson(l))
          .toList(),
      isLocked: true,
    );
  }
}
