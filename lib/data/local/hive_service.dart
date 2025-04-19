
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';


class HiveService {
  static final HiveService _instance = HiveService._internal();
  static HiveService get instance => _instance;

  factory HiveService() => _instance;

  HiveService._internal();

  static const String userBoxName = 'userBox';
  static const String userKey = 'currentUser';

  Box<Map>? _userBox;

  Future<void> init() async {
    try {
      //Initialize Hive
      await Hive.initFlutter();

      //Open box
      _userBox = await Hive.openBox<Map>(userBoxName);
      Logger.log("Hive initialized successfully");
    } catch (e) {
      Logger.error("Failed to initialize Hive", error: e);
    }
  }

  Future<void> saveUser(User user) async {
    try {
      if (_userBox == null) {
        throw Exception('Hive not initialized');
      }

      final userModel = UserModel.fromFirebaseUser(user);
      await _userBox!.put(userKey, userModel.toMap());
      Logger.log("User saved to Hive: ${user.uid}");
    } catch(e) {
      Logger.error("Failed save user to hive", error: e);
    }
  }

  UserModel? getUser() {
    try {
      if (_userBox == null) {
        throw Exception('Hive not initialized');
      }

      final userData = _userBox!.get(userKey);
      if (userData == null) {
        return null;
      }

      return UserModel.fromMap(Map<String, dynamic>.from(userData));
    } catch (e) {
      Logger.error("Failed to get user from hive", error: e);
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      if (_userBox == null) {
        throw Exception('Hive not initialized');
      }

      await _userBox!.delete(userKey);
      Logger.log("User cleared from Hive");
    } catch (e) {
      Logger.error("Failed to clear user from hive", error: e);
    }
  }

  Future<void> closeBoxes() async {
    await _userBox?.close();
  }
}
