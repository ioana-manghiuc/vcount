import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/direction_model.dart';

class DirectionCardHeader extends StatelessWidget {
  final DirectionModel direction;
  final bool isSelected;
  final VoidCallback? onColorTap;

  const DirectionCardHeader({
    super.key,
    required this.direction,
    required this.isSelected,
    this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        GestureDetector(
          onTap: !isSelected ? null : onColorTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: direction.color,
              border: Border.all(color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isSelected
              ? localizations.editable
              : direction.isLocked
                  ? localizations.locked
                  : localizations.editable,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Theme.of(context).colorScheme.tertiary
                : direction.isLocked
                    ? Theme.of(context).colorScheme.onTertiary
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
