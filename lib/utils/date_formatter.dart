import 'package:intl/intl.dart';
import 'package:temulapak_app/utils/logger.dart';

class DateFormatter {
  // Indonesian day names for fallback
  static const List<String> _dayNames = [
    'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  /// Format message time in WhatsApp style with safe fallback
  static String formatMessageTime(DateTime messageTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(messageTime);
      
      // If less than 1 minute
      if (difference.inMinutes < 1) {
        return 'Baru saja';
      }
      
      // If less than 1 hour, show minutes
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      }
      
      // If today, show time (HH:mm)
      if (_isSameDay(messageTime, now)) {
        return _safeFormatTime(messageTime);
      }
      
      // If yesterday
      if (difference.inDays == 1) {
        return 'Kemarin';
      }
      
      // If this week (less than 7 days), show day name
      if (difference.inDays < 7) {
        return _safeDayName(messageTime);
      }
      
      // If more than 7 days, show date (dd/MM/yyyy)
      return _safeFormatDate(messageTime);
      
    } catch (e) {
      Logger.error("DateFormatter - Error formatting message time", error: e);
      return _fallbackFormat(messageTime);
    }
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Safely format time (HH:mm)
  static String _safeFormatTime(DateTime dateTime) {
    try {
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      Logger.error("DateFormatter - Error formatting time", error: e);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Safely get day name
  static String _safeDayName(DateTime dateTime) {
    try {
      return DateFormat('EEEE').format(dateTime);
    } catch (e) {
      Logger.error("DateFormatter - Error formatting day name", error: e);
      // Fallback to manual day names
      return _dayNames[dateTime.weekday % 7];
    }
  }

  /// Safely format date (dd/MM/yyyy)
  static String _safeFormatDate(DateTime dateTime) {
    try {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      Logger.error("DateFormatter - Error formatting date", error: e);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  /// Ultimate fallback formatting
  static String _fallbackFormat(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays == 0) {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return _dayNames[messageTime.weekday % 7];
    } else {
      return '${messageTime.day.toString().padLeft(2, '0')}/${messageTime.month.toString().padLeft(2, '0')}/${messageTime.year}';
    }
  }

  /// Format full date and time for detailed views
  static String formatFullDateTime(DateTime dateTime) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      Logger.error("DateFormatter - Error formatting full date time", error: e);
      return '${_safeFormatDate(dateTime)} ${_safeFormatTime(dateTime)}';
    }
  }

  /// Format date only
  static String formatDateOnly(DateTime dateTime) {
    return _safeFormatDate(dateTime);
  }

  /// Format time only
  static String formatTimeOnly(DateTime dateTime) {
    return _safeFormatTime(dateTime);
  }
}