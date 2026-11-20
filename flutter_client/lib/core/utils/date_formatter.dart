import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy');
  static final DateFormat _displayDateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayDate.format(date.toLocal());
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayDateTime.format(date.toLocal());
  }

  static String formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _timeOnly.format(date.toLocal());
  }

  static String formatFromIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return _displayDate.format(date.toLocal());
    } catch (_) {
      return isoString;
    }
  }

  static String formatDateTimeFromIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return _displayDateTime.format(date.toLocal());
    } catch (_) {
      return isoString;
    }
  }
}
