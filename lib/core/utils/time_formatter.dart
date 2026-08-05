import 'package:intl/intl.dart';

class TimeFormatter {
  /// Formats a [DateTime] into a friendly relative string:
  /// - Null: 'Sin fecha'
  /// - < 1 min: 'Hace un momento'
  /// - < 60 min: 'Hace X min'
  /// - Today: 'Hace Xh' (or 'Hoy HH:mm')
  /// - Yesterday: 'Ayer HH:mm'
  /// - < 7 days: 'Hace X días'
  /// - Otherwise: 'DD/MM/YYYY'
  static String formatRelative(DateTime? dateTime) {
    if (dateTime == null) return 'Sin fecha';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }

    if (difference.inSeconds < 60) {
      return 'Hace un momento';
    }

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Hace $mins min';
    }

    final isSameDay =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    if (isSameDay) {
      final hours = difference.inHours;
      if (hours > 0) {
        return 'Hace ${hours}h';
      }
      return 'Hoy ${DateFormat('HH:mm').format(dateTime)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day;

    if (isYesterday) {
      return 'Ayer ${DateFormat('HH:mm').format(dateTime)}';
    }

    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    }

    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Returns true if [dateTime] is null or if the time difference is greater than or equal to [daysThreshold] days (default 7 days).
  static bool isOutdated(DateTime? dateTime, {int daysThreshold = 7}) {
    if (dateTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return difference.inDays >= daysThreshold;
  }
}
