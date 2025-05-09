import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Validate email domain specifically for your college
// Validate email domain specifically for your college
  bool isValidCollegeEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    final validDomains = ['@rguktn.ac.in', '@rguktsklm.ac.in'];

    // Check for specific allowed test email
    if (trimmedEmail == 'panindiatrip1464@gmail.com') {
      return true;
    }

    // Check for allowed domains
    return validDomains.any((domain) => trimmedEmail.endsWith(domain));
  }

  // Stream to check authentication state
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Google Sign-In Method
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to clear any previous sessions
      await _googleSignIn.signOut();

      // Force account selection to prevent automatic reuse of invalid account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled');
        return null;
      }

      // Debug log: Print the email received from Google Sign-In
      print('Received email from Google Sign-In: ${googleUser.email}');

      // Validate college email domain
      if (!isValidCollegeEmail(googleUser.email)) {
        print('Invalid college email: ${googleUser.email}');
        // Sign out to prevent the invalid account from being cached
        await _googleSignIn.signOut();
        throw Exception('Invalid college email. Please use an @rguktn.ac.in or @rguktsklm.ac.in email.');
      }

      // Rest of your code remains the same
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user != null) {
        await _storeUserDetails(user);
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      // Ensure we're signed out on any error
      await _googleSignIn.signOut();
      rethrow;
    }
  }



  // Store User Details in Firestore
  Future<void> _storeUserDetails(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Store or update user details in Firestore
      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
      print('User details stored successfully');
    } catch (e) {
      print('Error storing user details: $e');
    }
  }

  // Sign Out Method
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}