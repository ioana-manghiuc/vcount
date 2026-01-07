import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle Counter')),
            body: Center(
              child: ElevatedButton(
  onPressed: () async {
    await vm.pickVideo(context); 
  },
  child: const Text('Pick Video'),
)
            ),
          );
        },
      ),
    );
  }
}