import 'dart:core';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lazycat/view/requestForm.dart';
import 'package:lazycat/view/widgets/bottomSheet.dart';
import 'package:lazycat/viewModel/authService.dart';

import 'package:url_launcher/url_launcher.dart';

class RequestPage extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode - this ensures we capture the current theme
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Define theme colors based on mode
    final primaryColor = isDarkMode ? Color(0xFF30908A) : Color(0xFF4ECDC4);
    final secondaryColor = isDarkMode ? Color(0xFF2D97B0) : Color(0xFF45B7D1);
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.white70;
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDarkMode ? Colors.black26 : Colors.black12;

    return Theme(
      // This ensures the theme is applied to all children
      data: isDarkMode
          ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardColor,
          background: backgroundColor,
        ),
      )
          : ThemeData.light().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardColor,
          background: backgroundColor,
        ),
      ),
      child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personalized Header Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey, ${_authService.getCurrentUser()?.displayName ?? "Student"}! 👋',
                          style: GoogleFonts.quicksand(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ready to get something delivered?',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Create Request Section
                  Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a New Request',
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Styled Create Request Button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateRequestScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  secondaryColor,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HeroIcon(
                                  HeroIcons.plus,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Create Request',
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Active Requests Section
                        Text(
                          'Your Latest Requests',
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Active Requests Stream Builder
                        _buildActiveRequestsList(context, isDarkMode),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildActiveRequestsList(BuildContext context, bool isDarkMode) {
    final String? currentUserId = _authService.getCurrentUser()?.uid;
    final textColor = isDarkMode ? Colors.white70 : Colors.grey;

    if (currentUserId == null) {
      return Center(
        child: Text(
          'Please log in to view requests',
          style: GoogleFonts.quicksand(
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Get today's date at midnight
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'Accepted'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Color(0xFF30908A) : Color(0xFF4ECDC4),
              ),
            ),
          );
        }

        // Filter documents to only show today's requests
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final request = doc.data() as Map<String, dynamic>;
          final Timestamp createdAtTimestamp = request['createdAt'];
          final DateTime createdAt = createdAtTimestamp.toDate();

          // Check if the request is from today
          return _isAtSameDayAs(createdAt, today);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No active requests today',
              style: GoogleFonts.quicksand(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Column(
          children: filteredDocs.map((doc) {
            final request = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(context, doc.id, request, isDarkMode);
          }).toList(),
        );
      },
    );
  }

  // Helper method to check if two dates are on the same day
  bool _isAtSameDayAs(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildPreviousRequestsList(BuildContext context, bool isDarkMode) {
    final String? currentUserId = _authService.getCurrentUser()?.uid;
    final textColor = isDarkMode ? Colors.white70 : Colors.grey;

    if (currentUserId == null) {
      return Center(
        child: Text(
          'Please log in to view requests',
          style: GoogleFonts.quicksand(
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Get today's date at midnight
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return StreamBuilder(
      stream: _firestore
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'Accepted', 'Completed'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Color(0xFF30908A) : Color(0xFF4ECDC4),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No Previous requests',
              style: GoogleFonts.quicksand(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Filter documents further in the client-side
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final Map<String, dynamic> request = doc.data() as Map<String, dynamic>;
          final Timestamp createdAtTimestamp = request['createdAt'];
          final DateTime createdAt = createdAtTimestamp.toDate();

          // If status is Completed, allow today's date
          if (request['status'] == 'Completed') {
            return _isAtSameDayAs(createdAt, today);
          }

          // Otherwise, ensure it's not today
          return !_isAtSameDayAs(createdAt, today);
        }).toList();

        return Column(
          children: filteredDocs.map((doc) {
            final Map<String, dynamic> request = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(context, doc.id, request, isDarkMode);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> request, bool isDarkMode) {
    bool isAccepted = request['status'] == 'Accepted';
    bool isPending = request['status'] == 'pending';

    // Define status-specific colors
    final pendingBgColor = isDarkMode ? Color(0xFF332A14) : Color(0xFFFFF4E5);
    final pendingBorderColor = isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300;
    final pendingTextColor = isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;

    final acceptedBgColor = isDarkMode ? Color(0xFF1A2E1A) : Color(0xFFE6F3E6);
    final acceptedBorderColor = isDarkMode ? Colors.green.shade700 : Colors.green.shade300;
    final acceptedTextColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;

    final cardBgColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        _showRequestDetailsBottomSheet(context, docId, request);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isAccepted
              ? acceptedBgColor
              : (isPending ? pendingBgColor : cardBgColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: isAccepted
              ? Border.all(color: acceptedBorderColor, width: 1.5)
              : (isPending ? Border.all(color: pendingBorderColor, width: 1.5) : null),
        ),
        child: ListTile(
          leading: Stack(
            children: [
              HeroIcon(
                isAccepted
                    ? HeroIcons.shoppingBag
                    : (isPending ? HeroIcons.clock : HeroIcons.shoppingBag),
                color: isAccepted
                    ? acceptedTextColor
                    : (isPending ? pendingTextColor : (isDarkMode ? Colors.white70 : Colors.grey)),
              ),
              if (isPending)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: pendingTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            request['requestType'] ?? 'Unnamed Request',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: isPending ? pendingTextColor : (isAccepted ? acceptedTextColor : textColor),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['itemDescription'] ?? 'No description',
                style: GoogleFonts.quicksand(
                  color: isPending ? pendingTextColor.withOpacity(0.8) : subtitleColor,
                ),
              ),
              if (isAccepted) ...[
                SizedBox(height: 4),
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(request['acceptedBy']).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading accepter details...',
                        style: GoogleFonts.quicksand(
                          color: acceptedTextColor,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      );
                    }

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final accepterData = userSnapshot.data!.data() as Map<String, dynamic>;
                      return Text(
                        'Accepted by: ${accepterData['name'] ?? 'Unknown'} | ${accepterData['phoneNumber'] ?? 'No phone'}',
                        style: GoogleFonts.quicksand(
                          color: acceptedTextColor,
                          fontSize: 12,
                        ),
                      );
                    }

                    return SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAccepted)
                Text(
                  'Order Accepted',
                  style: GoogleFonts.quicksand(
                    color: acceptedTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              if (isPending)
                Text(
                  'Pending',
                  style: GoogleFonts.quicksand(
                    color: pendingTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              Icon(
                Icons.chevron_right,
                color: isPending
                    ? pendingTextColor
                    : (isAccepted ? acceptedTextColor : (isDarkMode ? Colors.white54 : Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetailsBottomSheet(BuildContext context, String docId, Map<String, dynamic> request) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => RequestDetailsSheet(
          docId: docId,
          request: request,
          controller: controller,
        ),
      ),
    );
  }
}