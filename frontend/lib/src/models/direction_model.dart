import 'dart:ui';

class DirectionModel {
  final String id;
  final Offset start; // normalized
  final Offset end;   // normalized
  final Map<String, String> label; // { "en": "...", "ro": "..." }
  final bool locked;

  DirectionModel({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
    this.locked = true,
  });

  DirectionModel copyWith({
    Map<String, String>? label,
    bool? locked,
  }) {
    return DirectionModel(
      id: id,
      start: start,
      end: end,
      label: label ?? this.label,
      locked: locked ?? this.locked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'line',
        'label': label,
        'start': {'x': start.dx, 'y': start.dy},
        'end': {'x': end.dx, 'y': end.dy},
      };
}