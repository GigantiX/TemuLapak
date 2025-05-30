// File: lib/view/widget/location_update_indicator.dart
// UPDATE: Add compact mode support

import 'package:flutter/material.dart';
// import 'package:temulapak_app/assets/mycolor.dart';

enum ConnectionStatus { live, recent, offline }

class LocationUpdateIndicator extends StatefulWidget {
  final DateTime lastUpdate;
  final ConnectionStatus status;
  final VoidCallback? onRetry;
  final bool compact; // NEW: compact mode untuk di sebelah status merchant

  const LocationUpdateIndicator({
    super.key,
    required this.lastUpdate,
    required this.status,
    this.onRetry,
    this.compact = false, // Default: full mode
  });

  @override
  State<LocationUpdateIndicator> createState() => _LocationUpdateIndicatorState();
}

class _LocationUpdateIndicatorState extends State<LocationUpdateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation untuk Live indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation jika status Live
    if (widget.status == ConnectionStatus.live) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LocationUpdateIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation berdasarkan status
    if (widget.status == ConnectionStatus.live && 
        oldWidget.status != ConnectionStatus.live) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status != ConnectionStatus.live) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getTimeAgoText() {
    final now = DateTime.now();
    final difference = now.difference(widget.lastUpdate);

    if (difference.inSeconds < 30) {
      return widget.compact ? "Baru saja" : "Baru saja";
    } else if (difference.inSeconds < 60) {
      return widget.compact ? "${difference.inSeconds}d" : "${difference.inSeconds} detik lalu";
    } else if (difference.inMinutes < 60) {
      return widget.compact ? "${difference.inMinutes}m" : "${difference.inMinutes} menit lalu";
    } else if (difference.inHours < 24) {
      return widget.compact ? "${difference.inHours}j" : "${difference.inHours} jam lalu";
    } else {
      return widget.compact ? "${difference.inDays}h" : "${difference.inDays} hari lalu";
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case ConnectionStatus.live:
        return Colors.green;
      case ConnectionStatus.recent:
        return Colors.orange;
      case ConnectionStatus.offline:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case ConnectionStatus.live:
        return Icons.radio_button_checked;
      case ConnectionStatus.recent:
        return Icons.access_time;
      case ConnectionStatus.offline:
        return Icons.signal_wifi_off;
    }
  }

  String _getStatusText() {
    if (widget.compact) {
      switch (widget.status) {
        case ConnectionStatus.live:
          return "Live";
        case ConnectionStatus.recent:
          return "Recent";
        case ConnectionStatus.offline:
          return "Offline";
      }
    } else {
      switch (widget.status) {
        case ConnectionStatus.live:
          return "Live";
        case ConnectionStatus.recent:
          return "Terakhir dilihat";
        case ConnectionStatus.offline:
          return "Offline";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 12, 
        vertical: widget.compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.compact ? 12 : 20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated status icon untuk Live
          if (widget.status == ConnectionStatus.live)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    _getStatusIcon(),
                    color: statusColor,
                    size: widget.compact ? 12 : 16,
                  ),
                );
              },
            )
          else
            Icon(
              _getStatusIcon(),
              color: statusColor,
              size: widget.compact ? 12 : 16,
            ),
          
          const SizedBox(width: 4),
          
          // Status text & time (compact atau full)
          if (widget.compact) ...[
            Text(
              _getStatusText(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              _getStatusText(),
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Dot separator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            
            // Time ago text
            Text(
              _getTimeAgoText(),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          
          // Retry button untuk offline status (hanya di full mode)
          if (!widget.compact && 
              widget.status == ConnectionStatus.offline && 
              widget.onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRetry,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh,
                  color: statusColor,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}