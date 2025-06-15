import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  await Firebase.initializeApp();
  await HiveService.instance.init();
  await _initializeNotifications();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  try {
    Logger.log("MAIN - Initializing notification service");

    final notificationService = NotificationService.instance;

    notificationService.onNotificationTap = (payload) {
      Logger.log("MAIN - Notification tapped, payload: $payload");

      final conversationId = payload['conversationId'];
      final currentUserPersonaId = payload['receiverId'];

      if (conversationId != null && currentUserPersonaId != null) {
        Logger.log("MAIN - Navigating to conversation: $conversationId as persona: $currentUserPersonaId");
        
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Navigate to ChatDetailPage with BOTH required parameters
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                conversationId: conversationId,
                currentUserPersonaId: currentUserPersonaId,
              ),
            ),
          );
        }
      } else {
        Logger.error("MAIN - Notification payload is missing required data.");
      }
    };

    await notificationService.initialize();
    await notificationService.prefetchServerUrl();

    Logger.log("MAIN - Notification service initialized successfully");
  } catch (e) {
    Logger.error("MAIN - Error initializing notification service", error: e);
  }
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginViewModelProvider);

    return MerchantLifecycleHandler(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
