import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lazycat/utils/notificationService.dart';
import 'package:lazycat/view/splashScreen/splash_screen.dart';

import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

// Global singleton instance of AppOpenAdManager
final appOpenAdManager = AppOpenAdManager();

// App Open Ad Manager
class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();

  // Singleton pattern
  factory AppOpenAdManager() => _instance;

  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  // For testing/production, use appropriate ad unit ID
  final String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-1806980107390232/1813640506' // Your Android ad unit ID for production
      : 'ca-app-pub-3940256099942544/5662855259'; // iOS test ID

  // Load an app open ad
  void loadAd() {
    if (_appOpenAd != null) {
      print('Disposing existing ad before loading a new one');
      _appOpenAd!.dispose();
      _appOpenAd = null;
    }

    print('Loading App Open Ad with ID: $adUnitId');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('App Open Ad loaded successfully');
          _appOpenAd = ad;

          // Set fullscreen callbacks right after loading
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingAd = true;
              print('App Open Ad showed full screen content');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('App Open Ad dismissed');
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;

              // Reload for next time
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('App Open Ad failed to show: ${error.message}');
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;

              // Try loading again
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('App Open Ad failed to load: ${error.message}');
          _appOpenAd = null;

          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), () {
            loadAd();
          });
        },
      ),
    );
  }

  // Show the loaded ad
  void showAdIfAvailable() {
    if (_appOpenAd == null || _isShowingAd) {
      print('App Open Ad not available or already showing');
      if (_appOpenAd == null) {
        loadAd();
      }
      return;
    }

    print('Showing App Open Ad now');
    _appOpenAd!.show();
  }

  // Dispose of the ad when done
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}




Future<void> checkForPlayStoreUpdates(BuildContext context) async {
  try {
    print('Checking for Play Store updates...');
    AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      print("Update available: Version ${updateInfo.availableVersionCode}");
      await InAppUpdate.performImmediateUpdate();
    } else {
      print("No updates available.");
    }
  } catch (e) {
    print("Failed to check for updates: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('App starting...');

  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized');

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  print('Mobile Ads SDK initialized');

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('Firebase messaging background handler set');

  // Initialize notification service
  await NotificationService().initialize();
  print('Notification service initialized');

  // Initialize app open ad
  print('Loading initial App Open Ad');
 //  appOpenAdManager.loadAd();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Time when the app went to background (for tracking background time)
  DateTime? _pausedTime;

  // Use the global instance
  // No need to create a new instance here

  // Minimum time app needs to be in background to show ad when resumed
  final Duration _minBackgroundDuration = const Duration(seconds: 30);
  bool _isInitialAdShown = false;

  @override
  void initState() {
    super.initState();
    print('MyApp initializing...');
    WidgetsBinding.instance.addObserver(this);

    // Give some time for the app to fully initialize before showing ad
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isInitialAdShown) {
        print('Showing initial app open ad after delay');
        _isInitialAdShown = true;
        appOpenAdManager.showAdIfAvailable();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForPlayStoreUpdates(context);
    });
  }

  @override
  void dispose() {
    print('Disposing MyApp');
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the global app open ad manager here
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      if (_pausedTime != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_pausedTime!);
        if (backgroundDuration >= _minBackgroundDuration) {
          // Wait a moment for the UI to settle before showing the ad
          Future.delayed(const Duration(milliseconds: 700), () {
            appOpenAdManager.showAdIfAvailable();
          });
        }
      }
      _pausedTime = null;
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      _pausedTime = DateTime.now();
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LazyCat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MysplashScreen(),
    );
  }
}