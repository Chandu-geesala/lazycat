import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lazycat/view/widgets/bottomSheet.dart';

import '../viewModel/authService.dart';

class AccountPage extends StatefulWidget {
  final User? user;

  const AccountPage({Key? key, required this.user}) : super(key: key);



  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {




  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  final _suggestionController = TextEditingController();
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumber();
  }

  Future<void> _fetchPhoneNumber() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user?.uid)
          .get();

      setState(() {
        _phoneNumber = doc.data()?['phoneNumber'];
      });
    } catch (e) {
      print('Error fetching phone number: $e');
    }
  }

  void _showPhoneNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Phone Number',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content:    TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}')),
          ],
          decoration: InputDecoration(
            prefixText: '+91 ',
            hintText: 'Enter 10-digit mobile number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length != 10) {
              return 'Please enter a valid 10-digit number';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand()),
          ),
          ElevatedButton(
            onPressed: _savePhoneNumber,
            child: Text('Save', style: GoogleFonts.quicksand()),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhoneNumber() async {
    if (_phoneController.text.length == 10) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user?.uid)
            .update({
          'phoneNumber': '+91${_phoneController.text.trim()}',
        });

        setState(() {
          _phoneNumber = '+91${_phoneController.text.trim()}';
        });

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save phone number: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 10-digit number')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {

    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;


    return SingleChildScrollView(

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,



          children: [
            // User Profile Section
            _buildUserProfileHeader(context),

            SizedBox(height: 24),

            // User Details Card
            _buildUserDetailsCard(),

            SizedBox(height: 24),

            // Rewards Section
            _buildRewardsSection(),


            SizedBox(height: 24),

            Text(
              'Your Previous Requests',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),


            SizedBox(height: 16),

            // Active Requests Stream Builder
            _buildPreviousRequestsList(context),


          ],
        ),
      ),
    );
  }




  Widget _buildUserProfileHeader(BuildContext context) {
    // Detect system theme automatically
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    // Define colors based on system theme
    final backgroundColor = isDarkMode ? Color(0xFF1E3A8A) : Color(0xFF4ECDC4);
    final gradientEndColor = isDarkMode ? Color(0xFF1E40AF) : Color(0xFF2AB7CA);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, gradientEndColor],
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture with enhanced styling
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              backgroundImage: widget.user?.photoURL != null
                  ? NetworkImage(widget.user!.photoURL!)
                  : null,
              child: widget.user?.photoURL == null
                  ? Icon(Icons.person, size: 50, color: isDarkMode ? Colors.grey[400] : Colors.grey[700])
                  : null,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user?.displayName ?? 'User Name',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.user?.email ?? 'user@example.com',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildUserDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,


          children: [
            Text(
              'Account Details',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),


            SizedBox(height: 16),

            // Phone Number Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [


                  Text(
                    'Phone Number',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _phoneNumber ?? 'Not Added',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: _phoneNumber == null
                              ? Colors.red
                              : Colors.grey[700],
                        ),
                      ),
                      SizedBox(width: 0.1),
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: _showPhoneNumberDialog,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildDetailRow('Email Verified',
                widget.user?.emailVerified == true ? 'Yes' : 'No'),
            _buildDetailRow('Registration Date',
                widget.user?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Existing _buildRewardsSection remains the same
  Widget _buildRewardsSection() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;


    return FutureBuilder<int>(
      future: _calculateRewards(),
      builder: (context, snapshot) {
        int totalPoints = snapshot.data ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Card(
                elevation: 4, // Adds shadow to make it look like a card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for a modern look
                ),
                child: InkWell(
                  onTap: _showSuggestionDialog, // Handle button press
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Ensures the content is compact
                      children: [
                        Icon(Icons.feedback_outlined, size: 20), // Feedback icon
                        SizedBox(width: 8), // Spacing between icon and text
                        Text(
                          'Submit Suggestion',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Adjust font size for better readability
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Text(
              'Your Rewards',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            // Rewards Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total Points',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$totalPoints',
                      style: GoogleFonts.quicksand(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(height: 16),

            // Active Requests Stream Builder




            // TODO: Add list of past rewards and point transactions
          ],
        );
      },
    );
  }



  Future<void> _submitSuggestion() async {
    final suggestion = _suggestionController.text.trim();

    if (suggestion.isNotEmpty) {
      try {
        // Submit suggestion to Firestore
        await FirebaseFirestore.instance.collection('suggestions').add({
          'userId': widget.user?.uid,
          'userName': widget.user?.displayName ?? 'Anonymous',
          'suggestion': suggestion,
          'timestamp': FieldValue.serverTimestamp(),

        });

        // Clear the suggestion controller
        _suggestionController.clear();

        // Close the dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thank you for your suggestion!',
              style: GoogleFonts.quicksand(),
            ),
          ),
        );
      } catch (e) {
        // Show error message if submission fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit suggestion: $e',
              style: GoogleFonts.quicksand(),
            ),
          ),
        );
      }
    }
  }


  void _showSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Submit Suggestion',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: TextFormField(
          controller: _suggestionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your suggestion or feedback...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a suggestion';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.quicksand()),
          ),
          ElevatedButton(
            onPressed: _submitSuggestion,
            child: Text('Submit', style: GoogleFonts.quicksand()),
          ),
        ],
      ),
    );
  }

  Future<int> _calculateRewards() async {
    try {
      final userId = widget.user?.uid;
      if (userId == null) return 0;

      // Fetch posted requests
      final postedRequestsQuery = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: userId)
          .get();

      int postedRequestPoints = postedRequestsQuery.docs.length * 10;

      // Fetch accepted requests
      final acceptedRequestsQuery = await FirebaseFirestore.instance
          .collection('requests')
          .where('acceptedBy', isEqualTo: userId)
          .get();

      int acceptedRequestPoints = acceptedRequestsQuery.docs.length * 5;

      // Calculate total points
      int totalPoints = postedRequestPoints + acceptedRequestPoints;

      // Update or create rewards document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'rewards': {
          'totalPoints': totalPoints,
          'postedRequestPoints': postedRequestPoints,
          'acceptedRequestPoints': acceptedRequestPoints,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      return totalPoints;
    } catch (e) {
      print('Error calculating rewards: $e');
      return 0;
    }
  }

  bool _isAtSameDayAs(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }


  Widget _buildPreviousRequestsList(BuildContext context) {
    final String? currentUserId = _authService.getCurrentUser()?.uid;

    if (currentUserId == null) {
      return Center(
        child: Text(
          'Please log in to view requests',
          style: GoogleFonts.quicksand(
            color: Colors.grey,
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
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No Previous requests',
              style: GoogleFonts.quicksand(
                color: Colors.grey,
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
            return _buildRequestCard(context, doc.id, request);
          }).toList(),
        );
      },
    );
  }


  void _showRequestDetailsBottomSheet(BuildContext context, String docId, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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



  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> request) {
    bool isAccepted = request['status'] == 'Accepted';
    bool isPending = request['status'] == 'pending';
    bool isCompleted = request['status'] == 'Completed';

    // Check if request is expired (not from today)
    bool isExpired = false;
    if (request.containsKey('createdAt')) {
      final Timestamp createdAtTimestamp = request['createdAt'];
      final DateTime createdAt = createdAtTimestamp.toDate();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      isExpired = !_isAtSameDayAs(createdAt, today) && !isCompleted;
    }

    return GestureDetector(
      onTap: () {
        _showRequestDetailsBottomSheet(context, docId, request);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isExpired
              ? Color(0xFFf0f0f0) // Light gray for expired
              : (isAccepted
              ? Color(0xFFE6F3E6)
              : (isPending ? Color(0xFFFFF4E5) : Colors.white)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: isExpired
              ? Border.all(color: Colors.grey.shade400, width: 1.5)
              : (isAccepted
              ? Border.all(color: Colors.green.shade300, width: 1.5)
              : (isPending ? Border.all(color: Colors.orange.shade300, width: 1.5) : null)),
        ),
        child: ListTile(
          leading: Stack(
            children: [
              HeroIcon(
                isExpired
                    ? HeroIcons.exclamationCircle // Exclamation icon for expired
                    : (isAccepted
                    ? HeroIcons.shoppingBag
                    : (isPending ? HeroIcons.clock : HeroIcons.shoppingBag)),
                color: isExpired
                    ? Colors.grey.shade600
                    : (isAccepted
                    ? Colors.green
                    : (isPending ? Colors.orange : Colors.grey)),
              ),
              if (isPending && !isExpired)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
              color: isExpired ? Colors.grey.shade700 : (isPending ? Colors.orange.shade700 : null),
              decoration: isExpired ? TextDecoration.lineThrough : null, // Strikethrough for expired
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['itemDescription'] ?? 'No description',
                style: GoogleFonts.quicksand(
                  color: isExpired ? Colors.grey.shade600 : (isPending ? Colors.orange.shade600 : null),
                ),
              ),
              SizedBox(height: 4),
              if (isExpired) ...[
                Text(
                  'Expired',
                  style: GoogleFonts.quicksand(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ] else if (isAccepted) ...[
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(request['acceptedBy']).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading accepter details...',
                        style: GoogleFonts.quicksand(
                          color: Colors.green.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final accepterData = userSnapshot.data!.data() as Map<String, dynamic>;
                      return Text(
                        'Accepted by: ${accepterData['name'] ?? 'Unknown'} | ${accepterData['phoneNumber'] ?? 'No phone'}',
                        style: GoogleFonts.quicksand(
                          color: Colors.green.shade700,
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
              if (isExpired)
                Text(
                  'Expired',
                  style: GoogleFonts.quicksand(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else if (isAccepted)
                Text(
                  'Order Accepted',
                  style: GoogleFonts.quicksand(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else if (isPending)
                  Text(
                    'Pending',
                    style: GoogleFonts.quicksand(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              Icon(
                Icons.chevron_right,
                color: isExpired ? Colors.grey.shade600 : (isPending ? Colors.orange.shade700 : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}