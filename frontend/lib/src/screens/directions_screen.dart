import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../widgets/draw_on_image.dart';
import '../widgets/directions_panel.dart';
import '../widgets/app_bar.dart';
import '../view_models/directions_view_model.dart';
import '../view_models/results_view_model.dart';
import '../utils/backend_service.dart';
import '../localization/app_localizations.dart';

class DirectionsScreen extends StatefulWidget {
  final VideoModel video;

  const DirectionsScreen({super.key, required this.video});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsViewModel>();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (provider.selectedLineId == null) return KeyEventResult.ignored;

        const step = 0.005;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyA:
            provider.adjustSelectedLineCoordinate(dx1: -step);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyD:
            provider.adjustSelectedLineCoordinate(dx2: step);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyW:
            provider.adjustSelectedLineCoordinate(dy1: -step);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyS:
            provider.adjustSelectedLineCoordinate(dy2: step);
            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      },
      child: Scaffold(
        appBar: const AppBarWidget(titleKey: 'drawDirections'),
        body: widget.video.thumbnailUrl == null
            ? const Center(child: CircularProgressIndicator())
            : _DirectionsScreenBody(video: widget.video),
      ),
    );
  }
}

class _DirectionsScreenBody extends StatelessWidget {
  final VideoModel video;

  const _DirectionsScreenBody({required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DrawOnImage(imageUrl: video.thumbnailUrl!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _DirectionsPanelWithSendButton(video: video),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionsPanelWithSendButton extends StatelessWidget {
  final VideoModel video;

  const _DirectionsPanelWithSendButton({required this.video});

  @override
  Widget build(BuildContext context) {
    final directionsProvider = context.watch<DirectionsViewModel>();
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        const Expanded(child: DirectionsPanel()),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: directionsProvider.canSend
                ? () async {
                    await _sendDirections(context, directionsProvider);
                  }
                : null,
            child: Text(localizations?.translate('sendToBackend') ?? 'Send to Backend'),
          ),
        ),
      ],
    );
  }

  Future<void> _sendDirections(
    BuildContext context,
    DirectionsViewModel directionsProvider,
  ) async {
    final localizations = AppLocalizations.of(context);
    final resultsViewModel = context.read<ResultsViewModel>();

    final lockedDirections = directionsProvider.directions.where((d) => d.isLocked).toList();
    for (final direction in lockedDirections) {
      if (direction.lines.length != 2) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(localizations?.translate('directionError') ?? 'Direction Error'),
              content: Text(
                localizations?.translate('twoLinesRequired') ?? 
                'Direction is defined by two lines! Edit current lines or start a new direction',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations?.translate('close') ?? 'Close'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final loadedIntersectionName = directionsProvider.file?.name;
    
    final intersectionName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => _IntersectionNameDialog(
        onConfirm: (name) => Navigator.pop(ctx, name),
        initialValue: loadedIntersectionName,
      ),
    );

    if (intersectionName == null || intersectionName.isEmpty) {
      return;
    }

    resultsViewModel.setLoading(true);

    if (context.mounted) {
      Navigator.of(context).pushNamed('/results');
    }

    final results = await BackendService.sendDirections(
      video.path,
      directionsProvider.serializeDirections(),
      directionsProvider.selectedModel,
      intersectionName,
    );

    if (context.mounted) {
      if (results != null) {
        resultsViewModel.setResults(results);
      } else {
        final localizations = AppLocalizations.of(context);
        resultsViewModel.setError(
          localizations?.translate('errorProcessingResults') ?? 
          'Failed to process vehicle counting'
        );
      }
      resultsViewModel.setLoading(false);
    }
  }
}

class _IntersectionNameDialog extends StatefulWidget {
  final Function(String) onConfirm;
  final String? initialValue;

  const _IntersectionNameDialog({
    required this.onConfirm,
    this.initialValue,
  });

  @override
  State<_IntersectionNameDialog> createState() =>
      _IntersectionNameDialogState();
}

class _IntersectionNameDialogState extends State<_IntersectionNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          localizations?.translate('intersectionName') ?? 'Intersection Name',
        ),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: localizations?.translate('enterIntersectionName') ??
                'Enter intersection name',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              widget.onConfirm(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: _controller.text.isEmpty
                ? null
                : () => widget.onConfirm(_controller.text),
            child: Text(localizations?.translate('confirm') ?? 'Confirm'),
          ),
        ],
      ),
    );
  }
}