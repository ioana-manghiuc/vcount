import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/settings_screen.dart';
import '../view_models/video_player_view_model.dart';

class RouteHandler {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case '/video':
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => VideoPlayerViewModel(),
            child: const VideoPlayerScreen(),
          ),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}