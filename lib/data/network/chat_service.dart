import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/chat/conversation_model.dart';
import 'package:temulapak_app/model/chat/message_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // === CONVERSATION MANAGEMENT ===

  /// Get or create conversation between user and merchant (only user can initiate)
  Future<String> getOrCreateConversation(String userId, String merchantId, MerchantModel merchant) async {
    try {
      final conversationId = _generateConversationId(userId, merchantId);
      final docRef = _firestore.collection('conversations').doc(conversationId);
      
      Logger.log("CHAT_SERVICE - Getting/Creating conversation: $conversationId");
      
      final doc = await docRef.get();
      if (!doc.exists) {
        // Get user data
        final user = await _userService.getCurrentUser();
        
        if (user == null) {
          throw Exception("User data not found");
        }
        
        // Create new conversation
        final conversation = ConversationModel(
          id: conversationId,
          participants: [userId, merchantId],
          participantDetails: {
            userId: ParticipantDetail(
              name: user.displayName ?? 'User',
              avatar: user.photoURL,
              role: 'user',
            ),
            merchantId: ParticipantDetail(
              name: merchant.merchantName ?? 'Merchant',
              avatar: merchant.merchantImgUrl,
              role: 'merchant',
            ),
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          merchantId: merchantId,
          unreadCount: {userId: 0, merchantId: 0},
          lastMessage: null,
        );
        
        await docRef.set(conversation.toMap());
        Logger.log("CHAT_SERVICE - Created new conversation: $conversationId");
      } else {
        Logger.log("CHAT_SERVICE - Conversation already exists: $conversationId");
      }
      
      return conversationId;
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error getting/creating conversation", error: e);
      rethrow;
    }
  }

  /// Get conversations where user is participant as USER
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    Logger.log("CHAT_SERVICE - Getting user conversations for: $userId");
    
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .where('participantDetails.$userId.role', isEqualTo: 'user')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      Logger.log("CHAT_SERVICE - User conversations snapshot: ${snapshot.docs.length} conversations");
      
      return snapshot.docs
          .map((doc) {
            try {
              return ConversationModel.fromMap(doc.data());
            } catch (e) {
              Logger.error("CHAT_SERVICE - Error parsing conversation ${doc.id}", error: e);
              return null;
            }
          })
          .where((conversation) => conversation != null)
          .cast<ConversationModel>()
          .toList();
    });
  }

  /// Get conversations where user is participant as MERCHANT
  Stream<List<ConversationModel>> getMerchantConversations(String merchantId) {
    Logger.log("CHAT_SERVICE - Getting merchant conversations for: $merchantId");
    
    return _firestore
        .collection('conversations')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      Logger.log("CHAT_SERVICE - Merchant conversations snapshot: ${snapshot.docs.length} conversations");
      
      return snapshot.docs
          .map((doc) {
            try {
              return ConversationModel.fromMap(doc.data());
            } catch (e) {
              Logger.error("CHAT_SERVICE - Error parsing merchant conversation ${doc.id}", error: e);
              return null;
            }
          })
          .where((conversation) => conversation != null)
          .cast<ConversationModel>()
          .toList();
    });
  }

  /// Get single conversation stream
  Stream<ConversationModel?> getConversation(String conversationId) {
    Logger.log("CHAT_SERVICE - Getting conversation stream: $conversationId");
    
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        try {
          return ConversationModel.fromMap(doc.data()!);
        } catch (e) {
          Logger.error("CHAT_SERVICE - Error parsing conversation $conversationId", error: e);
          return null;
        }
      }
      return null;
    });
  }

  // === MESSAGE MANAGEMENT ===

  /// Send message with 350 character limit
  Future<void> sendMessage(String conversationId, String text, String senderId) async {
    try {
      // Validate message
      if (text.trim().isEmpty) {
        throw Exception("Message cannot be empty");
      }
      
      if (text.length > 350) {
        throw Exception("Message too long (maximum 350 characters)");
      }
      
      final messageId = _firestore.collection('temp').doc().id;
      final timestamp = DateTime.now();
      
      Logger.log("CHAT_SERVICE - Sending message: $messageId");
      
      // Create message
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        text: text.trim(),
        timestamp: timestamp,
        type: 'text',
        readBy: [senderId], // Sender has read it
        isEdited: false,
      );
      
      // Batch write for atomicity
      final batch = _firestore.batch();
      
      // 1. Add message to subcollection
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);
      batch.set(messageRef, message.toMap());
      
      // 2. Update conversation
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      
      // Get receiver ID
      final receiverId = await _getReceiverId(conversationId, senderId);
      
      batch.update(conversationRef, {
        'lastMessage': {
          'text': text.trim(),
          'senderId': senderId,
          'timestamp': timestamp.toIso8601String(),
          'type': 'text',
        },
        'updatedAt': timestamp.toIso8601String(),
        // Increment unread count for receiver
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
      
      await batch.commit();
      Logger.log("CHAT_SERVICE - Message sent successfully");
      
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error sending message", error: e);
      rethrow;
    }
  }

  /// Get messages stream for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    Logger.log("CHAT_SERVICE - Getting messages stream for: $conversationId");
    
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Load last 100 messages
        .snapshots()
        .map((snapshot) {
      Logger.log("CHAT_SERVICE - Messages snapshot: ${snapshot.docs.length} messages");
      
      return snapshot.docs
          .map((doc) {
            try {
              return MessageModel.fromMap(doc.data());
            } catch (e) {
              Logger.error("CHAT_SERVICE - Error parsing message ${doc.id}", error: e);
              return null;
            }
          })
          .where((message) => message != null)
          .cast<MessageModel>()
          .toList();
    });
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      Logger.log("CHAT_SERVICE - Marking as read: $conversationId for $userId");
      
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'unreadCount.$userId': 0,
      });
      
      Logger.log("CHAT_SERVICE - Marked as read successfully");
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error marking as read", error: e);
      rethrow;
    }
  }

  // === UTILITY METHODS ===

  /// Generate consistent conversation ID
  String _generateConversationId(String userId, String merchantId) {
    // Always put user first, then merchant for consistency
    return "${userId}_${merchantId}";
  }

  /// Get receiver ID from conversation
  Future<String> _getReceiverId(String conversationId, String senderId) async {
    try {
      // Parse conversation ID: "user123_MRCN_merchant456"
      final parts = conversationId.split('_');
      if (parts.length >= 3) {
        final userId = parts[0];
        final merchantId = "${parts[1]}_${parts[2]}"; // MRCN_merchant456
        
        return senderId == userId ? merchantId : userId;
      } else {
        // Fallback: get from conversation document
        final doc = await _firestore.collection('conversations').doc(conversationId).get();
        if (doc.exists) {
          final participants = List<String>.from(doc.data()!['participants'] ?? []);
          return participants.firstWhere((id) => id != senderId, orElse: () => '');
        }
        throw Exception("Cannot determine receiver ID");
      }
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error getting receiver ID", error: e);
      rethrow;
    }
  }

  /// Get other participant details from conversation
  ParticipantDetail? getOtherParticipant(ConversationModel conversation, String currentUserId) {
    try {
      final otherParticipantId = conversation.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      if (otherParticipantId.isNotEmpty) {
        return conversation.participantDetails[otherParticipantId];
      }
      return null;
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error getting other participant", error: e);
      return null;
    }
  }

  /// Get customer participant (for merchant view)
  ParticipantDetail? getCustomerParticipant(ConversationModel conversation) {
    try {
      final customerEntry = conversation.participantDetails.entries.firstWhere(
        (entry) => entry.value.role == 'user',
        orElse: () => MapEntry('', ParticipantDetail(name: '', role: 'user')),
      );
      
      return customerEntry.key.isNotEmpty ? customerEntry.value : null;
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error getting customer participant", error: e);
      return null;
    }
  }
}