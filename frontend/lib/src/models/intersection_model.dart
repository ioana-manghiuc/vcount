import 'package:analyzer_plugin/utilities/pair.dart';
import 'direction_model.dart'; 

class IntersectionModel{
  final String id;
  final String name;
  final Pair<double, double> canvasSize;
  final List<DirectionModel> directions;

  IntersectionModel({
    required this.id,
    required this.name,
    required this.canvasSize,
    required this.directions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'canvasSize': {
        'w': canvasSize.first,
        'h': canvasSize.last,
      },
      'directions': directions.map((d) => d.toJson()).toList()
    };
  }

  factory IntersectionModel.fromJson(Map<String, dynamic> json) {
    return IntersectionModel(
      id: json['id'].toString(),
      name: json['name'], 
      canvasSize: Pair<double, double>(
        (json['canvasSize']['w'] as num).toDouble(),
        (json['canvasSize']['h'] as num).toDouble(),
      ),
      directions: (json['directions'] as List)
          .map((d) => DirectionModel.fromJson(d))
          .toList(),
    );
  }
}