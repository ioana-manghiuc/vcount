import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/direction_model.dart';

class DrawingViewModel extends ChangeNotifier {
  final List<DirectionModel> _directions = [];

  bool _editMode = true;
  Offset? _startPx;
  Offset? _currentPx;
  Size? _canvasSize;

  bool get editMode => _editMode;
  List<DirectionModel> get directions => List.unmodifiable(_directions);
  Offset? get previewStart => _startPx;
  Offset? get previewEnd => _currentPx;

  void toggleEditMode() {
    _editMode = !_editMode;
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    _canvasSize = size;
  }

  void startDrawing(Offset position) {
    if (!_editMode) return;
    _startPx = position;
    _currentPx = position;
    notifyListeners();
  }

  void updateDrawing(Offset position) {
    if (!_editMode) return;
    _currentPx = position;
    notifyListeners();
  }

  void endDrawing() {
    if (!_editMode || _startPx == null || _currentPx == null) return;

    final startNorm = _normalize(_startPx!);
    final endNorm = _normalize(_currentPx!);

    _directions.add(
      DirectionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        start: startNorm,
        end: endNorm,
        label: {'en': 'New direction', 'ro': 'Direcție nouă'},
        locked: true,
      ),
    );

    _startPx = null;
    _currentPx = null;
    notifyListeners();
  }

  void updateLabel(String id, String lang, String value) {
    final index = _directions.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final updatedLabel = Map<String, String>.from(_directions[index].label);
    updatedLabel[lang] = value;

    _directions[index] =
        _directions[index].copyWith(label: updatedLabel);

    notifyListeners();
  }

  void removeDirection(String id) {
    _directions.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Offset _normalize(Offset px) {
    return Offset(
      px.dx / _canvasSize!.width,
      px.dy / _canvasSize!.height,
    );
  }
}