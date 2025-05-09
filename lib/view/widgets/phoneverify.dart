import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class PhoneNumberDialog extends StatefulWidget {
  final User user;

  const PhoneNumberDialog({Key? key, required this.user}) : super(key: key);

  @override
  _PhoneNumberDialogState createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<PhoneNumberDialog> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showWelcomeAnimation = false; // New state variable

  @override
  Widget build(BuildContext context) {
    // If welcome animation is showing, return the animation overlay
    if (_showWelcomeAnimation) {
      return WelcomeAnimationOverlay();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(
        'Complete Your Profile',
        style: GoogleFonts.quicksand(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide your phone number to continue',
              style: GoogleFonts.quicksand(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),

            TextFormField(
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
            SizedBox(height: 10),
            Text(
              'Note: Your phone number is kept private and can be changed later in your profile settings.',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _savePhoneNumber,
          child: Text(
            'Save',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4ECDC4),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _savePhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save phone number to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'phoneNumber': '+91${_phoneController.text.trim()}',
        });

        // Show welcome animation
        setState(() {
          _showWelcomeAnimation = true;
        });

        // Automatically navigate away after animation completes
        Future.delayed(Duration(seconds: 3), () {
          Navigator.of(context).pop(true);
        });
      } catch (e) {
        // Show error if saving fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save phone number: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

// Separate widget for welcome animation
class WelcomeAnimationOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Lottie.asset(
          'assets/wel.json', // Path to your Lottie animation
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          repeat: false, // Play only once
        ),
      ),
    );
  }
}

// Extension method to check phone number
extension PhoneNumberCheck on User {
  Future<bool> hasPhoneNumber() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return doc.exists &&
          doc.data()?['phoneNumber'] != null &&
          doc.data()!['phoneNumber'].toString().isNotEmpty;
    } catch (e) {
      print('Error checking phone number: $e');
      return false;
    }
  }
}