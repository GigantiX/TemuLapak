// File: lib/view/widget/merchant_widget.dart
// VERIFIED: Fixed FavoriteButton integration and improved distance handling

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/view/widget/favorite_button.dart';

class MerchantWidget extends ConsumerWidget {
  final MerchantModel merchant;
  final VoidCallback? onTap;
  final bool showFavoriteButton; // Option to show/hide favorite button
  final double? distance; // Optional distance parameter

  const MerchantWidget({
    super.key,
    required this.merchant,
    this.onTap,
    this.showFavoriteButton = true, // Default true
    this.distance, // Distance in km
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
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
                height: 134, // Full height to match container with padding
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and favorite button
                    Row(
                      children: [
                        // Merchant Name
                        Expanded(
                          child: Text(
                            merchant.merchantName ?? 'Merchant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // VERIFIED: Favorite Button using FavoriteButton widget
                        if (showFavoriteButton) ...[
                          const SizedBox(width: 8),
                          FavoriteButton.compact(
                            merchant: merchant,
                            showFeedback: false, // No feedback in list view to avoid spam
                          ),
                        ],
                      ],
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
                              _getDistanceText(),
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
      width: 130,
      height: 130,
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
      width: 130,
      height: 130,
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

  // IMPROVED: Better distance text handling
  String _getDistanceText() {
    if (distance != null) {
      // Format distance nicely
      if (distance! < 1.0) {
        // Show in meters if less than 1km
        final meters = (distance! * 1000).round();
        return "${meters}m";
      } else {
        // Show in km with appropriate decimal places
        if (distance! < 10) {
          return "${distance!.toStringAsFixed(1)} km";
        } else {
          return "${distance!.toStringAsFixed(0)} km";
        }
      }
    }
    
    // IMPROVED: Better fallback text
    return "-- km"; // More professional than "2.14 km" hardcoded
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

// VERIFIED: Specialized merchant widget for favorite page remains the same
// (This will be used later when we create favorite_page.dart)
class FavoriteMerchantWidget extends ConsumerWidget {
  final MerchantModel merchant;
  final VoidCallback? onTap;
  final VoidCallback? onRemoveFavorite;
  final double? distance;

  const FavoriteMerchantWidget({
    super.key,
    required this.merchant,
    this.onTap,
    this.onRemoveFavorite,
    this.distance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key("favorite_${merchant.uid}"),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onRemoveFavorite?.call();
      },
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Hapus dari Favorit?'),
            content: Text('Apakah Anda yakin ingin menghapus ${merchant.merchantName} dari daftar favorit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Hapus'),
              ),
            ],
          ),
        ) ?? false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: MerchantWidget(
        merchant: merchant,
        onTap: onTap,
        showFavoriteButton: false, // Don't show favorite button in favorite page
        distance: distance,
      ),
    );
  }
}