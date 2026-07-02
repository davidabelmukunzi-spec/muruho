import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
  }

  static String formatPercent(double value) {
    return '${(value * 100).clamp(0, 100).toStringAsFixed(0)} %';
  }

  static String formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return DateFormat.Hm().format(date);
    }
    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    }
    if (now.difference(date).inDays < 7) {
      return DateFormat.E('fr_FR').format(date);
    }
    return DateFormat.yMMMd('fr_FR').format(date);
  }
}
