import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/network/login_service.dart';
import 'package:temulapak_app/model/login/login_state.dart';
import 'package:temulapak_app/utils/logger.dart';

final loginServiceProvider = Provider((ref) => LoginService());
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final loginModel = ref.read(loginServiceProvider);

  return LoginViewModel(loginModel);
});

class LoginViewModel extends StateNotifier<LoginState> {
  final LoginService _loginModel;

  LoginViewModel(this._loginModel)
      : super(LoginState(user: _loginModel.currentUser));

  Future<void> googleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loginModel.signInWithGoogle();
      state = state.copyWith(user: _loginModel.currentUser, isLoading: false);
      Logger.log("Google Sign In Success");
    } catch (e) {
      Logger.error("Google Sign In Error", error: e);
      state = state.copyWith(isLoading: false, error: e.toString(), user: null);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _loginModel.signOut();
    state = LoginState();
  }
}