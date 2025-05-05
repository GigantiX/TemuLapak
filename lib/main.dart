import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temulapak_app/data/local/hive_service.dart';
import 'package:temulapak_app/view/chat_page/chat_page.dart';
import 'package:temulapak_app/view/favorite_page/favorite_page.dart';
import 'package:temulapak_app/view/home_page/home_page.dart';
import 'package:temulapak_app/view/login_page/login_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';
import 'package:temulapak_app/view/navigation_page/navigation_page.dart';
import 'package:temulapak_app/view/profile_page/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //Initialize Local Storage Hive
  await HiveService.instance.init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginViewModelProvider);
    
    return MaterialApp( 
      debugShowCheckedModeBanner: false,
      title: 'TemuLapak',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.interTextTheme()
      ),
      home: loginState.user != null ? const NavigationPage() : const LoginPage(),
      routes: {
        '/navigation': (context) => NavigationPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/favorite': (context) => const FavoritePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}


