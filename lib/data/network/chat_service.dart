import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/model/chat/conversation_model.dart';
import 'package:temulapak_app/model/chat/message_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/notification/notification_payload.dart';
import 'package:temulapak_app/utils/logger.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService.instance;

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
        
        // FIXED: Ensure proper participant details structure
        final participantDetails = <String, ParticipantDetail>{
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
        };
        
        Logger.log("CHAT_SERVICE - Creating participant details: $participantDetails");
        
        // Create new conversation
        final conversation = ConversationModel(
          id: conversationId,
          participants: [userId, merchantId],
          participantDetails: participantDetails,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          merchantId: merchantId,
          unreadCount: {userId: 0, merchantId: 0},
          lastMessage: null,
        );
        
        final conversationData = conversation.toMap();
        Logger.log("CHAT_SERVICE - Conversation data to save: $conversationData");
        
        await docRef.set(conversationData);
        Logger.log("CHAT_SERVICE - Created new conversation: $conversationId");
      } else {
        Logger.log("CHAT_SERVICE - Conversation already exists: $conversationId");
        
        // FIXED: Verify and update participant details if needed
        final existingData = doc.data()!;
        final existingParticipantDetails = existingData['participantDetails'] as Map<String, dynamic>?;
        
        if (existingParticipantDetails == null || 
            !existingParticipantDetails.containsKey(userId) ||
            !existingParticipantDetails.containsKey(merchantId)) {
          
          Logger.log("CHAT_SERVICE - Updating missing participant details for existing conversation");
          
          // Get user data for update
          final user = await _userService.getCurrentUser();
          
          final updatedParticipantDetails = <String, dynamic>{
            ...?existingParticipantDetails,
            userId: {
              'name': user?.displayName ?? 'User',
              'avatar': user?.photoURL,
              'role': 'user',
            },
            merchantId: {
              'name': merchant.merchantName ?? 'Merchant',
              'avatar': merchant.merchantImgUrl,
              'role': 'merchant',
            },
          };
          
          await docRef.update({
            'participantDetails': updatedParticipantDetails,
          });
          
          Logger.log("CHAT_SERVICE - Updated participant details for existing conversation");
        }
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
    
    // FIXED: Simplified query to avoid complex composite index
    // We'll filter by participants array and then filter by role in the stream map
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      Logger.log("CHAT_SERVICE - User conversations snapshot: ${snapshot.docs.length} conversations");
      
      return snapshot.docs
          .map((doc) {
            try {
              final conversation = ConversationModel.fromMap(doc.data());
              
              // FIXED: Filter by role after fetching - check if user is participating as 'user' role
              final userDetail = conversation.participantDetails[userId];
              if (userDetail != null && userDetail.role == 'user') {
                return conversation;
              }
              return null; // Skip this conversation if user is not participating as 'user'
              
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

  /// Send message with 350 character limit and notification
  Future<void> sendMessage(String conversationId, String text, String senderRawUid) async {
    try {
      // Validate message
      if (text.trim().isEmpty) throw Exception("Message cannot be empty");
      if (text.length > 350) throw Exception("Message too long (maximum 350 characters)");

      final timestamp = DateTime.now();
      Logger.log("CHAT_SERVICE - Sending message from raw UID: $senderRawUid");

      // 1. Fetch the conversation document to get context
      final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!convDoc.exists) {
        throw Exception("Conversation not found");
      }
      final conversation = ConversationModel.fromMap(convDoc.data()!);

      // 2. Determine sender and receiver roles for THIS conversation
      // A user is the merchant for this chat if their prefixed UID matches the conversation's merchantId
      final isSenderTheMerchant = conversation.merchantId == "MRCN_${senderRawUid}";

      final String senderParticipantId;
      final String receiverParticipantId;

      if (isSenderTheMerchant) {
        senderParticipantId = conversation.merchantId;
        // The receiver is the other participant in the list
        receiverParticipantId = conversation.participants.firstWhere((p) => p != senderParticipantId);
      } else {
        senderParticipantId = senderRawUid;
        receiverParticipantId = conversation.merchantId;
      }
      
      Logger.log("CHAT_SERVICE - Sender Role: ${isSenderTheMerchant ? 'Merchant' : 'User'}. Sender ID: $senderParticipantId, Receiver ID: $receiverParticipantId");

      // 3. Get sender's name for the notification from the correct persona
      final senderName = conversation.participantDetails[senderParticipantId]?.name ?? 'Unknown';

      // 4. Create the message model
      final messageId = _firestore.collection('temp').doc().id;
      final message = MessageModel(
        id: messageId,
        senderId: senderParticipantId, // Use the correct contextual participant ID
        text: text.trim(),
        timestamp: timestamp,
        readBy: [senderParticipantId],
      );

      // 5. Create a batch write for atomicity
      final batch = _firestore.batch();
      final messageRef = convDoc.reference.collection('messages').doc(messageId);
      batch.set(messageRef, message.toMap());

      batch.update(convDoc.reference, {
        'lastMessage': {
          'text': text.trim(),
          'senderId': senderParticipantId,
          'timestamp': timestamp.toIso8601String(),
          'type': 'text',
        },
        'updatedAt': timestamp.toIso8601String(),
        'unreadCount.$receiverParticipantId': FieldValue.increment(1),
        'unreadCount.$senderParticipantId': 0, // Reset sender's unread count
      });

      await batch.commit();
      Logger.log("CHAT_SERVICE - Message sent by $senderParticipantId, unread count updated for $receiverParticipantId");

      // 6. Send notification with the correct senderName
      await _sendNotificationToReceiver(
        receiverId: receiverParticipantId,
        senderId: senderParticipantId,
        senderName: senderName, // This will now correctly be the Merchant's name if they sent it
        message: text.trim(),
        conversationId: conversationId,
      );

    } catch (e) {
      Logger.error("CHAT_SERVICE - Error sending message", error: e);
      rethrow;
    }
  }

  /// Send notification to message receiver
  Future<void> _sendNotificationToReceiver({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      Logger.log("CHAT_SERVICE - Sending notification to $receiverId");
      
      final notificationPayload = NotificationPayload(
        receiverId: receiverId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        conversationId: conversationId,
      );
      
      await _notificationService.sendNotification(notificationPayload);
      Logger.log("CHAT_SERVICE - Notification sent successfully");
      
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error sending notification", error: e);
      // Don't rethrow - notification failure shouldn't fail message sending
    }
  }

  /// Get sender name from conversation participants
  Future<String> _getSenderName(String conversationId, String senderId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final participantDetails = data['participantDetails'] as Map<String, dynamic>?;
        
        if (participantDetails != null && participantDetails.containsKey(senderId)) {
          final senderDetail = participantDetails[senderId] as Map<String, dynamic>;
          return senderDetail['name'] ?? 'Unknown';
        }
      }
      
      // Fallback to role-based name
      return senderId.startsWith('MRCN_') ? 'Penjual' : 'Pembeli';
      
    } catch (e) {
      Logger.error("CHAT_SERVICE - Error getting sender name", error: e);
      return 'Unknown';
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

  /// FIXED: Mark messages as read with proper participant detection
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      Logger.log("CHAT_SERVICE - Marking as read: $conversationId for $userId");
      
      // FIXED: Get conversation first to determine correct user ID
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (!conversationDoc.exists) {
        Logger.error("CHAT_SERVICE - Conversation not found: $conversationId");
        return;
      }
      
      final conversationData = conversationDoc.data()!;
      final participants = List<String>.from(conversationData['participants'] ?? []);
      
      // FIXED: Determine the correct participant ID to reset unread count
      String? participantToUpdate;
      
      // Check if userId is directly in participants (for users)
      if (participants.contains(userId)) {
        participantToUpdate = userId;
        Logger.log("CHAT_SERVICE - Direct participant match: $userId");
      } else {
        // For merchants, find the merchant ID in participants
        for (final participant in participants) {
          if (participant.startsWith('MRCN_') && participant.contains(userId.replaceFirst('MRCN_', ''))) {
            participantToUpdate = participant;
            Logger.log("CHAT_SERVICE - Merchant participant match: $participant for $userId");
            break;
          }
        }
        
        // If still not found, try exact match with MRCN_ prefix
        if (participantToUpdate == null && !userId.startsWith('MRCN_')) {
          final merchantId = "MRCN_$userId";
          if (participants.contains(merchantId)) {
            participantToUpdate = merchantId;
            Logger.log("CHAT_SERVICE - Constructed merchant ID match: $merchantId");
          }
        }
        
        // Last resort: use userId as is if it starts with MRCN_
        if (participantToUpdate == null && userId.startsWith('MRCN_')) {
          if (participants.contains(userId)) {
            participantToUpdate = userId;
            Logger.log("CHAT_SERVICE - Direct MRCN_ match: $userId");
          }
        }
      }
      
      if (participantToUpdate == null) {
        Logger.error("CHAT_SERVICE - Could not determine participant to update for $userId in $participants");
        return;
      }
      
      // FIXED: Update unread count for correct participant
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'unreadCount.$participantToUpdate': 0,
      });
      
      Logger.log("CHAT_SERVICE - Successfully marked as read for participant: $participantToUpdate");
      
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

  /// FIXED: Get receiver ID from conversation with better error handling
  Future<String> _getReceiverId(String conversationId, String senderId) async {
    try {
      // First, try parsing conversation ID: "user123_MRCN_merchant456"
      final parts = conversationId.split('_');
      if (parts.length >= 3) {
        final userId = parts[0];
        final merchantId = "${parts[1]}_${parts[2]}"; // MRCN_merchant456
        
        final receiverId = senderId == userId ? merchantId : userId;
        Logger.log("CHAT_SERVICE - Receiver ID from parsing: $receiverId (sender: $senderId)");
        return receiverId;
      } else {
        // Fallback: get from conversation document
        Logger.log("CHAT_SERVICE - Using fallback method to get receiver ID");
        final doc = await _firestore.collection('conversations').doc(conversationId).get();
        if (doc.exists) {
          final participants = List<String>.from(doc.data()!['participants'] ?? []);
          Logger.log("CHAT_SERVICE - Participants: $participants, Sender: $senderId");
          
          final receiverId = participants.firstWhere(
            (id) => id != senderId, 
            orElse: () => throw Exception("Cannot find receiver in participants")
          );
          
          Logger.log("CHAT_SERVICE - Receiver ID from document: $receiverId");
          return receiverId;
        }
        throw Exception("Conversation document not found");
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