import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_status_viewmodel.dart';

enum FavoriteButtonStyle {
  floating,  // For detail page (with dark background circle)
  inline,    // For merchant cards (just the icon)
  compact,   // Small size for list items
}

class FavoriteButton extends ConsumerWidget {
  final MerchantModel merchant;
  final FavoriteButtonStyle style;
  final double? size;
  final bool showFeedback;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.merchant,
    this.style = FavoriteButtonStyle.inline,
    this.size,
    this.showFeedback = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantId = "MRCN_${merchant.uid}";
    final favoriteState = ref.watch(favoriteStatusProvider(merchantId));

    return favoriteState.when(
      idle: () => _buildButton(
        context: context,
        ref: ref,
        merchantId: merchantId,
        isFavorited: false,
        isLoading: false,
        hasError: false,
      ),
      loading: () => _buildLoadingButton(),
      success: (isFavorited) => _buildButton(
        context: context,
        ref: ref,
        merchantId: merchantId,
        isFavorited: isFavorited,
        isLoading: false,
        hasError: false,
      ),
      error: (error, message) => _buildButton(
        context: context,
        ref: ref,
        merchantId: merchantId,
        isFavorited: false,
        isLoading: false,
        hasError: true,
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required WidgetRef ref,
    required String merchantId,
    required bool isFavorited,
    required bool isLoading,
    required bool hasError,
  }) {
    final buttonSize = _getButtonSize();
    final iconSize = _getIconSize();

    Widget iconButton = IconButton(
      onPressed: () => _handleToggle(context, ref, merchantId),
      icon: Icon(
        _getIconData(isFavorited, hasError),
        color: _getIconColor(isFavorited, hasError),
        size: iconSize,
      ),
      iconSize: iconSize,
      constraints: BoxConstraints(
        minWidth: buttonSize,
        minHeight: buttonSize,
      ),
      padding: EdgeInsets.zero,
    );

    // Apply style-specific wrapper
    switch (style) {
      case FavoriteButtonStyle.floating:
        return Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: iconButton,
        );

      case FavoriteButtonStyle.inline:
        return SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: iconButton,
        );

      case FavoriteButtonStyle.compact:
        return SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: iconButton,
        );
    }
  }

  Widget _buildLoadingButton() {
    final buttonSize = _getButtonSize();
    final spinnerSize = _getIconSize() * 0.8;

    Widget spinner = SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          style == FavoriteButtonStyle.floating 
            ? Colors.white 
            : MyColor.orange,
        ),
      ),
    );

    switch (style) {
      case FavoriteButtonStyle.floating:
        return Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(child: spinner),
        );

      case FavoriteButtonStyle.inline:
      case FavoriteButtonStyle.compact:
        return SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(child: spinner),
        );
    }
  }

  void _handleToggle(BuildContext context, WidgetRef ref, String merchantId) {
    Logger.log("FAVORITE_BUTTON - Toggle favorite for ${merchant.merchantName}");

    final favoriteNotifier = ref.read(favoriteStatusProvider(merchantId).notifier);

    // Call custom callback if provided
    onToggle?.call();

    favoriteNotifier.toggleFavorite(merchant).then((_) {
      // Show success feedback if enabled
      if (showFeedback && context.mounted) {
        final favoriteState = ref.read(favoriteStatusProvider(merchantId));
        // FIXED: Use when instead of whenOrNull
        favoriteState.when(
          idle: () {},
          loading: () {},
          success: (isFavorited) {
            _showFeedback(
              context,
              isFavorited 
                ? "Ditambahkan ke favorit!" 
                : "Dihapus dari favorit!",
              isFavorited ? Colors.green : MyColor.orange,
            );
          },
          error: (_, __) {},
        );
      }
    }).catchError((error) {
      // Show error feedback if enabled
      if (showFeedback && context.mounted) {
        _showFeedback(
          context,
          "Gagal mengubah status favorit",
          MyColor.red,
        );
      }
    });
  }

  void _showFeedback(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  IconData _getIconData(bool isFavorited, bool hasError) {
    if (hasError) return Icons.error_outline;
    return isFavorited ? Icons.favorite : Icons.favorite_border;
  }

  Color _getIconColor(bool isFavorited, bool hasError) {
    if (hasError) return MyColor.red;
    
    switch (style) {
      case FavoriteButtonStyle.floating:
        return isFavorited ? Colors.red : Colors.white;
      case FavoriteButtonStyle.inline:
      case FavoriteButtonStyle.compact:
        return isFavorited ? Colors.red : Colors.grey[600]!;
    }
  }

  double _getButtonSize() {
    if (size != null) return size!;
    
    switch (style) {
      case FavoriteButtonStyle.floating:
        return 48.0;
      case FavoriteButtonStyle.inline:
        return 40.0;
      case FavoriteButtonStyle.compact:
        return 32.0;
    }
  }

  double _getIconSize() {
    if (size != null) return size! * 0.6;
    
    switch (style) {
      case FavoriteButtonStyle.floating:
        return 24.0;
      case FavoriteButtonStyle.inline:
        return 20.0;
      case FavoriteButtonStyle.compact:
        return 16.0;
    }
  }

  // FIXED: Static factory methods as extensions
  static Widget floating({
    required MerchantModel merchant,
    double? size,
    bool showFeedback = true,
    VoidCallback? onToggle,
  }) {
    return FavoriteButton(
      merchant: merchant,
      style: FavoriteButtonStyle.floating,
      size: size,
      showFeedback: showFeedback,
      onToggle: onToggle,
    );
  }

  static Widget inline({
    required MerchantModel merchant,
    double? size,
    bool showFeedback = true,
    VoidCallback? onToggle,
  }) {
    return FavoriteButton(
      merchant: merchant,
      style: FavoriteButtonStyle.inline,
      size: size,
      showFeedback: showFeedback,
      onToggle: onToggle,
    );
  }

  static Widget compact({
    required MerchantModel merchant,
    double? size,
    bool showFeedback = false,
    VoidCallback? onToggle,
  }) {
    return FavoriteButton(
      merchant: merchant,
      style: FavoriteButtonStyle.compact,
      size: size,
      showFeedback: showFeedback,
      onToggle: onToggle,
    );
  }
}