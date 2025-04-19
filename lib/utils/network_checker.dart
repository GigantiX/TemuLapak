import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static final NetworkChecker _instance = NetworkChecker._internal();
  static NetworkChecker get instance => _instance;

  factory NetworkChecker() => _instance;

  NetworkChecker._internal();

  Future<bool> checkInternetConnection(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();

    if (result == ConnectivityResult.none) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> execute(BuildContext context, Future<void> Function() action) async {
    if (await checkInternetConnection(context)) {
      await action();
    }
  }
}
