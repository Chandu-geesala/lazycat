import 'package:flutter/material.dart';

// This class can be used to observe app lifecycle changes and react accordingly
class AppLifecycleReactor {
  final Function onAppForegrounded;

  // Minimum time app should be in background before showing ad on return
  final Duration minBackgroundDuration;
  DateTime? _pausedTime;

  AppLifecycleReactor({
    required this.onAppForegrounded,
    this.minBackgroundDuration = const Duration(seconds: 30),
  });

  void handleAppStateChange(AppLifecycleState state) {
    // App goes to foreground
    if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_pausedTime!);
        if (backgroundDuration >= minBackgroundDuration) {
          onAppForegrounded();
        }
      }
      _pausedTime = null;
    }
    // App goes to background
    else if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    }
  }
}