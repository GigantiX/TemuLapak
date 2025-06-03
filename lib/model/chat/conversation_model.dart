class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, ParticipantDetail> participantDetails;
  final LastMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String merchantId;
  final Map<String, int> unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.merchantId,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantDetails': participantDetails.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'lastMessage': lastMessage?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'merchantId': merchantId,
      'unreadCount': unreadCount,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantDetails: Map<String, ParticipantDetail>.from(
        (map['participantDetails'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key,
            ParticipantDetail.fromMap(value as Map<String, dynamic>),
          ),
        ),
      ),
      lastMessage: map['lastMessage'] != null
          ? LastMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      merchantId: map['merchantId'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, ParticipantDetail>? participantDetails,
    LastMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? merchantId,
    Map<String, int>? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      merchantId: merchantId ?? this.merchantId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ParticipantDetail {
  final String name;
  final String? avatar;
  final String role; // "user" or "merchant"

  ParticipantDetail({
    required this.name,
    this.avatar,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatar': avatar,
      'role': role,
    };
  }

  factory ParticipantDetail.fromMap(Map<String, dynamic> map) {
    return ParticipantDetail(
      name: map['name'] ?? '',
      avatar: map['avatar'],
      role: map['role'] ?? 'user',
    );
  }

  ParticipantDetail copyWith({
    String? name,
    String? avatar,
    String? role,
  }) {
    return ParticipantDetail(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }
}

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String type;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      type: map['type'] ?? 'text',
    );
  }

  LastMessage copyWith({
    String? text,
    String? senderId,
    DateTime? timestamp,
    String? type,
  }) {
    return LastMessage(
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}