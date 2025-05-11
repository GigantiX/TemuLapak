import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:temulapak_app/utils/logger.dart';

class NetworkChecker {
  static final NetworkChecker _instance = NetworkChecker._internal();
  static NetworkChecker get instance => _instance;

  factory NetworkChecker() => _instance;

  NetworkChecker._internal();

  Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Shows a snackbar with a no connection message
  void showNoConnectionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection. Please check your network.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Run a network-dependent function with proper error handling
  /// Returns the function's result or null if offline
  Future<T?> run<T>({
    required BuildContext context,
    required Future<T> Function() action,
    String? customOfflineMessage,
    bool showMessage = true,
  }) async {
    try {
      if (!await isConnected()) {
        if (showMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(customOfflineMessage ?? 'No internet connection. Please check your network.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ));
        }
        return null;
      }
      
      return await action();
    } catch (e) {
      Logger.error('Network operation failed', error: e);
      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Operation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
      return null;
    }
  }
}
