import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lazycat/view/Request Page.dart';
import 'package:lazycat/view/account.dart';
import 'package:lazycat/view/widgets/notifications.dart';
import 'package:lazycat/viewModel/authService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lazycat/view/widgets/phoneverify.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/notificationService.dart';
import 'cariier.dart';
import 'login.dart';
import 'myorder.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  int _newUpdateCount = 0;
  bool _isDarkMode = false;

  // Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPhoneNumber();
    _checkNewUpdates();
    _checkNotificationPermissions();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // Load Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-1806980107390232/3402856678'  // Android test ID
          : 'ca-app-pub-3940256099942544/2934735716', // iOS test ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('Banner ad loaded successfully!');
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: ${error.message}');
          print('Error code: ${error.code}');
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  Future<void> _checkNotificationPermissions() async {
    bool permissionGranted = await NotificationService().checkAndRequestPermissions();
    if (!permissionGranted) {
      // Optionally show a custom dialog explaining why notifications are important
      _showPermissionExplanationDialog();
    }
  }

  void _showPermissionExplanationDialog() {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF2D3748) : Colors.white,
          title: Text(
            'Enable Notifications',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Notifications help you stay updated with important information. '
                'Please enable notifications to get the most out of LazyCat.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                NotificationService().checkAndRequestPermissions();
              },
              child: Text(
                'Enable',
                style: TextStyle(
                  color: Color(0xFF4ECDC4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkPhoneNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool hasPhone = await user.hasPhoneNumber();
      if (!hasPhone) {
        // Show phone number dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PhoneNumberDialog(user: user),
        );
      }
    }
  }

  Future<void> _checkNewUpdates() async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Get the locally stored update count
    final savedUpdateCount = prefs.getInt('total_updates_count') ?? 0;

    // Fetch current updates count from Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('updates')
        .get();

    // Calculate new updates
    final currentUpdateCount = querySnapshot.docs.length;

    // Compare and update new update count
    setState(() {
      _newUpdateCount = currentUpdateCount > savedUpdateCount
          ? currentUpdateCount - savedUpdateCount
          : 0;
    });
  }

  // List of pages to navigate between
  get _pages => [
    RequestPage(),
    CarrierPage(),
    OrdersPage(),
    AccountPage(user: FirebaseAuth.instance.currentUser),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detect system theme
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Define theme colors
    final primaryColor = Color(0xFF4ECDC4);
    final backgroundColor = isDarkMode ? Color(0xFF1A202C) : Color(0xFFF4F7F9);
    final cardColor = isDarkMode ? Color(0xFF2D3748) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: isDarkMode ? 0 : 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.asset(
              'assets/l.png',
              fit: BoxFit.contain,
             // color: isDarkMode ? Colors.white : null, // Tint logo in dark mode if needed
            ),
          ),
        ),
        title: Text(
          'LazyCat',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 24,
          ),
        ),
        actions: [
          // Notifications Button with Badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: HeroIcon(
                  HeroIcons.bell,
                  color: iconColor,
                  size: 28,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => NotificationsPage())
                  );

                  // Recheck new updates after returning
                  _checkNewUpdates();
                },
              ),
              if (_newUpdateCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_newUpdateCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Logout Button
          IconButton(
            icon: HeroIcon(
              HeroIcons.arrowRightOnRectangle,
              color: Colors.redAccent,
              size: 28,
            ),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage())
              );
            },
          ),
          SizedBox(width: 8), // Add a little padding on the right
        ],
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: _pages[_selectedIndex],
          ),

          // Banner Ad with loading indicator and visible container
          Container(
            width: AdSize.banner.width.toDouble(),
            height: AdSize.banner.height.toDouble(),
            color: isDarkMode ? Color(0xFF2D3748) : Colors.grey[200],
            alignment: Alignment.center,
            child: _isBannerAdLoaded
                ? AdWidget(ad: _bannerAd!)
                : Text(
              "Loading Ad...",
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: isDarkMode
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: cardColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: secondaryTextColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.shoppingBag),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.truck),
              label: 'Carrier',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.documentText),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.user),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}