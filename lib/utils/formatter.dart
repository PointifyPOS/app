import 'package:intl/intl.dart';

abstract class Formatter {
  Formatter._();

  static String formatDateTime(DateTime dateTime) {
    final DateFormat dateFormat = DateFormat('hh:mm a');
    return dateFormat.format(dateTime);
  }

}

String? normalizeKePhone(String? p) {
  if (p == null) return null;
  final d = p.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('254')) return d;
  if (d.startsWith('0')) return '254${d.substring(1)}';
  if (d.startsWith('7') || d.startsWith('1')) return '254$d';
  return d.isEmpty ? null : d;
}
