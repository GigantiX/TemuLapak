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
  final List<Product>? products;

  MerchantModel(
      {required this.uid,
      this.merchantStatus = false,
      this.merchantName,
      this.merchantDesc,
      this.merchantLocLat,
      this.merchantLocLong,
      this.merchantImgUrl,
      this.merchantPopularity,
      this.products});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'merchantStatus': merchantStatus,
      'merchantName': merchantName,
      'merchantDesc': merchantDesc,
      'merchantLocLat': merchantLocLat,
      'merchantLocLong': merchantLocLong,
      'merchantImgUrl': merchantImgUrl,
      'merchantPopularity': merchantPopularity,
      'products': products?.map((product) => product.toMap()).toList(),
    };
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      uid: map['uid'] ?? '',
      merchantStatus: map['merchantStatus'] ?? false,
      merchantName: map['merchantName'],
      merchantDesc: map['merchantDesc'],
      merchantLocLat: map['merchantLocLat']?.toDouble(),
      merchantLocLong: map['merchantLocLong']?.toDouble(),
      merchantImgUrl: map['merchantImgUrl'],
      merchantPopularity: map['merchantPopularity']?.toInt(),
      products: map['products'] != null
          ? List<Product>.from(
              (map['products'] as List).map((item) => Product.fromMap(item)))
          : null,
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
    List<Product>? products,
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
      products: products ?? this.products,
    );
  }
}
