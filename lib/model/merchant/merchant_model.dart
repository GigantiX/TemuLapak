import 'package:temulapak_app/model/product/product_model.dart';

class MerchantModel {
  final String uid;
  final bool merchantStatus;
  final String? merchantName;
  final String? merchantDesc;
  final double? merchantLocLat;
  final double? merchantLocLong;
  final double? merchantCurrLat;
  final double? merchantCurrLong;
  final List<Product>? products;

  MerchantModel(
      {required this.uid,
      this.merchantStatus = false,
      this.merchantName,
      this.merchantDesc,
      this.merchantLocLat,
      this.merchantLocLong,
      this.merchantCurrLat,
      this.merchantCurrLong,
      this.products});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
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

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      uid: map['uid'] ?? '',
      merchantStatus: map['merchantStatus'] ?? false,
      merchantName: map['merchantName'],
      merchantDesc: map['merchantDesc'],
      merchantLocLat: map['merchantLocLat']?.toDouble(),
      merchantLocLong: map['merchantLocLong']?.toDouble(),
      merchantCurrLat: map['merchantCurrLat']?.toDouble(),
      merchantCurrLong: map['merchantCurrLong']?.toDouble(),
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
    double? merchantCurrLat,
    double? merchantCurrLong,
    List<Product>? products,
  }) {
    return MerchantModel(
      uid: uid ?? this.uid,
      merchantStatus: merchantStatus ?? this.merchantStatus,
      merchantName: merchantName ?? this.merchantName,
      merchantDesc: merchantDesc ?? this.merchantDesc,
      merchantLocLat: merchantLocLat ?? this.merchantLocLat,
      merchantLocLong: merchantLocLong ?? this.merchantLocLong,
      merchantCurrLat: merchantCurrLat ?? this.merchantCurrLat,
      merchantCurrLong: merchantCurrLong ?? this.merchantCurrLong,
      products: products ?? this.products,
    );
  }
}
