import 'package:cloud_firestore/cloud_firestore.dart';

class FCMTokenModel {
  final String userId;
  final String fcmToken;
  final DateTime lastUpdated;

  FCMTokenModel({
    required this.userId,
    required this.fcmToken,
    required this.lastUpdated,
  });

  factory FCMTokenModel.fromFirestore(Map<String, dynamic> map) {
    return FCMTokenModel(
      userId: map['userId'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fcmToken': fcmToken,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}