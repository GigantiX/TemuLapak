import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String message;
  final String conversationId;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.conversationId,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      conversationId: map['conversationId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'conversationId': conversationId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  String toString() {
    return 'NotificationModel(senderName: $senderName, message: $message)';
  }
}