import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:temulapak_app/model/product/product_model.dart';

class MerchantModel {
  final String uid;
  final bool merchantStatus;
  final String? merchantName;
  final String? merchantDesc;
  final String? merchantImgUrl;
  final double? merchantLocLat;
  final double? merchantLocLong;
  final int? merchantPopularity;
  final List<String>? merchantCategory;
  final List<Product>? products;
  final GeoFirePoint? geoPoint;

  MerchantModel(
      {required this.uid,
      this.merchantStatus = false,
      this.merchantName,
      this.merchantDesc,
      this.merchantLocLat,
      this.merchantLocLong,
      this.merchantImgUrl,
      this.merchantPopularity,
      this.merchantCategory,
      this.products,
      this.geoPoint});

  Map<String, dynamic> toMap() {
    final map = {
      'uid': uid,
      'merchantStatus': merchantStatus,
      'merchantName': merchantName,
      'merchantDesc': merchantDesc,
      'merchantLocLat': merchantLocLat,
      'merchantLocLong': merchantLocLong,
      'merchantImgUrl': merchantImgUrl,
      'merchantPopularity': merchantPopularity,
      'merchantCategory': merchantCategory,
      'products': products?.map((product) => product.toMap()).toList(),
      'geoPoint': geoPoint?.data,
    };
    return map;
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    final rawGeo = map['geoPoint'] as Map<String, dynamic>?;
    final geoPoint = rawGeo != null
        ? GeoFirePoint(rawGeo['geopoint'] as GeoPoint,)
        : null;

    return MerchantModel(
      uid: map['uid'] ?? '',
      merchantStatus: map['merchantStatus'] ?? false,
      merchantName: map['merchantName'],
      merchantDesc: map['merchantDesc'],
      merchantLocLat: map['merchantLocLat']?.toDouble(),
      merchantLocLong: map['merchantLocLong']?.toDouble(),
      merchantImgUrl: map['merchantImgUrl'],
      merchantPopularity: map['merchantPopularity']?.toInt(),
      merchantCategory: map['merchantCategory'] != null
          ? List<String>.from(map['merchantCategory'])
          : null,
      products: map['products'] != null
          ? List<Product>.from(
              (map['products'] as List).map((item) => Product.fromMap(item)))
          : null,
      geoPoint: geoPoint,
    );
  }

  MerchantModel copyWith({
    String? uid,
    bool? merchantStatus,
    String? merchantName,
    String? merchantDesc,
    double? merchantLocLat,
    double? merchantLocLong,
    String? merchantImgUrl,
    int? merchantPopularity,
    List<String>? merchantCategory,
    List<Product>? products,
    GeoFirePoint? geoPoint,
  }) {
    return MerchantModel(
      uid: uid ?? this.uid,
      merchantStatus: merchantStatus ?? this.merchantStatus,
      merchantName: merchantName ?? this.merchantName,
      merchantDesc: merchantDesc ?? this.merchantDesc,
      merchantLocLat: merchantLocLat ?? this.merchantLocLat,
      merchantLocLong: merchantLocLong ?? this.merchantLocLong,
      merchantImgUrl: merchantImgUrl ?? this.merchantImgUrl,
      merchantPopularity: merchantPopularity ?? this.merchantPopularity,
      merchantCategory: merchantCategory ?? this.merchantCategory,
      products: products ?? this.products,
      geoPoint: geoPoint ?? this.geoPoint,
    );
  }
}
