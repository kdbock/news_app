import 'package:intl/intl.dart';

class DateFormatter {
  // Format relative date (e.g., "2 days ago", "5 min ago")
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }

    // If older than a week, return month + day
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  // Format as standard date (e.g., "Apr 5, 2025")
  static String formatStandardDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Format as short date (e.g., "04/05/25")
  static String formatShortDate(DateTime date) {
    return DateFormat('MM/dd/yy').format(date);
  }

  // Format with time (e.g., "Apr 5, 2025 at 3:45 PM")
  static String formatDateWithTime(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }

  // Get day name (e.g., "Monday", "Tuesday")
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  // Get short day name (e.g., "Mon", "Tue")
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }
}