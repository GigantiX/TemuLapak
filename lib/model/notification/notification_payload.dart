class NotificationPayload {
  final String receiverId;
  final String senderId;
  final String senderName;
  final String message;
  final String conversationId;

  NotificationPayload({
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.conversationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'conversationId': conversationId,
    };
  }

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      receiverId: json['receiverId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      conversationId: json['conversationId'] ?? '',
    );
  }
}