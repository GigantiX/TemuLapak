import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:temulapak_app/config/app_config.dart';
import 'package:temulapak_app/data/local/hive_service.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/chat_page/chat_detail_view.dart';
import 'package:temulapak_app/view/chat_page/chat_view.dart';
import 'package:temulapak_app/view/favorite_page/favorite_view.dart';
import 'package:temulapak_app/view/home_page/home_view.dart';
import 'package:temulapak_app/view/login_page/login_view.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/lifecycle_handler/merchant_lifecycle_handler.dart';
import 'package:temulapak_app/view/navigation_page/navigation_view.dart';
import 'package:temulapak_app/view/profile_page/profile_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _handleNotificationNavigation(Map<String, String?> payload) async {
  Logger.log("MAIN - Handling notification navigation with payload: $payload");
  final conversationId = payload['conversationId'];
  final currentUserRawId = payload['receiverId'];

  if (conversationId != null && currentUserRawId != null) {
    try {
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        final conversationData = conversationDoc.data();
        final merchantId = conversationData?['merchantId'] as String?;

        String currentUserPersonaId = currentUserRawId;
        // Check if the current user is the merchant for this conversation
        if (merchantId != null && merchantId == "MRCN_$currentUserRawId") {
            currentUserPersonaId = merchantId;
            Logger.log("MAIN - User is a merchant, setting persona ID to: $currentUserPersonaId");
        }

        // Use the navigatorKey to push the route.
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversationId: conversationId,
              currentUserPersonaId: currentUserPersonaId,
            ),
          ),
        );
      } else {
        Logger.error("MAIN - Conversation document not found for ID: $conversationId");
      }
    } catch (e) {
      Logger.error("MAIN - Error fetching conversation details: $e");
    }
  } else {
    Logger.error("MAIN - Notification payload is missing required data.");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  await Firebase.initializeApp(options: AppConfig.firebaseOptions);
  await HiveService.instance.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Logger.log("MAIN - onMessageOpenedApp (background tap) triggered.");
    _handleNotificationNavigation({
      'conversationId': message.data['conversationId'],
      'receiverId': message.data['receiverId'],
    });
  });

  await _initializeNotifications();

  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();


  runApp(
    ProviderScope(
      child: MyApp(initialMessage: initialMessage,),
    ),
  );
}

Future<void> _initializeNotifications() async {
  try {
    Logger.log("MAIN - Initializing notification service for foreground/local handling");

    final notificationService = NotificationService.instance;

    // Set the single, unified callback function
    notificationService.onNotificationTap = _handleNotificationNavigation;

    await notificationService.initialize();
    await notificationService.prefetchServerUrl();

    Logger.log("MAIN - Notification service initialized successfully");
  } catch (e) {
    Logger.error("MAIN - Error initializing notification service", error: e);
  }
}


class MyApp extends ConsumerStatefulWidget {
  final RemoteMessage? initialMessage;
  const MyApp({super.key, this.initialMessage});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();
    // If the app was launched from a terminated state, handle the navigation
    // after the first frame is built.
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Logger.log("MAIN - Handling initialMessage (terminated state tap).");
        _handleNotificationNavigation({
          'conversationId': widget.initialMessage!.data['conversationId'],
          'receiverId': widget.initialMessage!.data['receiverId'],
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    return MerchantLifecycleHandler(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'TemuLapak',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Inter',
        ),
        home: loginState.user != null
            ? const NavigationPage()
            : const LoginPage(),
        routes: {
          '/navigation': (context) => NavigationPage(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/chat': (context) => const ChatPage(),
          '/favorite': (context) => const FavoritePage(),
          '/profile': (context) => const ProfilePage(),
        },
      ),
    );
  }
}
