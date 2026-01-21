import 'package:uuid/uuid.dart';

class LineModel {
  final String id;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  bool isEntry;

  LineModel({
    String? id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.isEntry = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
    'isEntry': isEntry,
  };

  factory LineModel.fromJson(Map<String, dynamic> json) {
    return LineModel(
      id: json['id'],
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      isEntry: json['isEntry'] ?? false,
    );
  }

  LineModel copyWith({
    String? id,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    bool? isEntry,
  }) {
    return LineModel(
      id: id ?? this.id,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      isEntry: isEntry ?? this.isEntry,
    );
  }
}
