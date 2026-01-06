import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/direction_model.dart';
import '../view_models/drawing_view_model.dart';
import '../settings/settings_controller.dart';

class DirectionListItem extends StatelessWidget {
  final DirectionModel direction;

  const DirectionListItem({super.key, required this.direction});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DrawingViewModel>();
    final locale = context.watch<SettingsController>().locale.languageCode;

    return ListTile(
      title: TextFormField(
        initialValue: direction.label[locale],
        decoration: const InputDecoration(labelText: 'Label'),
        onChanged: (v) => vm.updateLabel(direction.id, locale, v),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => vm.removeDirection(direction.id),
      ),
    );
  }
}