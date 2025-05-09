import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lazycat/viewModel/requestModel.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new request
  Future<String?> createRequest(RequestModel request) async {
    try {
      // Ensure user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to create a request');
      }

      // Create a new request with the current user's ID and FCM token
      final requestWithUserId = RequestModel(
        requestType: request.requestType,
        itemDescription: request.itemDescription,
        fromLocation: request.fromLocation,
        toLocation: request.toLocation,
        urgencyLevel: request.urgencyLevel,
        urgencyTiming: request.urgencyTiming,
        paymentMethod: request.paymentMethod,
        reward: request.reward,
        status: 'pending',
        userId: currentUser.uid,
        fcmToken: request.fcmToken, // Add this line
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection('requests')
          .add(requestWithUserId.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating request: $e');
      return null;
    }
  }


  // Get all active requests for the current user
  Stream<List<RequestModel>> getUserActiveRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Update request status
  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore
          .collection('requests')
          .doc(requestId)
          .update({'status': newStatus});
      return true;
    } catch (e) {
      print('Error updating request status: $e');
      return false;
    }
  }

  // Delete a request by its ID
  Future<bool> deleteRequest(String requestId) async {
    try {
      // Ensure user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete a request');
      }

      // Fetch the request to ensure it belongs to the current user
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final requestData = requestDoc.data();

      if (requestData == null) {
        throw Exception('Request not found');
      }

      if (requestData['userId'] != currentUser.uid) {
        throw Exception('You are not authorized to delete this request');
      }

      // Delete the request
      await _firestore.collection('requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }
}