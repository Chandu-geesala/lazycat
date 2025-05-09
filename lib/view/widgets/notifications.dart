import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _saveUpdateCount();
  }

  Future<void> _saveUpdateCount() async {
    // Fetch updates from Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('updates')
        .get();

    // Save total update count to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_updates_count', querySnapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current brightness mode from the system
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Developer Updates',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            // Color based on theme
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        // Background color based on theme
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: HeroIcon(
            HeroIcons.arrowLeft,
            // Icon color based on theme
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Background color based on theme for the entire scaffold
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('updates')
            .snapshots(),
        builder: (context, snapshot) {
          // Check if data is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if there are no updates
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoUpdatesCard(context, isDarkMode);
          }

          // Display updates
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var update = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildUpdateCard(update, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      // Card color based on theme
      color: isDarkMode ? const Color(0xFF212121) : Colors.white,
      child: ListTile(
        leading: const HeroIcon(
          HeroIcons.informationCircle,
          color: Color(0xFF4ECDC4), // Keep accent color the same
          size: 32,
        ),
        title: Text(
          update['update'] ?? 'Update',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            // Text color based on theme
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildNoUpdatesCard(BuildContext context, bool isDarkMode) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        // Card color based on theme
        color: isDarkMode ? const Color(0xFF212121) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(
                HeroIcons.documentText,
                size: 64,
                // Icon color based on theme (slightly lighter gray for dark mode)
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Updates from Developer',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // Text color based on theme
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for the latest information',
                style: GoogleFonts.quicksand(
                  // Text color based on theme
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}