import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import '../localization/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'userManual'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              localizations?.translate('userManualIntro') ??
                  'Follow these steps to get started:',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _StepRow(
              number: '1',
              text: localizations?.translate('userManualStepUpload') ??
                  'Click the canvas or upload button to select a video.',
            ),
            _StepRow(
              number: '2',
              text: localizations?.translate('userManualStepWait') ??
                  'Wait while the server prepares the thumbnail.',
            ),
            _StepRow(
              number: '3',
              text: localizations?.translate('userManualStepDraw') ??
                  'Draw directions on the image, add labels, and lock them.',
            ),
            _StepRow(
              number: '4',
              text: localizations?.translate('userManualStepSend') ??
                  'Send the locked directions to the backend.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  localizations?.translate('userManualTip') ??
                      'Tip: You can change colors before drawing a new direction.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(number, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
