import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lazycat/viewModel/requestModel.dart';
import 'package:lazycat/viewModel/request SErvice.dart';

import '../utils/notificationService.dart';
import '../utils/tokenUtils.dart';
import 'home.dart';

class CreateRequestScreen extends StatefulWidget {
  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  // Add loading state variable
  bool _isLoading = false;

  // Check if dark mode is enabled
  bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // Request Type Options
  final List<Map<String, dynamic>> _requestTypes = [
    {
      'title': 'Food Delivery',
      'icon': HeroIcon(HeroIcons.shoppingBag),
      'color': Color(0xFFFF6B6B),
    },
    {
      'title': 'Package Pickup',
      'icon': HeroIcon(HeroIcons.truck),
      'color': Color(0xFF4ECDC4),
    },
    {
      'title': 'Item Retrieval',
      'icon': HeroIcon(HeroIcons.documentText),
      'color': Color(0xFF45B7D1),
    },
    {
      'title': 'Other',
      'icon': HeroIcon(HeroIcons.plusCircle),
      'color': Color(0xFFFFA07A),
    }
  ];

  // Form Controllers
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();

  // Urgency Options with Estimated Timings
  final List<Map<String, dynamic>> _urgencyLevels = [
    {
      'level': 'Not Urgent',
      'timing': 'Within 1-3 hours',
      'color': Colors.green
    },
    {
      'level': 'Somewhat Urgent',
      'timing': 'Within 1 hour',
      'color': Colors.orange
    },
    {
      'level': 'Very Urgent',
      'timing': 'Within 30 mins',
      'color': Colors.red
    }
  ];

