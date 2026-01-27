import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../view_models/directions_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../models/direction_model.dart';

void showDirectionColorPicker(BuildContext context, DirectionModel direction) {
  final provider = context.read<DirectionsViewModel>();
  final localizations = AppLocalizations.of(context)!;
  Color tempColor = direction.color;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(localizations.pickAColor),
      content: ColorPicker(
        pickerColor: direction.color,
        onColorChanged: (Color color) => tempColor = color,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            provider.updateColor(tempColor);
            Navigator.of(context).pop();
          },
          child: Text(localizations.save),
        ),
      ],
    ),
  );
}
