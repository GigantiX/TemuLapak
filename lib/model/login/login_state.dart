import 'package:firebase_auth/firebase_auth.dart';

class LoginState {
  final User? user;
  final bool isLoading;
  final String? error;

  LoginState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  LoginState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return LoginState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}