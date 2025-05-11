import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/utils/logger.dart';

final loginServiceProvider = Provider<LoginService>((ref) {
  return LoginService();
});

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Logger.log("google-signin-cancelled");
        throw FirebaseAuthException(
            code: 'google-signin-cancelled', message: 'Google Sign-In Failed');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userService = UserService();
        await userService.addProfileFromGoogle(user);
        
      } else {
        throw FirebaseAuthException(
            code: 'null-user',
            message: 'Failed to get user after authentication');
      }

      Logger.log("Token : ${googleAuth.accessToken}");
      Logger.log("UID : ${user.uid}");
      Logger.log("Email : ${user.email}");
      Logger.log("Display Name : ${user.displayName}");

      // Save user to Local Storage
      // await HiveService.instance.saveUser(user);
    } on FirebaseAuthException catch (e) {
      Logger.error("Firebase Auth Error", error: e);
      Logger.error("Code: ${e.code}, Message: ${e.message}");

      rethrow;
    } catch (e) {
      Logger.error("Google Sign-In Error", error: e);

      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      Logger.log("User signed out successfully");
    } catch (e) {
      Logger.error("Sign out error", error: e);
    }
  }

  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.log("No user is currently signed in");
      return null;
    }

    return user;
  }
}
