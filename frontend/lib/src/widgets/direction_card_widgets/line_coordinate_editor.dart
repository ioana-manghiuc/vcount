import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/directions_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../models/direction_model.dart';
import 'coordinate_text_field.dart';

class LineCoordinateEditor extends StatelessWidget {
  final DirectionModel direction;
  final int lineIndex;
  final bool isSelected;
  final Map<String, TextEditingController> coordinateControllers;
  final Map<String, FocusNode> coordinateFocusNodes;

  const LineCoordinateEditor({
    super.key,
    required this.direction,
    required this.lineIndex,
    required this.isSelected,
    required this.coordinateControllers,
    required this.coordinateFocusNodes,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context)!;
    final line = direction.lines[lineIndex];
    final isLineSelected = provider.selectedLineId == line.id;
    
    return InkWell(
      onTap: isSelected ? () => provider.selectLine(isLineSelected ? null : line.id) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLineSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: isLineSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.lineNumber(lineIndex + 1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => provider.deleteLineAtIndex(direction, lineIndex),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: CoordinateTextField(
                    label: 'X1',
                    value: line.x1,
                    lineIndex: lineIndex,
                    coord: 'x1',
                    coordinateControllers: coordinateControllers,
                    coordinateFocusNodes: coordinateFocusNodes,
                    enabled: isSelected,
                    onChanged: (value) {
                      final x = double.tryParse(value);
                      if (x != null) {
                        provider.updateLineCoordinates(direction, lineIndex, x, line.y1, line.x2, line.y2);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: CoordinateTextField(
                    label: 'Y1',
                    value: line.y1,
                    lineIndex: lineIndex,
                    coord: 'y1',
                    coordinateControllers: coordinateControllers,
                    coordinateFocusNodes: coordinateFocusNodes,
                    enabled: isSelected,
                    onChanged: (value) {
                      final y = double.tryParse(value);
                      if (y != null) {
                        provider.updateLineCoordinates(direction, lineIndex, line.x1, y, line.x2, line.y2);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: CoordinateTextField(
                    label: 'X2',
                    value: line.x2,
                    lineIndex: lineIndex,
                    coord: 'x2',
                    coordinateControllers: coordinateControllers,
                    coordinateFocusNodes: coordinateFocusNodes,
                    enabled: isSelected,
                    onChanged: (value) {
                      final x = double.tryParse(value);
                      if (x != null) {
                        provider.updateLineCoordinates(direction, lineIndex, line.x1, line.y1, x, line.y2);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: CoordinateTextField(
                    label: 'Y2',
                    value: line.y2,
                    lineIndex: lineIndex,
                    coord: 'y2',
                    coordinateControllers: coordinateControllers,
                    coordinateFocusNodes: coordinateFocusNodes,
                    enabled: isSelected,
                    onChanged: (value) {
                      final y = double.tryParse(value);
                      if (y != null) {
                        provider.updateLineCoordinates(direction, lineIndex, line.x1, line.y1, line.x2, y);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
