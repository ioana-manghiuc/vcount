import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoordinateTextField extends StatelessWidget {
  final String label;
  final double value;
  final Function(String) onChanged;
  final bool enabled;
  final int lineIndex;
  final String coord;
  final Map<String, TextEditingController> coordinateControllers;
  final Map<String, FocusNode> coordinateFocusNodes;

  const CoordinateTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.lineIndex,
    required this.coord,
    required this.coordinateControllers,
    required this.coordinateFocusNodes,
  });

  @override
  Widget build(BuildContext context) {
    final key = '$lineIndex-$coord';
    
    if (!coordinateControllers.containsKey(key)) {
      coordinateControllers[key] = TextEditingController(text: value.toStringAsFixed(3));
    }

    if (!coordinateFocusNodes.containsKey(key)) {
      coordinateFocusNodes[key] = FocusNode();
    }

    final focusNode = coordinateFocusNodes[key]!;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (!enabled) return KeyEventResult.ignored;

        const step = 0.005;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyA:
            if (coord.startsWith('x')) {
              final currentValue = double.tryParse(coordinateControllers[key]!.text) ?? value;
              final newValue = (currentValue - step).clamp(0.0, 1.0);
              coordinateControllers[key]!.text = newValue.toStringAsFixed(3);
              onChanged(newValue.toStringAsFixed(3));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;

          case LogicalKeyboardKey.keyD:
            if (coord.startsWith('x')) {
              final currentValue = double.tryParse(coordinateControllers[key]!.text) ?? value;
              final newValue = (currentValue + step).clamp(0.0, 1.0);
              coordinateControllers[key]!.text = newValue.toStringAsFixed(3);
              onChanged(newValue.toStringAsFixed(3));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;

          case LogicalKeyboardKey.keyW:
            if (coord.startsWith('y')) {
              final currentValue = double.tryParse(coordinateControllers[key]!.text) ?? value;
              final newValue = (currentValue - step).clamp(0.0, 1.0);
              coordinateControllers[key]!.text = newValue.toStringAsFixed(3);
              onChanged(newValue.toStringAsFixed(3));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;

          case LogicalKeyboardKey.keyS:
            if (coord.startsWith('y')) {
              final currentValue = double.tryParse(coordinateControllers[key]!.text) ?? value;
              final newValue = (currentValue + step).clamp(0.0, 1.0);
              coordinateControllers[key]!.text = newValue.toStringAsFixed(3);
              onChanged(newValue.toStringAsFixed(3));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;

          default:
            return KeyEventResult.ignored;
        }
      },
      child: TextField(
        controller: coordinateControllers[key],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: const OutlineInputBorder(),
        ),
        style: Theme.of(context).textTheme.bodySmall,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: enabled,
        onChanged: onChanged,
      ),
    );
  }
}
