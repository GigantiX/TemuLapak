// File: lib/model/favorite/favorite_model.dart

class FavoriteModel {
  final String merchantId;
  final DateTime addedAt;
  final int order;
  final String? merchantName;
  final String? merchantImgUrl;
  final bool? merchantStatus;
  final List<String>? merchantCategory;

  FavoriteModel({
    required this.merchantId,
    required this.addedAt,
    required this.order,
    this.merchantName,
    this.merchantImgUrl,
    this.merchantStatus,
    this.merchantCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'addedAt': addedAt.toIso8601String(),
      'order': order,
      'merchantName': merchantName,
      'merchantImgUrl': merchantImgUrl,
      'merchantStatus': merchantStatus,
      'merchantCategory': merchantCategory,
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      merchantId: map['merchantId'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      order: map['order']?.toInt() ?? 0,
      merchantName: map['merchantName'],
      merchantImgUrl: map['merchantImgUrl'],
      merchantStatus: map['merchantStatus'],
      merchantCategory: map['merchantCategory'] != null 
          ? List<String>.from(map['merchantCategory']) 
          : null,
    );
  }

  FavoriteModel copyWith({
    String? merchantId,
    DateTime? addedAt,
    int? order,
    String? merchantName,
    String? merchantImgUrl,
    bool? merchantStatus,
    List<String>? merchantCategory,
  }) {
    return FavoriteModel(
      merchantId: merchantId ?? this.merchantId,
      addedAt: addedAt ?? this.addedAt,
      order: order ?? this.order,
      merchantName: merchantName ?? this.merchantName,
      merchantImgUrl: merchantImgUrl ?? this.merchantImgUrl,
      merchantStatus: merchantStatus ?? this.merchantStatus,
      merchantCategory: merchantCategory ?? this.merchantCategory,
    );
  }

  @override
  String toString() {
    return 'FavoriteModel(merchantId: $merchantId, merchantName: $merchantName, order: $order, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteModel && other.merchantId == merchantId;
  }

  @override
  int get hashCode {
    return merchantId.hashCode;
  }
}