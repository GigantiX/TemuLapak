import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';

class MerchantWidget extends StatelessWidget {
  final MerchantModel merchant;
  final VoidCallback? onTap;

  const MerchantWidget({
    super.key,
    required this.merchant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric( vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Merchant Image - Full height, no padding
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),    // Same as container
                bottomLeft: Radius.circular(12), // Same as container
                topRight: Radius.circular(0),    // No rounding on right
                bottomRight: Radius.circular(0), // No rounding on right
              ),
              child: SizedBox(
                width: 130,
                height: 130, // Full height to match container with padding
                child: merchant.merchantImgUrl != null &&
                        merchant.merchantImgUrl!.isNotEmpty
                    ? Image.network(
                        merchant.merchantImgUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            // Merchant Info - With padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant Name
                    Text(
                      merchant.merchantName ?? 'Merchant',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Product Count
                    Text(
                      '${_getProductCount()} Produk',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Price Range
                    Text(
                      _getPriceRange(),
                      style: TextStyle(
                        fontSize: 14,
                        color: MyColor.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Distance and Status Row
                    Row(
                      children: [
                        // Distance
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: MyColor.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2.14 km',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: merchant.merchantStatus
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            merchant.merchantStatus ? 'BUKA' : 'TUTUP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.grey,
        // No borderRadius here since ClipRRect handles it
      ),
      child: Icon(
        Icons.store,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.grey,
        // No borderRadius here since ClipRRect handles it
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  int _getProductCount() {
    return merchant.products?.length ?? 0;
  }

  String _getPriceRange() {
    if (merchant.products == null || merchant.products!.isEmpty) {
      return 'Harga tidak tersedia';
    }
    
    List<int> prices = [];
    
    for (var product in merchant.products!) {
      try {
        String? priceString = product.productPrice?.toString();
        if (priceString != null && priceString.isNotEmpty) {
          // Remove any non-digit characters and parse
          String cleanPrice = priceString.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPrice.isNotEmpty) {
            int price = int.parse(cleanPrice);
            prices.add(price);
          }
        }
      } catch (e) {
        continue; // Skip invalid prices
      }
    }
    
    if (prices.isEmpty) {
      return 'Harga tidak tersedia';
    }
    
    prices.sort();
    int minPrice = prices.first;
    int maxPrice = prices.last;
    
    if (minPrice == maxPrice) {
      return "Rp ${_formatPriceShort(minPrice)}";
    } else {
      return "Rp ${_formatPriceShort(minPrice)} - ${_formatPriceShort(maxPrice)}";
    }
  }

  /// Format price with "k" for thousands (short format)
  String _formatPriceShort(int price) {
    if (price >= 1000) {
      if (price % 1000 == 0) {
        return '${price ~/ 1000}k';
      } else {
        double priceInK = price / 1000;
        if (priceInK == priceInK.toInt()) {
          return '${priceInK.toInt()}k';
        } else {
          return '${priceInK.toStringAsFixed(1)}k';
        }
      }
    } else {
      return price.toString();
    }
  }
}