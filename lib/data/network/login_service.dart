
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:temulapak_app/data/local/hive_service.dart';
import 'package:temulapak_app/utils/logger.dart';

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

      if (user == null) {
        throw FirebaseAuthException(
            code: 'null-user',
            message: 'Failed to get user after authentication');
      }

      Logger.log("Token : ${googleAuth.accessToken}");
      Logger.log("UID : ${user.uid}");
      Logger.log("Email : ${user.email}");
      Logger.log("Display Name : ${user.displayName}");

      // Save user to Local Storage
      await HiveService.instance.saveUser(user);
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
      await HiveService.instance.clearUser();
      await _auth.signOut();
      await _googleSignIn.signOut();
      Logger.log("User signed out successfully");
    } catch (e) {
      Logger.error("Sign out error", error: e);
    }
  }
}
