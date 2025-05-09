import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/notificationService.dart';
import 'myorder.dart';

class CarrierPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current brightness mode from the system
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      // Background color based on theme for the entire scaffold
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Delivery Requests',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                // Color based on theme
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: _buildAvailableRequestsList(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRequestsList(BuildContext context, bool isDarkMode) {
    // Get the start and end of the current date
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    // Get the current user's UID
    String? currentUserUid = _auth.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .where('userId', isNotEqualTo: currentUserUid) // Exclude user's own requests
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              // Keep accent color the same
              color: const Color(0xFF4ECDC4),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No available requests',
              style: GoogleFonts.quicksand(
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var requestDoc = snapshot.data!.docs[index];
            var request = requestDoc.data() as Map<String, dynamic>;
            request['documentId'] = requestDoc.id; // Add document ID to the request map
            return _buildRequestCard(context, request, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request, bool isDarkMode) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(request['userId']).get(),
      builder: (context, userSnapshot) {
        // Default user name if fetching fails
        String userName = 'Unknown User';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Unknown User';
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          // Card color based on theme
          color: isDarkMode ? const Color(0xFF212121) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request Type and Item Description
                Text(
                  '${request['requestType'] ?? 'Delivery'} Request',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    // Keep accent color the same
                    color: const Color(0xFF4ECDC4),
                  ),
                ),
                SizedBox(height: 8),

                // Detailed Request Information
                _buildInfoRow(
                  icon: Icons.fastfood,
                  label: 'Item',
                  value: request['itemDescription'] ?? 'Not specified',
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'From',
                  value: request['fromLocation'] ?? 'Not specified',
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.location_pin,
                  label: 'To',
                  value: request['toLocation'] ?? 'Not specified',
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: 'Urgency',
                  value: '${request['urgencyLevel'] ?? 'Normal'} • ${request['urgencyTiming'] ?? 'Anytime'}',
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Requester',
                  value: userName,
                  isDarkMode: isDarkMode,
                ),

                SizedBox(height: 16),

                // Bottom Row with Reward and Accept Button
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Estimated Reward (if available)
                        Text(
                          'Estimated Reward: ₹${request['reward'] ?? 'Humanity ❣'}',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            // Green color adjusted for dark mode
                            color: isDarkMode ? Colors.lightGreen : Colors.green,
                            fontSize: 16,
                          ),
                        ),

                        // Accept Button
                        ElevatedButton(
                          onPressed: () {
                            _acceptRequest(context, request, isDarkMode);
                            // Navigate to OrdersPage after accepting
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrdersPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            'Accept Request',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptRequest(BuildContext context, Map<String, dynamic> request, bool isDarkMode) async {
    try {
      // Ensure the request contains a document ID
      if (request['documentId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid request: Missing document ID'),
            backgroundColor: isDarkMode ? Colors.red[700] : Colors.red,
          ),
        );
        return;
      }

      // Get the current user's UID
      String? currentUserUid = _auth.currentUser?.uid;

      if (currentUserUid == null) {
        // Show error if no user is logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to accept a request'),
            backgroundColor: isDarkMode ? Colors.red[700] : Colors.red,
          ),
        );
        return;
      }

      // Get current user's name to include in the notification
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserUid).get();
      String carrierName = 'Someone';

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        carrierName = userData['name'] ?? 'Someone';
      }

      // Reference to the specific request document
      await _firestore.collection('requests').doc(request['documentId']).update({
        'status': 'Accepted',
        'acceptedBy': currentUserUid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the request creator
      // Check if fcmToken exists in the request
      if (request.containsKey('fcmToken') && request['fcmToken'] != null) {
        String fcmToken = request['fcmToken'];

        // Prepare notification title and body
        final notificationTitle = "${request['requestType']} Request Accepted";
        String notificationBody = "$carrierName has accepted your ${request['itemDescription']} delivery request";

        // Add urgency level if it was urgent
        if (request['urgencyLevel'] == 'Very Urgent') {
          notificationBody += " (Urgent)";
        }

        // Add locations to make it more specific
        notificationBody += " from ${request['fromLocation']} to ${request['toLocation']}";

        // Add additional data for deep linking
        Map<String, dynamic> additionalData = {
          'requestId': request['documentId'],
          'requestType': request['requestType'],
          'route': 'accepted_request_details',
        };

        // Use the NotificationService to send a direct notification to the user
        await NotificationService().sendNotificationToToken(
          token: fcmToken,
          title: notificationTitle,
          body: notificationBody,
          data: additionalData,
        );

        print('Notification sent to user with FCM token: $fcmToken');
      } else {
        print('No FCM token found for this request creator');
      }

      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request Accepted Successfully'),
          // Success snackbar color based on theme
          backgroundColor: isDarkMode ? const Color(0xFF1E88E5) : const Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: isDarkMode ? Colors.red[700] : Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            // Keep accent color the same
            color: const Color(0xFF4ECDC4),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    // Label color based on theme
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    // Text color based on theme
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}