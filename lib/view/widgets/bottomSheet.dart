import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lazycat/view/requestForm.dart';
import 'package:lazycat/viewModel/authService.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> request;
  final ScrollController controller;

  const RequestDetailsSheet({
    Key? key,
    required this.docId,
    required this.request,
    required this.controller,
  }) : super(key: key);

  @override
  _RequestDetailsSheetState createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<RequestDetailsSheet> {
  late Map<String, dynamic> _editableRequest;
  bool _isEditable = true;
  bool _isLoading = true;
  Map<String, dynamic>? _acceptorDetails;

  @override
  void initState() {
    super.initState();
    _editableRequest = Map<String, dynamic>.from(widget.request);
    _checkEditability();
    _fetchAcceptorDetails();
  }

  Future<void> _fetchAcceptorDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if the request is accepted and has an acceptedBy field
      if (_editableRequest['status'] == 'Accepted' && _editableRequest['acceptedBy'] != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_editableRequest['acceptedBy'])
            .get();

        if (userDoc.exists) {
          setState(() {
            _acceptorDetails = userDoc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching acceptor details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkEditability() {
    _isEditable = widget.request['status'] == 'pending';
  }

  void _cancelRequest() async {
    try {
      if (_editableRequest['status'] == 'pending') {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request cannot be cancelled at this stage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching dialer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current brightness mode from the system
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      // Background color based on theme
      color: isDarkMode ? const Color(0xFF121212) : Colors.white,
      padding: EdgeInsets.all(16),
      child: ListView(
        controller: widget.controller,
        children: [
          Text(
            'Request Details',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // Text color based on theme
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          // Detailed Request Information
          _buildDetailRow('Request Type', _editableRequest['requestType'], isDarkMode),
          _buildDetailRow('Item Description', _editableRequest['itemDescription'], isDarkMode),
          _buildDetailRow('From Location', _editableRequest['fromLocation'], isDarkMode),
          _buildDetailRow('To Location', _editableRequest['toLocation'], isDarkMode),
          _buildDetailRow('Urgency Level', _editableRequest['urgencyLevel'], isDarkMode),
          _buildDetailRow('Urgency Timing', _editableRequest['urgencyTiming'], isDarkMode),
          _buildDetailRow('Payment Method', _editableRequest['paymentMethod'], isDarkMode),
          _buildDetailRow('Status', _editableRequest['status'], isDarkMode),

          SizedBox(height: 20),

          // Acceptor Details Section with Improved Error Handling
          if (_editableRequest['status'] == 'Accepted') ...[
            _buildAcceptorSection(isDarkMode),
          ],

          SizedBox(height: 20),

          // Conditional Cancel Button
          if (_isEditable)
            ElevatedButton(
              onPressed: _cancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE31149),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Cancel Request',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptorSection(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      );
    }

    if (_acceptorDetails == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Dark mode support for the "not available" container
          color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Acceptor details not available',
          style: GoogleFonts.quicksand(
            // Text color based on theme
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Dark mode colors for the acceptor details container
        color: isDarkMode ? Color(0xFF0A3622) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.green.shade800 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acceptor Details',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // Header color based on theme
              color: isDarkMode ? Colors.green.shade300 : Colors.green.shade800,
            ),
          ),
          SizedBox(height: 8),

          _buildHighlightedDetailRow(
            'Name',
            _acceptorDetails?['name'] ?? 'Not Available',
            Icons.person,
            isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
          ),

          _buildHighlightedDetailRow(
            'Phone',
            _acceptorDetails?['phoneNumber'] ?? 'Not Available',
            Icons.phone,
            isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
          ),

          _buildHighlightedDetailRow(
            'Email',
            _acceptorDetails?['email'] ?? 'Not Available',
            Icons.email,
            isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
          ),

          // Call Button
          if (_acceptorDetails?['phoneNumber'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ElevatedButton.icon(
                onPressed: () => _launchDialer(_acceptorDetails!['phoneNumber']),
                icon: Icon(Icons.call, color: Colors.white),
                label: Text(
                  'Call Acceptor',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  // Button color slightly adjusted for dark mode
                  backgroundColor: isDarkMode
                      ? Colors.green.shade800
                      : Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightedDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: GoogleFonts.quicksand(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              // Label text color based on theme
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            value?.toString() ?? 'Not specified',
            style: GoogleFonts.quicksand(
              // Value text color based on theme
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}