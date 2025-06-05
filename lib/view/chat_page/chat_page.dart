import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/chat/conversation_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/date_formatter.dart'; // Use our safe date formatter
import 'package:temulapak_app/view/chat_page/chat_detail_page.dart';
import 'package:temulapak_app/view/chat_page/chat_viewmodel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize chat lists
    Future.microtask(() {
      ref.read(chatListViewModelProvider.notifier).loadChatLists();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatListState = ref.watch(chatListViewModelProvider);

    return chatListState.when(
      idle: () => _buildLoadingState(),
      loading: () => _buildLoadingState(),
      success: (data) => _buildChatDashboard(data),
      error: (error, message) => _buildErrorState(message),
    );
  }

  Widget _buildChatDashboard(Map<String, dynamic> data) {
    final isMerchant = data['isMerchant'] as bool;
    final userId = data['userId'] as String;
    final merchantId = data['merchantId'] as String;

    // Initialize tab controller based on merchant status
    if (_tabController == null) {
      _tabController = TabController(
        length: isMerchant ? 2 : 1,
        vsync: this,
      );
    }

    if (isMerchant) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: MyColor.whitePlain,
          appBar: AppBar(
            title: Text(
              'Pesan',
              style: TextStyle(
                color: MyColor.blackPlain,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            // FIXED: Modern TabBar design
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MyColor.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: MyColor.blackPlain,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicator: BoxDecoration(
                    color: MyColor.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicatorPadding: EdgeInsets.all(2),
                  tabs: [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Sebagai Pembeli'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Sebagai Penjual'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              UserChatListView(userId: userId),
              MerchantChatListView(merchantId: merchantId),
            ],
          ),
        ),
      );
    } else {
      // User only - no tabs
      return Scaffold(
        backgroundColor: MyColor.whitePlain,
        appBar: AppBar(
          title: Text(
            'Pesan',
            style: TextStyle(
              color: MyColor.blackPlain,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
        ),
        body: UserChatListView(userId: userId),
      );
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text(
          'Pesan',
          style: TextStyle(
            color: MyColor.blackPlain,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: MyColor.orange),
            SizedBox(height: 16),
            Text(
              'Memuat chat...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text(
          'Pesan',
          style: TextStyle(
            color: MyColor.blackPlain,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: Center(
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
                'Gagal Memuat Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MyColor.blackPlain,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message ?? 'Terjadi kesalahan saat memuat chat',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatListViewModelProvider.notifier).refreshChatLists();
                },
                icon: Icon(Icons.refresh),
                label: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserChatListView extends ConsumerWidget {
  final String userId;

  const UserChatListView({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsStream = ref.watch(userConversationsProvider(userId));

    return conversationsStream.when(
      data: (conversations) {
        Logger.log("USER_CHAT_LIST - Successfully loaded ${conversations.length} conversations");
        if (conversations.isEmpty) {
          return _buildEmptyUserState();
        }
        return _buildConversationsList(conversations, isFromMerchant: false);
      },
      loading: () {
        Logger.log("USER_CHAT_LIST - Loading conversations for user: $userId");
        return _buildLoadingList();
      },
      error: (error, stack) {
        Logger.error("USER_CHAT_LIST - Stream error for user $userId", error: error);
        Logger.error("USER_CHAT_LIST - Stack trace", error: stack);
        
        // Check if it's a Firebase index error
        if (error.toString().contains('requires an index')) {
          return _buildIndexErrorState(ref);
        }
        
        return _buildErrorList("Gagal memuat chat sebagai pembeli: ${error.toString()}");
      },
    );
  }

  // FIXED: Pass WidgetRef as parameter
  Widget _buildIndexErrorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: MyColor.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Sedang Mengoptimalkan Database',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Aplikasi sedang mengatur database untuk performa yang lebih baik. Silakan coba lagi dalam beberapa saat.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // FIXED: Use ref parameter to force refresh
                ref.invalidate(userConversationsProvider(userId));
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
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

  Widget _buildEmptyUserState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: MyColor.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 64,
                color: MyColor.orange,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Chat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Mulai chat dengan merchant dengan\nmenekan tombol chat di halaman merchant',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(List<ConversationModel> conversations, {required bool isFromMerchant}) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ChatListTile(
          conversation: conversation,
          isFromMerchant: isFromMerchant,
          onTap: () {
            Logger.log("Opening chat detail: ${conversation.id}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  conversationId: conversation.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorList(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: MyColor.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

// === MERCHANT CHAT LIST VIEW ===

class MerchantChatListView extends ConsumerWidget {
  final String merchantId;

  const MerchantChatListView({
    super.key,
    required this.merchantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsStream = ref.watch(merchantConversationsProvider(merchantId));

    return conversationsStream.when(
      data: (conversations) {
        Logger.log("MERCHANT_CHAT_LIST - Successfully loaded ${conversations.length} conversations");
        if (conversations.isEmpty) {
          return _buildEmptyMerchantState();
        }
        return _buildConversationsList(conversations, isFromMerchant: true);
      },
      loading: () {
        Logger.log("MERCHANT_CHAT_LIST - Loading conversations for merchant: $merchantId");
        return _buildLoadingList();
      },
      error: (error, stack) {
        Logger.error("MERCHANT_CHAT_LIST - Stream error for merchant $merchantId", error: error);
        Logger.error("MERCHANT_CHAT_LIST - Stack trace", error: stack);
        
        // Check if it's a Firebase index error
        if (error.toString().contains('requires an index')) {
          return _buildMerchantIndexErrorState(ref);
        }
        
        return _buildErrorList("Gagal memuat chat sebagai penjual: ${error.toString()}");
      },
    );
  }

  // FIXED: Add index error state for merchant view
  Widget _buildMerchantIndexErrorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: MyColor.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Sedang Mengoptimalkan Database',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Aplikasi sedang mengatur database untuk performa yang lebih baik. Silakan coba lagi dalam beberapa saat.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Force refresh for merchant conversations
                ref.invalidate(merchantConversationsProvider(merchantId));
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
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

  Widget _buildEmptyMerchantState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: 64,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Pesan Masuk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Pelanggan akan muncul di sini\nsetelah mengirim pesan kepada Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(List<ConversationModel> conversations, {required bool isFromMerchant}) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ChatListTile(
          conversation: conversation,
          isFromMerchant: isFromMerchant,
          onTap: () {
            Logger.log("Opening merchant chat detail: ${conversation.id}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  conversationId: conversation.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorList(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: MyColor.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

// === CHAT LIST TILE WIDGET ===

class ChatListTile extends StatelessWidget {
  final ConversationModel conversation;
  final bool isFromMerchant;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.conversation,
    required this.isFromMerchant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = _getOtherParticipant();
    final currentUserId = _getCurrentUserId();
    final unreadCount = conversation.unreadCount[currentUserId] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: otherParticipant?.avatar != null
                      ? NetworkImage(otherParticipant!.avatar!)
                      : null,
                  child: otherParticipant?.avatar == null
                      ? Icon(
                          isFromMerchant ? Icons.person : Icons.store,
                          color: Colors.grey[600],
                          size: 28,
                        )
                      : null,
                ),
                SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherParticipant?.name ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: MyColor.blackPlain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            // FIXED: Use safe date formatter utility
                            DateFormatter.formatMessageTime(conversation.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      
                      // Last message and unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage?.text ?? 'Tidak ada pesan',
                              style: TextStyle(
                                fontSize: 14,
                                color: unreadCount > 0 
                                    ? MyColor.blackPlain 
                                    : Colors.grey[600],
                                fontWeight: unreadCount > 0 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MyColor.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ParticipantDetail? _getOtherParticipant() {
    final currentUserId = _getCurrentUserId();
    final otherParticipantId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherParticipantId.isNotEmpty) {
      return conversation.participantDetails[otherParticipantId];
    }
    return null;
  }

  String _getCurrentUserId() {
    // This would typically come from a provider/service
    // For now, we'll determine based on the merchant flag and conversation participants
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
}