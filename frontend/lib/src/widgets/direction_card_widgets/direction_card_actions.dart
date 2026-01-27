import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/directions_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../models/direction_model.dart';

class DirectionCardActions extends StatelessWidget {
  final DirectionModel direction;
  final bool enabled;

  const DirectionCardActions({
    super.key,
    required this.direction,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        TextButton(
          onPressed: enabled
              ? () {
                  if (direction.lines.length != 2) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(localizations.directionError),
                        content: Text(
                          localizations.twoLinesRequired,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(localizations.close),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  if (!direction.canLock) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(localizations.directionError),
                        content: Text(
                          localizations.labelsAndLineRequired,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(localizations.translate('ok') == '**ok**' ? 'OK' : localizations.translate('ok')),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  provider.lockSelectedDirection();
                }
              : null,
          child: Text(localizations.save),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => provider.deleteDirection(direction),
        ),
      ],
    );
  }
}
