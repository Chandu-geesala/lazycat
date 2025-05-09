import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String? id;
  final String? fcmToken;
  final String requestType;
  final String itemDescription;
  final String fromLocation;
  final String toLocation;
  final String urgencyLevel;
  final String urgencyTiming;
  final String paymentMethod;
  final double? reward;
  final String status;
  final DateTime createdAt;
  final String? userId;

  // To track which user created the request

  RequestModel({
    this.id,
    this.fcmToken,
    required this.requestType,
    required this.itemDescription,
    required this.fromLocation,
    required this.toLocation,
    required this.urgencyLevel,
    required this.urgencyTiming,
    required this.paymentMethod,
    this.reward,
    this.status = 'pending',
    DateTime? createdAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'fcmToken': fcmToken,
      'requestType': requestType,
      'itemDescription': itemDescription,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'urgencyLevel': urgencyLevel,
      'urgencyTiming': urgencyTiming,
      'paymentMethod': paymentMethod,
      'reward': reward,
      'status': status,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  // Create from Firestore document
  factory RequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RequestModel(
      id: documentId,
      fcmToken: map['fcmToken'],
      requestType: map['requestType'],
      itemDescription: map['itemDescription'],
      fromLocation: map['fromLocation'],
      toLocation: map['toLocation'],
      urgencyLevel: map['urgencyLevel'],
      urgencyTiming: map['urgencyTiming'],
      paymentMethod: map['paymentMethod'],
      reward: map['reward'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'],
    );
  }
}