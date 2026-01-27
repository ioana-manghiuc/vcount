import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';
import '../localization/app_localizations.dart';
import '../models/direction_model.dart';
import 'direction_card_widgets/color_picker_dialog.dart';
import 'direction_card_widgets/direction_card_header.dart';
import 'direction_card_widgets/direction_label_fields.dart';
import 'direction_card_widgets/entry_line_selector.dart';
import 'direction_card_widgets/line_coordinate_editor.dart';
import 'direction_card_widgets/direction_card_actions.dart';

class DirectionCard extends StatefulWidget {
  final DirectionModel direction;
  final AppLocalizations? localizations;

  const DirectionCard({required this.direction, required this.localizations, super.key});

  @override
  State<DirectionCard> createState() => _DirectionCardState();
}

class _DirectionCardState extends State<DirectionCard> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  final Map<String, TextEditingController> _coordinateControllers = {};
  final Map<String, FocusNode> _coordinateFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.direction.labelFrom);
    _toController = TextEditingController(text: widget.direction.labelTo);
    _initializeCoordinateControllers();
  }

  void _initializeCoordinateControllers() {
    for (int lineIndex = 0; lineIndex < widget.direction.lines.length; lineIndex++) {
      final line = widget.direction.lines[lineIndex];
      _coordinateControllers['$lineIndex-x1'] = TextEditingController(text: line.x1.toStringAsFixed(3));
      _coordinateControllers['$lineIndex-y1'] = TextEditingController(text: line.y1.toStringAsFixed(3));
      _coordinateControllers['$lineIndex-x2'] = TextEditingController(text: line.x2.toStringAsFixed(3));
      _coordinateControllers['$lineIndex-y2'] = TextEditingController(text: line.y2.toStringAsFixed(3));
    }
  }

  @override
  void didUpdateWidget(DirectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      _fromController.text = widget.direction.labelFrom;
      _toController.text = widget.direction.labelTo;
      _updateCoordinateControllers();
    }
  }

  void _updateCoordinateControllers() {
    _coordinateControllers.clear();
    _initializeCoordinateControllers();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    for (final controller in _coordinateControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _coordinateFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();
    final direction = widget.direction;
    final localizations = widget.localizations;
    final isSelected = provider.selectedDirection == direction;

    return InkWell(
      onTap: () { 
        provider.selectDirection(direction);
        if (direction.isLocked) {
          provider.unlockForEditing(direction);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).colorScheme.onSecondaryFixed
            : Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DirectionCardHeader(
                direction: direction,
                isSelected: isSelected,
                onColorTap: () => showDirectionColorPicker(context, direction),
              ),

              DirectionLabelFields(
                fromController: _fromController,
                toController: _toController,
                enabled: isSelected,
              ),

              if (direction.lines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  localizations!.linesCount(direction.lines.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                EntryLineSelector(
                  direction: direction,
                  enabled: isSelected,
                ),
                const SizedBox(height: 8),
              ],

              if (direction.lines.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...List.generate(direction.lines.length, (lineIndex) {
                  return LineCoordinateEditor(
                    direction: direction,
                    lineIndex: lineIndex,
                    isSelected: isSelected,
                    coordinateControllers: _coordinateControllers,
                    coordinateFocusNodes: _coordinateFocusNodes,
                  );
                }),
              ],
              
              DirectionCardActions(
                direction: direction,
                enabled: isSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}