import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/notification/fcm_token_model.dart';
import 'package:temulapak_app/model/notification/notification_model.dart';
import 'package:temulapak_app/model/notification/notification_payload.dart';
import 'package:temulapak_app/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final UserService _userService = UserService();

  // Cache for notification server URL
  String? _cachedServerUrl;
  DateTime? _lastUrlFetch;
  static const Duration _urlCacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Fixed Firestore path for notification URL
  static const String _urlCollection = 'service';
  static const String _urlDocument = 'notification';
  static const String _urlField = 'notificationUrl';

  // Fallback URL if Firestore fetch fails
  static const String _fallbackUrl = 'http://10.0.2.2:3000'; // Android emulator local

  // Callback for handling notification taps
  Function(String conversationId)? onNotificationTap;

  /// Get notification server URL from Firestore with caching
  Future<String> _getServerUrl() async {
    try {
      // Check cache first
      if (_cachedServerUrl != null && _lastUrlFetch != null) {
        final cacheAge = DateTime.now().difference(_lastUrlFetch!);
        if (cacheAge < _urlCacheDuration) {
          Logger.log("NOTIFICATION_SERVICE - Using cached server URL: $_cachedServerUrl");
          return _cachedServerUrl!;
        }
      }

      Logger.log("NOTIFICATION_SERVICE - Fetching server URL from Firestore");
      
      // Fetch URL from Firestore: service/notification/notificationUrl
      final doc = await _firestore
          .collection(_urlCollection)
          .doc(_urlDocument)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final url = data[_urlField] as String?;
        
        if (url != null && url.isNotEmpty) {
          _cachedServerUrl = url;
          _lastUrlFetch = DateTime.now();
          Logger.log("NOTIFICATION_SERVICE - Server URL fetched from Firestore: $url");
          return url;
        }
      }

      Logger.log("NOTIFICATION_SERVICE - No URL found in Firestore, using fallback");
      return _fallbackUrl;

    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error fetching server URL from Firestore", error: e);
      Logger.log("NOTIFICATION_SERVICE - Using fallback URL: $_fallbackUrl");
      return _fallbackUrl;
    }
  }

  /// Pre-fetch server URL (call on app start)
  Future<void> prefetchServerUrl() async {
    try {
      Logger.log("NOTIFICATION_SERVICE - Pre-fetching server URL");
      final url = await _getServerUrl();
      Logger.log("NOTIFICATION_SERVICE - Server URL cached: $url");
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error pre-fetching server URL", error: e);
    }
  }

  /// Clear cached URL (useful for testing)
  void clearUrlCache() {
    _cachedServerUrl = null;
    _lastUrlFetch = null;
    Logger.log("NOTIFICATION_SERVICE - URL cache cleared");
  }

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      Logger.log("NOTIFICATION_SERVICE - Initializing...");

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Get and save FCM token
      await _initializeFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      Logger.log("NOTIFICATION_SERVICE - Initialized successfully");
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Initialization failed", error: e);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    Logger.log("NOTIFICATION_SERVICE - Notification tapped: ${response.payload}");
    
    if (response.payload != null) {
      final conversationId = response.payload!;
      onNotificationTap?.call(conversationId);
    }
  }

  /// Request FCM permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    Logger.log("NOTIFICATION_SERVICE - Permission status: ${settings.authorizationStatus}");
  }

  /// Initialize and save FCM token
  Future<void> _initializeFCMToken() async {
    try {
      final userId = _userService.getCurrentUID();
      if (userId == null) {
        Logger.log("NOTIFICATION_SERVICE - No user logged in, skipping token initialization");
        return;
      }

      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await _saveFCMToken(userId, fcmToken);
        Logger.log("NOTIFICATION_SERVICE - FCM token saved for user: $userId");
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(userId, newToken);
      });
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error initializing FCM token", error: e);
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String userId, String fcmToken) async {
    try {
      final tokenModel = FCMTokenModel(
        userId: userId,
        fcmToken: fcmToken,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('fcm_tokens')
          .doc(userId)
          .set(tokenModel.toFirestore());

      Logger.log("NOTIFICATION_SERVICE - FCM token saved successfully");
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error saving FCM token", error: e);
    }
  }

  /// Setup message handlers for foreground and background
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.log("NOTIFICATION_SERVICE - Received foreground message: ${message.notification?.title}");

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'TemuLapak',
        body: message.notification!.body ?? '',
        payload: message.data['conversationId'] ?? '',
      );

      // Save notification to Firestore
      await _saveNotificationToFirestore(message);
    }
  }

  /// Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    Logger.log("NOTIFICATION_SERVICE - Background message tapped");
    
    final conversationId = message.data['conversationId'];
    if (conversationId != null) {
      onNotificationTap?.call(conversationId);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Save notification to Firestore for history
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final data = message.data;
      final notificationModel = NotificationModel(
        id: '', // Firestore will generate this
        receiverId: data['receiverId'] ?? '',
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? '',
        message: data['message'] ?? '',
        conversationId: data['conversationId'] ?? '',
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .add(notificationModel.toFirestore());

      Logger.log("NOTIFICATION_SERVICE - Notification saved to Firestore");
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error saving notification to Firestore", error: e);
    }
  }

  /// Send notification to server
  Future<void> sendNotification(NotificationPayload payload) async {
    try {
      Logger.log("NOTIFICATION_SERVICE - Sending notification to server");

      // Get current server URL from Firestore
      final serverUrl = await _getServerUrl();
      Logger.log("NOTIFICATION_SERVICE - Using server URL: $serverUrl");

      // FIXED: Clean the receiver ID before sending to server
      final cleanReceiverId = _cleanReceiverId(payload.receiverId);
      Logger.log("NOTIFICATION_SERVICE - Original receiver ID: ${payload.receiverId}");
      Logger.log("NOTIFICATION_SERVICE - Cleaned receiver ID: $cleanReceiverId");

      // Create payload with cleaned receiver ID
      final cleanedPayload = NotificationPayload(
        receiverId: cleanReceiverId,
        senderId: payload.senderId,
        senderName: payload.senderName,
        message: payload.message,
        conversationId: payload.conversationId,
      );

      final response = await http.post(
        Uri.parse('$serverUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cleanedPayload.toJson()),
      );

      if (response.statusCode == 200) {
        Logger.log("NOTIFICATION_SERVICE - Notification sent successfully");
      } else {
        Logger.error("NOTIFICATION_SERVICE - Failed to send notification: ${response.statusCode}");
        Logger.error("NOTIFICATION_SERVICE - Response body: ${response.body}");
      }
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error sending notification", error: e);
    }
  }

  /// Clean receiver ID by removing MRCN_ prefix if present
  String _cleanReceiverId(String receiverId) {
    if (receiverId.startsWith('MRCN_')) {
      return receiverId.replaceFirst('MRCN_', '');
    }
    return receiverId;
  }

  /// Get notification history for current user
  Stream<List<NotificationModel>> getNotificationHistory() {
    final userId = _userService.getCurrentUID();
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Update FCM token when user logs in
  Future<void> updateFCMTokenOnLogin() async {
    await _initializeFCMToken();
  }

  Future<void> clearFCMTokenOnLogout() async {
    try {
      final uid = _userService.getCurrentUID();
      await _firestore.collection('fcm_tokens').doc(uid).delete();
      Logger.log("NOTIFICATION_SERVICE - FCM token cleared on logout");
    } catch (e) {
      Logger.error("NOTIFICATION_SERVICE - Error clearing FCM token", error: e);
    }
  }
}