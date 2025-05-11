import 'package:firebase_auth/firebase_auth.dart';
import 'package:temulapak_app/model/product/product_model.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool merchantStatus;
  final String? merchantName;
  final String? merchantDesc;
  final double? merchantLocLat;
  final double? merchantLocLong;
  final double? merchantCurrLat;
  final double? merchantCurrLong;
  final List<Product>? products;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.merchantStatus = false,
    this.merchantName,
    this.merchantDesc,
    this.merchantLocLat,
    this.merchantLocLong,
    this.merchantCurrLat,
    this.merchantCurrLong,
    this.products,
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
      'merchantStatus': merchantStatus,
      'merchantName': merchantName,
      'merchantDesc': merchantDesc,
      'merchantLocLat': merchantLocLat,
      'merchantLocLong': merchantLocLong,
      'merchantCurrLat': merchantCurrLat,
      'merchantCurrLong': merchantCurrLong,
      'products': products?.map((product) => product.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        uid: map['uid'] as String,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        photoURL: map['photoURL'] as String?,
        merchantStatus: map['merchantStatus'] as bool? ?? false,
        merchantName: map['merchantName'] as String?,
        merchantDesc: map['merchantDesc'] as String?,
        merchantLocLat: map['merchantLocLat'] as double?,
        merchantLocLong: map['merchantLocLong'] as double?,
        merchantCurrLat: map['merchantCurrLat'] as double?,
        merchantCurrLong: map['merchantCurrLong'] as double?,
        products: (map['products'] as List<dynamic>?)
            ?.map((product) => Product.fromMap(product))
            .toList()
    );
  }
}
