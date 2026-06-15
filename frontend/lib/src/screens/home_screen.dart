import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';
import '../view_models/results_view_model.dart';
import '../utils/backend_service.dart';
import '../view_models/home_view_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/directions_panel.dart';
import '../widgets/draw_on_image.dart';
import '../localization/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handlePick(BuildContext context, HomeViewModel vm) async {
    context.read<DirectionsViewModel>().reset();
    await vm.pickVideos();
  }

  Future<void> _handleSendDirections(
    BuildContext context,
    HomeViewModel homeViewModel,
    DirectionsViewModel directionsViewModel,
  ) async {
    final resultsViewModel = context.read<ResultsViewModel>();
    final loadedIntersectionName = directionsViewModel.file?.name;

    final intersectionName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => _IntersectionNameDialog(
        onConfirm: (name) => Navigator.pop(ctx, name),
        initialValue: loadedIntersectionName,
      ),
    );

    if (intersectionName == null || intersectionName.isEmpty) return;

    resultsViewModel.setLoading(true);

    if (context.mounted) {
      Navigator.of(context).pushNamed('/results');
    }

    Future.microtask(() {
      final id = BackendService.currentProcessingId;
      if (id != null) resultsViewModel.startProgressStream(id);
    });

    final videoPaths = homeViewModel.videos!.map((v) => v.path).toList();

    final results = await BackendService.sendVideos(
      videoPaths,
      directionsViewModel.serializeDirections(),
      directionsViewModel.selectedModel,
      intersectionName,
    );

    if (context.mounted) {
      if (results != null) {
        resultsViewModel.setResults(results);
      } else {
        resultsViewModel.setError('Failed to process vehicle counting');
      }
      resultsViewModel.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final vm = context.watch<HomeViewModel>();
    final directionsProvider = context.watch<DirectionsViewModel>();

    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'appTitle'),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [

            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: _CanvasArea(
                    viewModel: vm,
                    localizations: localizations,
                    onPick: () => _handlePick(context, vm),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: vm.hasVideos && !vm.isLoading
                  ? Column(
                      children: [
                        const Expanded(child: DirectionsPanel()),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: directionsProvider.canSend
                                ? () async => await _handleSendDirections(
                                    context, vm, directionsProvider)
                                : null,
                            child: Text(localizations.sendToBackend),
                          ),
                        ),
                      ],
                    )
                  : _DirectionsPlaceholder(localizations: localizations),
            ),
          ],
        ),
      ),
    );
  }
}


class _CanvasArea extends StatelessWidget {
  final HomeViewModel viewModel;
  final AppLocalizations localizations;
  final VoidCallback onPick;

  const _CanvasArea({
    required this.viewModel,
    required this.localizations,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoCount = viewModel.videos?.length ?? 0;

    if (viewModel.thumbnailUrl != null && !viewModel.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            DrawOnImage(imageUrl: viewModel.thumbnailUrl!),

              
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(videoCount == 1
                      ? localizations.videoSelectedForProcessing(videoCount)
                      : localizations.videosSelectedForProcessing(videoCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onPick,
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          localizations.change,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (viewModel.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingAnimationWidget.waveDots(
                color: theme.colorScheme.primary,
                size: 72,
              ),
              const SizedBox(height: 12),
              Text(localizations.waitingForServer,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }


    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                textStyle: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              onPressed: onPick,
              child: Text(localizations.pickVideo),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.selectOneOrMoreVideos,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            _BulkInfoLink(),
          ],
        ),
      ),
    );
  }
}

class _BulkInfoLink extends StatelessWidget {
  const _BulkInfoLink();

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('aboutBulkProcessing') ?? 'About Processing Multiple Videos'),
        content: const SingleChildScrollView(
          child: Text(
            'Bulk processing lets you analyse multiple recordings of the '
            'same intersection in one go.'
            '• Select several videos filmed at the same location.'
            '• You will still draw directions on a single representative '
            'frame — the same configuration is applied to every video.'
            'Results are aggregated per direction across all provided '
            'videos, giving you a combined count for the intersection.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)?.translate('aboutBulkProcessing') ?? 'About Processing Multiple Videos',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DirectionsPlaceholder extends StatelessWidget {
  final AppLocalizations localizations;
  const _DirectionsPlaceholder({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            localizations.uploadVideoToStartDrawingDirections,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
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
          onChanged: (value) => setState(() {}),
          onSubmitted: (value) {
            if (value.isNotEmpty) widget.onConfirm(value);
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
