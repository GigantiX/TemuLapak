import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/data/network/chat_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/chat/conversation_model.dart';
import 'package:temulapak_app/model/chat/message_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/chat_page/chat_viewmodel.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String currentUserPersonaId;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.currentUserPersonaId,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  late types.User _currentUser;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUser(widget.currentUserPersonaId);
  }

  void _initializeUser(String personaId) async {
    try {
      final userService = UserService();
      final currentUserData = await userService.getCurrentUser();

      if ( currentUserData != null) {
        setState(() {
          _currentUser = types.User(
            id: personaId,
            firstName: currentUserData.displayName ?? 'User',
            imageUrl: currentUserData.photoURL,
          );
          _isInitialized = true;
        });

        Future.delayed(Duration(milliseconds: 500), () {
          ref
              .read(chatActionsViewModelProvider.notifier)
              .markAsRead(widget.conversationId, personaId);
        });
      }
    } catch (e) {
      Logger.error("CHAT_DETAIL - Error initializing user", error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: MyColor.whitePlain,
        appBar: AppBar(
          title: Text('Chat'),
          backgroundColor: Colors.white,
          foregroundColor: MyColor.blackPlain,
        ),
        body: Center(
          child: CircularProgressIndicator(color: MyColor.orange),
        ),
      );
    }

    final conversationStream =
        ref.watch(conversationDetailProvider(widget.conversationId));
    final messagesStream =
        ref.watch(conversationMessagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: _buildAppBar(conversationStream),
      body: messagesStream.when(
        data: (messages) => _buildChatUI(messages),
        loading: () => Center(
          child: CircularProgressIndicator(color: MyColor.orange),
        ),
        error: (error, stack) {
          Logger.error("CHAT_DETAIL - Messages stream error", error: error);
          return _buildErrorState("Gagal memuat pesan");
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AsyncValue<ConversationModel?> conversationStream) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: MyColor.blackPlain,
      elevation: 0.5,
      title: conversationStream.when(
        data: (conversation) {
          if (conversation != null) {
            final otherParticipant = ChatService.instance
                .getOtherParticipant(conversation, widget.currentUserPersonaId);

            if (otherParticipant != null) {
              return Row(
                children: [
                  // Profile picture in AppBar only (as requested)
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: otherParticipant.avatar != null
                        ? NetworkImage(otherParticipant.avatar!)
                        : null,
                    child: otherParticipant.avatar == null
                        ? Icon(
                            otherParticipant.role == 'merchant'
                                ? Icons.store
                                : Icons.person,
                            color: Colors.grey[600],
                            size: 18,
                          )
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherParticipant.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MyColor.blackPlain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          otherParticipant.role == 'merchant'
                              ? 'Penjual'
                              : 'Pembeli',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          }
          return Text('Chat');
        },
        loading: () => Text('Chat'),
        error: (_, __) => Text('Chat'),
      ),
    );
  }

  Widget _buildChatUI(List<MessageModel> messages) {
    // Convert MessageModel to flutter_chat_ui types
    final chatMessages =
        messages.map((msg) => _convertToFlutterChatMessage(msg)).toList();

    return Chat(
      messages: chatMessages,
      onSendPressed: _handleSendPressed,
      user: _currentUser,
      theme: DefaultChatTheme(
        primaryColor: MyColor.orange,
        backgroundColor: MyColor.whitePlain,
        inputBackgroundColor: Colors.white,
        inputTextColor: MyColor.blackPlain,
        // FIXED: Remove border radius from input
        inputBorderRadius: BorderRadius.zero,
        messageBorderRadius: 20,

        // Message styling
        sentMessageBodyTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        receivedMessageBodyTextStyle: TextStyle(
          color: MyColor.blackPlain,
          fontSize: 16,
        ),

        // Remove avatars from messages (only show in AppBar)
        userAvatarNameColors: [],

        // Input styling
        inputTextStyle: TextStyle(
          fontSize: 16,
          color: MyColor.blackPlain,
        ),
        // FIXED: Remove border from input container
        inputContainerDecoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.transparent),
        ),

        // FIXED: Orange send button with white icon
        sendButtonIcon: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: MyColor.orange,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.send,
            color: Colors.white,
            size: 20,
          ),
        ),

        // Input padding
        inputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        inputMargin: EdgeInsets.all(0),
      ),

      // Input options - Updated for v1.6.15
      l10n: const ChatL10nEn(
        inputPlaceholder: 'Ketik pesan...',
        emptyChatPlaceholder: 'Belum ada pesan',
      ),

      // Disable avatars in messages (as requested)
      showUserAvatars: false,
      showUserNames: false,

      // Empty state
      emptyState: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Mulai percakapan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kirim pesan pertama untuk memulai chat',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  types.Message _convertToFlutterChatMessage(MessageModel message) {
    return types.TextMessage(
      author: types.User(
        id: message.senderId,
        firstName: _getUserName(message.senderId),
      ),
      createdAt: message.timestamp.millisecondsSinceEpoch,
      id: message.id,
      text: message.text,
      status: message.readBy.contains(widget.currentUserPersonaId)
          ? types.Status.seen
          : types.Status.delivered,
    );
  }

  String _getUserName(String userId) {
    // This could be enhanced to get actual user names
    // For now, just return a simple identifier
    if (userId.startsWith('MRCN_')) {
      return 'Penjual';
    } else {
      return 'Pembeli';
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    final text = message.text.trim();

    if (text.isEmpty) {
      return;
    }

    // Validate message length (manual validation for v1.6.15)
    if (text.length > 350) {
      _showErrorSnackBar('Pesan terlalu panjang (maksimal 350 karakter)');
      return;
    }

    try {
      Logger.log(
          "CHAT_DETAIL - Sending message: ${text.substring(0, math.min(20, text.length))}...");

      await ref
          .read(chatActionsViewModelProvider.notifier)
          .sendMessage(widget.conversationId, text);

      Logger.log("CHAT_DETAIL - Message sent successfully");
    } catch (e) {
      Logger.error("CHAT_DETAIL - Error sending message", error: e);
      _showErrorSnackBar('Gagal mengirim pesan');
    }
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: MyColor.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(chatActionsViewModelProvider.notifier)
                    .navigateBack(context);
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: MyColor.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
