import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static FirebaseOptions get firebaseOptions {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _value('FIREBASE_ANDROID_API_KEY'),
          appId: _value('FIREBASE_ANDROID_APP_ID'),
          messagingSenderId: _value('FIREBASE_MESSAGING_SENDER_ID'),
          projectId: _value('FIREBASE_PROJECT_ID'),
          databaseURL: _value('FIREBASE_DATABASE_URL'),
          storageBucket: _value('FIREBASE_STORAGE_BUCKET'),
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: _value('FIREBASE_IOS_API_KEY'),
          appId: _value('FIREBASE_IOS_APP_ID'),
          messagingSenderId: _value('FIREBASE_MESSAGING_SENDER_ID'),
          projectId: _value('FIREBASE_PROJECT_ID'),
          databaseURL: _value('FIREBASE_DATABASE_URL'),
          storageBucket: _value('FIREBASE_STORAGE_BUCKET'),
          androidClientId: _value('FIREBASE_ANDROID_CLIENT_ID'),
          iosClientId: _value('FIREBASE_IOS_CLIENT_ID'),
          iosBundleId: _value('FIREBASE_IOS_BUNDLE_ID'),
        );
      default:
        throw UnsupportedError(
          'TemuLapak local configuration is only set up for Android and iOS.',
        );
    }
  }

  static String get googleMapsApiKey => _value('GOOGLE_MAPS_API_KEY');

  static String _value(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable: $key. '
        'Copy .env.example to .env and fill in the value.',
      );
    }
    return value;
  }
}
