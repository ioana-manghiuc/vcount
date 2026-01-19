import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'resultsTitle'),
      body: const Center(
        child: Text('Results screen – to be implemented'),
      ),
    );
  }
}
