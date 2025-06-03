// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatServiceHash() => r'ec2b2ddbcd34a3e4b52570a241e803d82a951266';

/// See also [chatService].
@ProviderFor(chatService)
final chatServiceProvider = AutoDisposeProvider<ChatService>.internal(
  chatService,
  name: r'chatServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatServiceRef = AutoDisposeProviderRef<ChatService>;
String _$userServiceChatHash() => r'a67ebf5b1313ed9511302929b8442e4052256093';

/// See also [userServiceChat].
@ProviderFor(userServiceChat)
final userServiceChatProvider = AutoDisposeProvider<UserService>.internal(
  userServiceChat,
  name: r'userServiceChatProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userServiceChatHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserServiceChatRef = AutoDisposeProviderRef<UserService>;
String _$userConversationsHash() => r'208c2f37a20d950752207223307c66164858fff7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Stream provider for user conversations (as buyer)
///
/// Copied from [userConversations].
@ProviderFor(userConversations)
const userConversationsProvider = UserConversationsFamily();

/// Stream provider for user conversations (as buyer)
///
/// Copied from [userConversations].
class UserConversationsFamily
    extends Family<AsyncValue<List<ConversationModel>>> {
  /// Stream provider for user conversations (as buyer)
  ///
  /// Copied from [userConversations].
  const UserConversationsFamily();

  /// Stream provider for user conversations (as buyer)
  ///
  /// Copied from [userConversations].
  UserConversationsProvider call(
    String userId,
  ) {
    return UserConversationsProvider(
      userId,
    );
  }

  @override
  UserConversationsProvider getProviderOverride(
    covariant UserConversationsProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userConversationsProvider';
}

/// Stream provider for user conversations (as buyer)
///
/// Copied from [userConversations].
class UserConversationsProvider
    extends AutoDisposeStreamProvider<List<ConversationModel>> {
  /// Stream provider for user conversations (as buyer)
  ///
  /// Copied from [userConversations].
  UserConversationsProvider(
    String userId,
  ) : this._internal(
          (ref) => userConversations(
            ref as UserConversationsRef,
            userId,
          ),
          from: userConversationsProvider,
          name: r'userConversationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userConversationsHash,
          dependencies: UserConversationsFamily._dependencies,
          allTransitiveDependencies:
              UserConversationsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserConversationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<ConversationModel>> Function(UserConversationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserConversationsProvider._internal(
        (ref) => create(ref as UserConversationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ConversationModel>> createElement() {
    return _UserConversationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserConversationsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserConversationsRef
    on AutoDisposeStreamProviderRef<List<ConversationModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserConversationsProviderElement
    extends AutoDisposeStreamProviderElement<List<ConversationModel>>
    with UserConversationsRef {
  _UserConversationsProviderElement(super.provider);

  @override
  String get userId => (origin as UserConversationsProvider).userId;
}

String _$merchantConversationsHash() =>
    r'deecd108eb6b6bb5f0f681775c72dfa6975c210b';

/// Stream provider for merchant conversations (as seller)
///
/// Copied from [merchantConversations].
@ProviderFor(merchantConversations)
const merchantConversationsProvider = MerchantConversationsFamily();

/// Stream provider for merchant conversations (as seller)
///
/// Copied from [merchantConversations].
class MerchantConversationsFamily
    extends Family<AsyncValue<List<ConversationModel>>> {
  /// Stream provider for merchant conversations (as seller)
  ///
  /// Copied from [merchantConversations].
  const MerchantConversationsFamily();

  /// Stream provider for merchant conversations (as seller)
  ///
  /// Copied from [merchantConversations].
  MerchantConversationsProvider call(
    String merchantId,
  ) {
    return MerchantConversationsProvider(
      merchantId,
    );
  }

  @override
  MerchantConversationsProvider getProviderOverride(
    covariant MerchantConversationsProvider provider,
  ) {
    return call(
      provider.merchantId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'merchantConversationsProvider';
}

/// Stream provider for merchant conversations (as seller)
///
/// Copied from [merchantConversations].
class MerchantConversationsProvider
    extends AutoDisposeStreamProvider<List<ConversationModel>> {
  /// Stream provider for merchant conversations (as seller)
  ///
  /// Copied from [merchantConversations].
  MerchantConversationsProvider(
    String merchantId,
  ) : this._internal(
          (ref) => merchantConversations(
            ref as MerchantConversationsRef,
            merchantId,
          ),
          from: merchantConversationsProvider,
          name: r'merchantConversationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$merchantConversationsHash,
          dependencies: MerchantConversationsFamily._dependencies,
          allTransitiveDependencies:
              MerchantConversationsFamily._allTransitiveDependencies,
          merchantId: merchantId,
        );

  MerchantConversationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.merchantId,
  }) : super.internal();

  final String merchantId;

  @override
  Override overrideWith(
    Stream<List<ConversationModel>> Function(MerchantConversationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MerchantConversationsProvider._internal(
        (ref) => create(ref as MerchantConversationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        merchantId: merchantId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ConversationModel>> createElement() {
    return _MerchantConversationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MerchantConversationsProvider &&
        other.merchantId == merchantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, merchantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MerchantConversationsRef
    on AutoDisposeStreamProviderRef<List<ConversationModel>> {
  /// The parameter `merchantId` of this provider.
  String get merchantId;
}

class _MerchantConversationsProviderElement
    extends AutoDisposeStreamProviderElement<List<ConversationModel>>
    with MerchantConversationsRef {
  _MerchantConversationsProviderElement(super.provider);

  @override
  String get merchantId => (origin as MerchantConversationsProvider).merchantId;
}

String _$conversationDetailHash() =>
    r'3e6ef415b13159c59bef15924a34634e5e196a12';

/// Stream provider for single conversation
///
/// Copied from [conversationDetail].
@ProviderFor(conversationDetail)
const conversationDetailProvider = ConversationDetailFamily();

/// Stream provider for single conversation
///
/// Copied from [conversationDetail].
class ConversationDetailFamily extends Family<AsyncValue<ConversationModel?>> {
  /// Stream provider for single conversation
  ///
  /// Copied from [conversationDetail].
  const ConversationDetailFamily();

  /// Stream provider for single conversation
  ///
  /// Copied from [conversationDetail].
  ConversationDetailProvider call(
    String conversationId,
  ) {
    return ConversationDetailProvider(
      conversationId,
    );
  }

  @override
  ConversationDetailProvider getProviderOverride(
    covariant ConversationDetailProvider provider,
  ) {
    return call(
      provider.conversationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationDetailProvider';
}

/// Stream provider for single conversation
///
/// Copied from [conversationDetail].
class ConversationDetailProvider
    extends AutoDisposeStreamProvider<ConversationModel?> {
  /// Stream provider for single conversation
  ///
  /// Copied from [conversationDetail].
  ConversationDetailProvider(
    String conversationId,
  ) : this._internal(
          (ref) => conversationDetail(
            ref as ConversationDetailRef,
            conversationId,
          ),
          from: conversationDetailProvider,
          name: r'conversationDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$conversationDetailHash,
          dependencies: ConversationDetailFamily._dependencies,
          allTransitiveDependencies:
              ConversationDetailFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ConversationDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<ConversationModel?> Function(ConversationDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationDetailProvider._internal(
        (ref) => create(ref as ConversationDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ConversationModel?> createElement() {
    return _ConversationDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationDetailProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationDetailRef
    on AutoDisposeStreamProviderRef<ConversationModel?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationDetailProviderElement
    extends AutoDisposeStreamProviderElement<ConversationModel?>
    with ConversationDetailRef {
  _ConversationDetailProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationDetailProvider).conversationId;
}

String _$conversationMessagesHash() =>
    r'86722084d3daf2d34510e542842e9262417afb57';

/// Stream provider for messages in a conversation
///
/// Copied from [conversationMessages].
@ProviderFor(conversationMessages)
const conversationMessagesProvider = ConversationMessagesFamily();

/// Stream provider for messages in a conversation
///
/// Copied from [conversationMessages].
class ConversationMessagesFamily
    extends Family<AsyncValue<List<MessageModel>>> {
  /// Stream provider for messages in a conversation
  ///
  /// Copied from [conversationMessages].
  const ConversationMessagesFamily();

  /// Stream provider for messages in a conversation
  ///
  /// Copied from [conversationMessages].
  ConversationMessagesProvider call(
    String conversationId,
  ) {
    return ConversationMessagesProvider(
      conversationId,
    );
  }

  @override
  ConversationMessagesProvider getProviderOverride(
    covariant ConversationMessagesProvider provider,
  ) {
    return call(
      provider.conversationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationMessagesProvider';
}

/// Stream provider for messages in a conversation
///
/// Copied from [conversationMessages].
class ConversationMessagesProvider
    extends AutoDisposeStreamProvider<List<MessageModel>> {
  /// Stream provider for messages in a conversation
  ///
  /// Copied from [conversationMessages].
  ConversationMessagesProvider(
    String conversationId,
  ) : this._internal(
          (ref) => conversationMessages(
            ref as ConversationMessagesRef,
            conversationId,
          ),
          from: conversationMessagesProvider,
          name: r'conversationMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$conversationMessagesHash,
          dependencies: ConversationMessagesFamily._dependencies,
          allTransitiveDependencies:
              ConversationMessagesFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ConversationMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<MessageModel>> Function(ConversationMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationMessagesProvider._internal(
        (ref) => create(ref as ConversationMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageModel>> createElement() {
    return _ConversationMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationMessagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationMessagesRef
    on AutoDisposeStreamProviderRef<List<MessageModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageModel>>
    with ConversationMessagesRef {
  _ConversationMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationMessagesProvider).conversationId;
}

String _$chatActionsViewModelHash() =>
    r'df6880a613d1cf6e0429a0ae6603e85d6d0b2617';

/// See also [ChatActionsViewModel].
@ProviderFor(ChatActionsViewModel)
final chatActionsViewModelProvider = AutoDisposeNotifierProvider<
    ChatActionsViewModel, AppState<String, Exception>>.internal(
  ChatActionsViewModel.new,
  name: r'chatActionsViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatActionsViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatActionsViewModel
    = AutoDisposeNotifier<AppState<String, Exception>>;
String _$chatListViewModelHash() => r'983d265d9e86d608e84de348dab6356559ef067c';

/// See also [ChatListViewModel].
@ProviderFor(ChatListViewModel)
final chatListViewModelProvider = AutoDisposeNotifierProvider<ChatListViewModel,
    AppState<Map<String, dynamic>, Exception>>.internal(
  ChatListViewModel.new,
  name: r'chatListViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatListViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatListViewModel
    = AutoDisposeNotifier<AppState<Map<String, dynamic>, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
