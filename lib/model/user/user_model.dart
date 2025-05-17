import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool merchantOwner;

  UserModel({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.merchantOwner = false,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'merchantOwner': merchantOwner,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        uid: map['uid']?.toString() ?? '',
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        photoURL: map['photoURL'] as String?,
        merchantOwner: map['merchantOwner'] as bool? ?? false,
    );
  }

    /// Creates a copy of this UserModel with the given fields replaced with new values
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? merchantOwner,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      merchantOwner: merchantOwner ?? this.merchantOwner,
    );
  }
}
