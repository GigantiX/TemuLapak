import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/chat_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/main.dart';
import 'package:temulapak_app/model/chat/conversation_model.dart';
import 'package:temulapak_app/model/chat/message_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/chat_page/chat_detail_page.dart';

part 'chat_viewmodel.g.dart';

@riverpod
ChatService chatService(Ref ref) {
  return ChatService.instance;
}

@riverpod
UserService userServiceChat(Ref ref) {
  return UserService();
}

// === CONVERSATION STREAMS ===

/// Stream provider for user conversations (as buyer)
@riverpod
Stream<List<ConversationModel>> userConversations(Ref ref, String userId) {
  Logger.log("CHAT_VM - Starting user conversations stream for: $userId");
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserConversations(userId);
}

/// Stream provider for merchant conversations (as seller)
@riverpod
Stream<List<ConversationModel>> merchantConversations(Ref ref, String merchantId) {
  Logger.log("CHAT_VM - Starting merchant conversations stream for: $merchantId");
  final chatService = ref.read(chatServiceProvider);
  return chatService.getMerchantConversations(merchantId);
}

/// Stream provider for single conversation
@riverpod
Stream<ConversationModel?> conversationDetail(Ref ref, String conversationId) {
  Logger.log("CHAT_VM - Starting conversation detail stream for: $conversationId");
  final chatService = ref.read(chatServiceProvider);
  return chatService.getConversation(conversationId);
}

/// Stream provider for messages in a conversation
@riverpod
Stream<List<MessageModel>> conversationMessages(Ref ref, String conversationId) {
  Logger.log("CHAT_VM - Starting messages stream for: $conversationId");
  final chatService = ref.read(chatServiceProvider);
  return chatService.getMessages(conversationId);
}

// === CHAT ACTIONS VIEWMODEL ===

@riverpod
class ChatActionsViewModel extends _$ChatActionsViewModel {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  /// Start new chat (only users can initiate)
  Future<String?> startChat(MerchantModel merchant) async {
    try {
      state = AppState.loading();
      Logger.log("CHAT_ACTIONS_VM - Starting chat with merchant: ${merchant.merchantName}");
      
      final userService = ref.read(userServiceChatProvider);
      final currentUserId = userService.getCurrentUID();
      
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }
      
      final merchantId = "MRCN_${merchant.uid}";
      final chatService = ref.read(chatServiceProvider);
      
      final conversationId = await chatService.getOrCreateConversation(
        currentUserId,
        merchantId,
        merchant,
      );
      
      Logger.log("CHAT_ACTIONS_VM - Chat started successfully: $conversationId");
      state = AppState.success("Chat started with ${merchant.merchantName}");
      
      return conversationId;
      
    } catch (e) {
      Logger.error("CHAT_ACTIONS_VM - Error starting chat", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Gagal memulai chat: ${e.toString()}'
      );
      return null;
    }
  }

  /// Send message
  Future<void> sendMessage(String conversationId, String text) async {
    try {
      Logger.log("CHAT_ACTIONS_VM - Sending message to: $conversationId");
      
      final userService = ref.read(userServiceChatProvider);
      final currentUserId = userService.getCurrentUID();
      
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }
      
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendMessage(conversationId, text, currentUserId);
      
      Logger.log("CHAT_ACTIONS_VM - Message sent successfully");
      
    } catch (e) {
      Logger.error("CHAT_ACTIONS_VM - Error sending message", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Gagal mengirim pesan: ${e.toString()}'
      );
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      Logger.log("CHAT_ACTIONS_VM - Marking as read: $conversationId");
      
      final userService = ref.read(userServiceChatProvider);
      final currentUserId = userService.getCurrentUID();
      
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }
      
      final chatService = ref.read(chatServiceProvider);
      await chatService.markAsRead(conversationId, currentUserId);
      
      Logger.log("CHAT_ACTIONS_VM - Marked as read successfully");
      
    } catch (e) {
      Logger.error("CHAT_ACTIONS_VM - Error marking as read", error: e);
      // Don't show error to user for read status
    }
  }

  void navigateToChatDetail(String conversationId, BuildContext context) {
     Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            conversationId: conversationId,
          ),
        ),
      );
  }

  void navigateBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Logger.log("CHAT_ACTIONS_VM - No previous route to pop");
    }
    
  }

  /// Clear state
  void clearState() {
    state = AppState.idle();
  }
}

// === CHAT LIST VIEWMODEL ===

@riverpod
class ChatListViewModel extends _$ChatListViewModel {
  @override
  AppState<Map<String, dynamic>, Exception> build() {
    return AppState.idle();
  }

  /// Load chat lists for current user
  Future<void> loadChatLists() async {
    try {
      state = AppState.loading();
      Logger.log("CHAT_LIST_VM - Loading chat lists");
      
      final userService = ref.read(userServiceChatProvider);
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception("User not found");
      }
      
      final result = {
        'user': currentUser,
        'userId': currentUser.uid!,
        'merchantId': "MRCN_${currentUser.uid}",
        'isMerchant': currentUser.isMerchant,
      };
      
      Logger.log("CHAT_LIST_VM - Chat lists loaded successfully");
      state = AppState.success(result);
      
    } catch (e) {
      Logger.error("CHAT_LIST_VM - Error loading chat lists", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Gagal memuat daftar chat: ${e.toString()}'
      );
    }
  }

  String getCurrentUserId(ConversationModel conversation, bool isFromMerchant) {
    Logger.log("CHAT_LIST_VM - Getting current user ID for ${isFromMerchant ? 'merchant' : 'user'} view");
    
    if (isFromMerchant) {
      // Find the merchant ID (starts with MRCN_)
      return conversation.participants.firstWhere(
        (id) => id.startsWith('MRCN_'),
        orElse: () => conversation.participants.first,
      );
    } else {
      // Find the user ID (doesn't start with MRCN_)
      return conversation.participants.firstWhere(
        (id) => !id.startsWith('MRCN_'),
        orElse: () => conversation.participants.first,
      );
    }
  }
  
  /// Get the other participant's details
  ParticipantDetail? getOtherParticipant(ConversationModel conversation, bool isFromMerchant) {
    final currentUserId = getCurrentUserId(conversation, isFromMerchant);
    final otherParticipantId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherParticipantId.isNotEmpty) {
      return conversation.participantDetails[otherParticipantId];
    }
    return null;
  }

  /// Refresh chat lists
  Future<void> refreshChatLists() async {
    Logger.log("CHAT_LIST_VM - Refreshing chat lists");
    await loadChatLists();
  }
}