  // Payment Method Options
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'method': 'Make a Payment',
      'description': 'Settle your service fees effortlessly',
      'icon': HeroIcon(HeroIcons.creditCard)
    },
    {
      'method': 'Community Support',
      'description': 'Offer support through non-monetary means',
      'icon': HeroIcon(HeroIcons.heart)
    }
  ];

  // Selected Options
  String _selectedRequestType = 'Food Delivery';
  Map<String, dynamic> _selectedUrgency = {};
  String _selectedPaymentMethod = 'Make a Payment';
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    // Set default urgency
    _selectedUrgency = _urgencyLevels[0];
  }

  @override
  Widget build(BuildContext context) {
    // Get theme mode
    final darkMode = isDarkMode(context);

    // Define colors based on theme
    final backgroundColor = darkMode ? Color(0xFF121212) : Color(0xFFF4F7F9);
    final textColor = darkMode ? Colors.white : Colors.black;
    final secondaryTextColor = darkMode ? Colors.white70 : Colors.black87;
    final tertiaryTextColor = darkMode ? Colors.white54 : Colors.black54;
    final cardColor = darkMode ? Color(0xFF1E1E1E) : Colors.white;
    final unselectedColor = darkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Request',
          style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 24
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Type Selection
            Text(
              'Select Request Type',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor
              ),
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _requestTypes.map((type) =>
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRequestType = type['title'];
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRequestType == type['title']
                              ? type['color'].withOpacity(0.3)
                              : unselectedColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            HeroIcon(
                              (type['icon'] as HeroIcon).icon,
                              color: darkMode ? Colors.white : Colors.black87,
                            ),
                            SizedBox(width: 10),
                            Text(
                              type['title'],
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.bold,
                                  color: secondaryTextColor
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ).toList(),
              ),
            ),

            SizedBox(height: 20),

            // Item Description
            _buildTextField(
              controller: _itemDescriptionController,
              label: 'Item Description',
              hint: 'What do you need to be picked up?',
              icon: HeroIcon(HeroIcons.documentText, color: tertiaryTextColor),
              darkMode: darkMode,
              textColor: textColor,
              cardColor: cardColor,
              hintColor: darkMode ? Colors.white38 : Colors.black45,
            ),

            SizedBox(height: 20),

            // From Location
            _buildTextField(
              controller: _fromLocationController,
              label: 'Pickup Location',
              hint: 'Where is the item located?',
              icon: HeroIcon(HeroIcons.mapPin, color: tertiaryTextColor),
              darkMode: darkMode,
              textColor: textColor,
              cardColor: cardColor,
              hintColor: darkMode ? Colors.white38 : Colors.black45,
            ),

            SizedBox(height: 20),

            // To Location
            _buildTextField(
              controller: _toLocationController,
              label: 'Delivery Location',
              hint: 'Where should it be delivered?',
              icon: HeroIcon(HeroIcons.home, color: tertiaryTextColor),
              darkMode: darkMode,
              textColor: textColor,
              cardColor: cardColor,
              hintColor: darkMode ? Colors.white38 : Colors.black45,
            ),

            SizedBox(height: 20),

            // Urgency Level with Timing
            Text(
              'Urgency Level',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _urgencyLevels.map((urgency) =>
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUrgency = urgency;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedUrgency == urgency
                              ? urgency['color'].withOpacity(0.3)
                              : unselectedColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urgency['level'],
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.bold,
                                color: secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              urgency['timing'],
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                color: tertiaryTextColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ).toList(),
              ),
            ),

            SizedBox(height: 20),

            // Payment Method Selection
            Text(
              'Payment Method',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _paymentMethods.map((method) =>
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method['method'];
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMethod == method['method']
                              ? Colors.teal.withOpacity( 0.3)
                              : unselectedColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                HeroIcon(
                                  (method['icon'] as HeroIcon).icon,
                                  color: darkMode ? Colors.white : Colors.black87,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  method['method'],
                                  style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.bold,
                                    color: secondaryTextColor,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              method['description'],
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                color: tertiaryTextColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ).toList(),
              ),
            ),

            SizedBox(height: 20),

            // Reward/Tip Input
            if (_selectedPaymentMethod != 'Community Support')
              _buildTextField(
                controller: _rewardController,
                label: 'Carrier Reward',
                hint: 'How much will you offer? (Optional)',
                icon: HeroIcon(HeroIcons.currencyRupee, color: tertiaryTextColor),
                keyboardType: TextInputType.number,
                darkMode: darkMode,
                textColor: textColor,
                cardColor: cardColor,
                hintColor: darkMode ? Colors.white38 : Colors.black45,
              ),

            SizedBox(height: 30),

            // Submit Button - Updated to show loading state
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)
                    )
                ),
                child: _isLoading ?
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white
                      ),
                    ),
                  ],
                )
                    : Text(
                  'Post Request',
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _submitRequest() async {
    // Set loading state to true
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate input fields
      final fcmToken = await TokenUtils.getFCMToken();
      print('FCM Token being used: $fcmToken');

      if (_itemDescriptionController.text.isEmpty) {
        _showValidationError('Please provide item description');
        return;
      }

      if (_fromLocationController.text.isEmpty) {
        _showValidationError('Please specify pickup location');
        return;
      }

      if (_toLocationController.text.isEmpty) {
        _showValidationError('Please specify delivery location');
        return;
      }

      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showValidationError('Please log in to create a request');
        return;
      }

      // Store these values before clearing any fields
      final fromLocation = _fromLocationController.text;
      final toLocation = _toLocationController.text;
      final selectedRequestType = _selectedRequestType;
      final urgencyLevel = _selectedUrgency['level'];

      // Prepare request data
      final request = RequestModel(
        fcmToken: fcmToken,
        requestType: selectedRequestType,
        itemDescription: _itemDescriptionController.text,
        fromLocation: fromLocation,
        toLocation: toLocation,
        urgencyLevel: urgencyLevel,
        urgencyTiming: _selectedUrgency['timing'],
        paymentMethod: _selectedPaymentMethod,
        reward: _selectedPaymentMethod != 'Community Support' && _rewardController.text.isNotEmpty
            ? double.parse(_rewardController.text)
            : null,
      );

      // Try to create the request
      final requestId = await _requestService.createRequest(request);

      if (requestId != null) {
        // Prepare notification content
        final notificationTitle = "New $selectedRequestType Request";

        // Create a concise description for the notification
        String notificationBody = "From: ${_shortenLocation(fromLocation)} to ${_shortenLocation(toLocation)}";

        if (urgencyLevel == 'Very Urgent') {
          notificationBody = "URGENT: $notificationBody";
        }

        // Add additional data for deep linking
        Map<String, dynamic> additionalData = {
          'requestId': requestId,
          'requestType': selectedRequestType,
          'route': 'request_details',
        };

        // Send notification to 'all' topic
        await NotificationService().sendNotificationToTopic(
          topic: 'all',
          title: notificationTitle,
          body: notificationBody,
          data: additionalData,
        );

        // ONLY NOW clear text fields, AFTER sending the notification
        _itemDescriptionController.clear();
        _fromLocationController.clear();
        _toLocationController.clear();
        _rewardController.clear();

        // Show success dialog
        _showSuccessDialog();
      } else {
        // Show error if request creation failed
        _showValidationError('Failed to create request. Please try again.');
      }
    } catch (e) {
      // Handle any exceptions that might occur
      _showValidationError('An error occurred: ${e.toString()}');
    } finally {
      // Set loading state back to false regardless of outcome
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to shorten location text for notifications
  String _shortenLocation(String location) {
    // Limit location to first 15 characters followed by ellipsis if longer
    if (location.length > 15) {
      return location.substring(0, 15) + '...';
    }
    return location;
  }

  // Show validation error
  void _showValidationError(String message) {
    // Reset loading state when showing an error
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.quicksand(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog() {
    // Make sure loading state is reset
    setState(() {
      _isLoading = false;
    });

    final darkMode = isDarkMode(context);
    final dialogBackgroundColor = darkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = darkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor,
        title: Text(
          'Request Created',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          'Your request has been successfully posted!',
          style: GoogleFonts.quicksand(
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close current dialog first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Text(
              'OK',
              style: GoogleFonts.quicksand(
                color: const Color(0xFF4ECDC4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Widget icon,
    required bool darkMode,
    required Color textColor,
    required Color cardColor,
    required Color hintColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: darkMode ? Colors.black26 : Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2)
                )
              ]
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.quicksand(color: hintColor),
                prefixIcon: icon,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15)
            ),
          ),
        )
      ],
    );
  }
}