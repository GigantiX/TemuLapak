import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> addProfileFromGoogle(User user) async {
    try {
      Logger.log("Adding profile for user: ${user.uid}");

      final docSnapshot = await _usersCollection.doc(user.uid).get();

      if (docSnapshot.exists) {
        final Map<String, dynamic> updateData = {};

        if (user.email != null) updateData['email'] = user.email;
        if (user.displayName != null) {
          updateData['displayName'] = user.displayName;
        }
        if (user.photoURL != null) updateData['photoURL'] = user.photoURL;

        if (updateData.isNotEmpty) {
          await _usersCollection.doc(user.uid).update(updateData);
          Logger.log('Profile updated for user: ${user.uid}');
        }
      } else {
        final UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            merchantStatus: false);
        await _usersCollection.doc(user.uid).set(newUser.toMap());
        Logger.log('Profile created for user: ${user.uid}');
      }
    } catch (e) {
      Logger.error("Error adding profile: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();

      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        Logger.log("User with uid $uid does not exist");
        return null;
      }
    } catch (e) {
      Logger.error("Error fetching user: $e");
      return null;
    }
  }
}
