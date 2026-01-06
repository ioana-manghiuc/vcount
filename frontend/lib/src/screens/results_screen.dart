import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/settings_controller.dart';
import '../models/count_result_model.dart';
import '../models/direction_model.dart';

class ResultsScreen extends StatelessWidget {
  final List<CountResultModel> results;
  final List<DirectionModel> directions;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.directions,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsController>().locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: ListView(
        children: results.map((r) {
          final dir =
              directions.firstWhere((d) => d.id == r.directionId);

          return Card(
            child: ListTile(
              title: Text(dir.label[lang] ?? r.directionId),
              subtitle: Text(
                'Bikes: ${r.bikes}, Cars: ${r.cars}, '
                'Buses: ${r.buses}, Trucks: ${r.trucks}',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}