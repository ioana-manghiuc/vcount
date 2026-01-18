import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/directions_provider.dart';
import '../localization/app_localizations.dart';
import '../models/direction_line.dart';

class DirectionCard extends StatefulWidget {
  final DirectionLine direction;
  final AppLocalizations? localizations;

  const DirectionCard({required this.direction, required this.localizations, super.key});

  @override
  State<DirectionCard> createState() => _DirectionCardState();
}

class _DirectionCardState extends State<DirectionCard> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.direction.labelFrom);
    _toController = TextEditingController(text: widget.direction.labelTo);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final direction = widget.direction;
    final localizations = widget.localizations;
    final isSelected = provider.selectedDirection == direction;

    return InkWell(
      onTap: () { 
        provider.selectDirection(direction);
        if (direction.isLocked) {
          provider.unlockForEditing(direction);
      }},
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: isSelected ? 4 : 1,
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
              Row(
                children: [
                  GestureDetector(
                    onTap: !isSelected ? null : () => _pickColor(context),
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
                        ? localizations!.editable
                        : direction.isLocked
                            ? localizations!.locked
                            : localizations!.editable,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.green
                          : direction.isLocked
                              ? Colors.grey[700]
                              : Colors.black,
                    ),
                  ),
                ],
              ),

              TextField(
                decoration: InputDecoration(labelText: localizations.from),
                controller: _fromController,
                onChanged: (v) => provider.updateLabels(v, _toController.text),
                enabled: isSelected,
              ),
              TextField(
                decoration: InputDecoration(labelText: localizations.to),
                controller: _toController,
                onChanged: (v) => provider.updateLabels(_fromController.text, v),
                enabled: isSelected,
              ),
              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: isSelected
                        ? (bool? value) {
                            setState(() => isChecked = value ?? false);
                          }
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      localizations.translate('multipleLinesDirection'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: isSelected
                        ? () => provider.lockSelectedDirection()
                        : null,
                    child: Text(localizations.save),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteDirection(direction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickColor(BuildContext context) {
    final provider = context.read<DirectionsProvider>();
    final direction = widget.direction;
    final localizations = widget.localizations;
    Color tempColor = direction.color;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations!.pickAColor),
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
}