import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bar.dart';
import '../view_models/results_view_model.dart';
import '../localization/app_localizations.dart';
import '../utils/backend_service.dart';
import '../widgets/results_widgets/loading_state.dart';
import '../widgets/results_widgets/error_state.dart';
import '../widgets/results_widgets/results_content.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed(context);
      },
      child: Consumer<ResultsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            // ── App bar: adds video dropdown below title when bulk ──────
            appBar: _ResultsAppBar(viewModel: viewModel),
            body: () {
              if (viewModel.isLoading) return const ResultsLoading();
              if (viewModel.error != null) {
                return ResultsError(error: viewModel.error!);
              }
              if (viewModel.resultsData == null) {
                final loc = AppLocalizations.of(context);
                return Center(
                  child: Text(
                    loc?.translate('noResultsAvailable') ??
                        'No results available',
                  ),
                );
              }
              return ResultsContent(viewModel: viewModel);
            }(),
          );
        },
      ),
    );
  }

  void _onBackPressed(BuildContext context) {
    final viewModel = context.read<ResultsViewModel>();

    if (!viewModel.isLoading) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final localizations = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            localizations?.translate('confirmCancel') ?? 'Cancel Processing?',
          ),
          content: Text(
            localizations?.translate('cancelProcessingMessage') ??
                'Video processing is in progress. Are you sure you want to cancel it and go back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(localizations?.translate('no') ?? 'No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                localizations?.translate('yes') ?? 'Yes',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    ).then((shouldCancel) {
      if (shouldCancel == true) {
        BackendService.cancelProcessing();
        viewModel.setLoading(false);
        viewModel.setError(
          localizations?.translate('processingCancelled') ??
              'Processing cancelled by user',
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom app bar — shows the standard title plus, in bulk mode, a video
// selector dropdown anchored to the top-left below the title row.
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ResultsViewModel viewModel;

  const _ResultsAppBar({required this.viewModel});

  @override
  Size get preferredSize => Size.fromHeight(
        (viewModel.isBulk && !viewModel.isLoading) ? kToolbarHeight + 48 : kToolbarHeight,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!viewModel.isBulk || viewModel.isLoading) {
      // Single-video: plain app bar unchanged.
      return const AppBarWidget(titleKey: 'resultsTitle');
    }

    // Bulk: app bar with an extra row below containing the dropdown.
    return AppBar(
      // Mirror AppBarWidget styling — adjust to match your actual widget.
      title: Text(
        AppLocalizations.of(context)?.translate('resultsTitle') ?? 'Results',
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.video_library,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: viewModel.selectedVideoIndex,
                    isExpanded: true,
                    isDense: true,
                    style: theme.textTheme.bodyMedium,
                    items: List.generate(
                      viewModel.videoDropdownLabels.length,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          viewModel.videoDropdownLabels[i],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    onChanged: (i) {
                      if (i != null) viewModel.setSelectedVideo(i);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}