class Product {
  final String? productName;
  final String? productPrice;

  Product({this.productName, this.productPrice});

  Product copyWith({
    String? productName,
    String? productPrice,
  }) {
    return Product(
      productName:  productName ?? this.productName,
      productPrice:  productPrice ?? this.productPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'productPrice': productPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
        productName: map['productName'] as String?,
        productPrice: map['productPrice'] as String?);
  }
}
