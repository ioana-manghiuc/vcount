import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/directions_view_model.dart';
import '../../localization/app_localizations.dart';

class DirectionLabelFields extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final bool enabled;

  const DirectionLabelFields({
    super.key,
    required this.fromController,
    required this.toController,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: localizations.from),
          controller: fromController,
          onChanged: (v) => provider.updateLabels(v, toController.text),
          enabled: enabled,
        ),
        TextField(
          decoration: InputDecoration(labelText: localizations.to),
          controller: toController,
          onChanged: (v) => provider.updateLabels(fromController.text, v),
          enabled: enabled,
        ),
      ],
    );
  }
}
