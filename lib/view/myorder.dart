import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current brightness mode from the system
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Background color based on theme for the entire scaffold
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          // Set background color based on theme
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          // Remove the back button/arrow
          automaticallyImplyLeading: false,
          title: Text(
            'Your Requests',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              // Text color based on theme
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          bottom: TabBar(
            // Tab indicator color consistent in both themes
            indicatorColor: const Color(0xFF4ECDC4),
            // Tab text color based on theme
            labelColor: isDarkMode ? Colors.white : Colors.black,
            unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey.shade600,
            tabs: [
              Tab(text: 'Accepted Requests'),
              Tab(text: 'Completed Requests'),
            ],
            labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          ),
          elevation: isDarkMode ? 0 : 1,
        ),
        body: TabBarView(
          children: [
            _buildAcceptedRequestsList(isDarkMode),
            _buildCompletedRequestsList(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedRequestsList(bool isDarkMode) {
    String? currentUserUid = _auth.currentUser?.uid;

    // Get today's date at midnight
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('acceptedBy', isEqualTo: currentUserUid)
          .where('status', isEqualTo: 'Accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              // Keep accent color consistent
              color: const Color(0xFF4ECDC4),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No accepted requests',
              style: GoogleFonts.quicksand(
                // Text color based on theme
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Filter to only show today's accepted requests
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final request = doc.data() as Map<String, dynamic>;
          final Timestamp createdAtTimestamp = request['createdAt'];
          final DateTime createdAt = createdAtTimestamp.toDate();

          // Keep only requests created today
          return _isAtSameDayAs(createdAt, today);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No active accepted requests for today',
              style: GoogleFonts.quicksand(
                // Text color based on theme
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var requestDoc = filteredDocs[index];
            var request = requestDoc.data() as Map<String, dynamic>;
            return _buildRequestDetailsCard(context, request, requestDoc.id, isDarkMode: isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildCompletedRequestsList(bool isDarkMode) {
    String? currentUserUid = _auth.currentUser?.uid;

    // Get today's date at midnight
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('acceptedBy', isEqualTo: currentUserUid)
          .where('status', whereIn: ['Accepted', 'Completed']) // Get both accepted and completed
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              // Keep accent color consistent
              color: const Color(0xFF4ECDC4),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No completed or expired requests',
              style: GoogleFonts.quicksand(
                // Text color based on theme
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Filter to show completed requests OR expired accepted requests
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final request = doc.data() as Map<String, dynamic>;
          final String status = request['status'];

          // Always include completed requests
          if (status == 'Completed') {
            return true;
          }

          // For accepted requests, only include if they're expired (not from today)
          if (status == 'Accepted') {
            final Timestamp createdAtTimestamp = request['createdAt'];
            final DateTime createdAt = createdAtTimestamp.toDate();
            return !_isAtSameDayAs(createdAt, today);
          }

          return false;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No completed or expired requests',
              style: GoogleFonts.quicksand(
                // Text color based on theme
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var requestDoc = filteredDocs[index];
            var request = requestDoc.data() as Map<String, dynamic>;
            bool isExpired = request['status'] == 'Accepted';
            return _buildRequestDetailsCard(
              context,
              request,
              requestDoc.id,
              isExpired: isExpired,
              isDarkMode: isDarkMode,
            );
          },
        );
      },
    );
  }

  // Add helper function to check if dates are the same day
  bool _isAtSameDayAs(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildRequestDetailsCard(
      BuildContext context,
      Map<String, dynamic> request,
      String requestId, {
        bool isExpired = false,
        required bool isDarkMode,
      }) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(request['userId']).get(),
      builder: (context, userSnapshot) {
        // Default user details in case fetching fails
        String userName = 'Unknown User';
        String userPhone = 'Not Available';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Unknown User';
          userPhone = userData['phoneNumber'] ?? 'Not Available';
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExpired
                ? BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey, width: 1.5)
                : BorderSide.none,
          ),
          // Card color based on theme and expired status
          color: isDarkMode
              ? (isExpired ? const Color(0xFF1A1A1A) : const Color(0xFF212121))
              : (isExpired ? Color(0xFFF0F0F0) : Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request Type with expired indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${request['requestType'] ?? 'Delivery'} Request',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          // Text color based on theme and status
                          color: isExpired
                              ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700)
                              : const Color(0xFF4ECDC4),
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isExpired)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // Expired badge color based on theme
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'EXPIRED',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            // Text color based on theme
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),

                // Request Details
                _buildInfoRow(
                  icon: Icons.fastfood,
                  label: 'Item',
                  value: request['itemDescription'] ?? 'Not specified',
                  isExpired: isExpired,
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'From',
                  value: request['fromLocation'] ?? 'Not specified',
                  isExpired: isExpired,
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.location_pin,
                  label: 'To',
                  value: request['toLocation'] ?? 'Not specified',
                  isExpired: isExpired,
                  isDarkMode: isDarkMode,
                ),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Requester',
                  value: userName,
                  isExpired: isExpired,
                  isDarkMode: isDarkMode,
                ),

                // Highlighted Contact Information with Dial Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Contact: $userPhone',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            // Contact color based on theme and status
                            color: isExpired
                                ? (isDarkMode ? Colors.grey.shade600 : Colors.grey)
                                : (isDarkMode ? Colors.lightGreen : Colors.green),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: (userPhone != 'Not Available' && !isExpired)
                            ? () => _launchDialer(userPhone)
                            : null,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            // Call button background based on theme and status
                            color: (userPhone != 'Not Available' && !isExpired)
                                ? Color(0xFF4ECDC4).withOpacity(isDarkMode ? 0.3 : 0.2)
                                : (isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.call,
                            // Call icon color based on theme and status
                            color: (userPhone != 'Not Available' && !isExpired)
                                ? Color(0xFF4ECDC4)
                                : (isDarkMode ? Colors.grey.shade700 : Colors.grey),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status and Reward
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExpired ? 'Status: Expired' : 'Status: ${request['status'] ?? 'Unknown'}',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        // Status color based on theme and status
                        color: isExpired
                            ? (isDarkMode ? Colors.grey.shade600 : Colors.grey)
                            : _getStatusColor(request['status'], isDarkMode),
                      ),
                    ),
                    Text(
                      'Reward: ₹${request['reward'] ?? 'Humanity ❣'}',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        // Reward color based on theme and status
                        color: isExpired
                            ? (isDarkMode ? Colors.grey.shade600 : Colors.grey)
                            : (isDarkMode ? Colors.lightGreen : Colors.green),
                      ),
                    ),
                  ],
                ),

                // Mark as Completed Button (for Accepted non-expired Requests)
                if (request['status'] == 'Accepted' && !isExpired)
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _markRequestAsCompleted(context, requestId, isDarkMode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Mark as Completed',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update the _buildInfoRow method to handle dark mode
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isExpired = false,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            // Icon color based on theme and status
            color: isExpired
                ? (isDarkMode ? Colors.grey.shade700 : Colors.grey)
                : const Color(0xFF4ECDC4),
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
                    // Value color based on theme and status
                    color: isExpired
                        ? (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade600)
                        : (isDarkMode ? Colors.white : Colors.black87),
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

  // Add this method to the class
  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Optional: Show an error or toast if dialer can't be launched
      print('Could not launch $launchUri');
    }
  }

  // Update status color method to handle dark mode
  Color _getStatusColor(String? status, bool isDarkMode) {
    switch (status) {
      case 'Accepted':
        return isDarkMode ? Colors.amber : Colors.orange;
      case 'Completed':
        return isDarkMode ? Colors.lightGreen : Colors.green;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey;
    }
  }

  // Updated to handle dark mode in snackbar
  Future<void> _markRequestAsCompleted(BuildContext context, String requestId, bool isDarkMode) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'Completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request marked as completed!'),
          backgroundColor: isDarkMode ? const Color(0xFF1E88E5) : const Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      print('Error marking request as completed: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Failed to mark as completed'),
          backgroundColor: isDarkMode ? Colors.red[700] : Colors.red,
        ),
      );
    }
  }
}